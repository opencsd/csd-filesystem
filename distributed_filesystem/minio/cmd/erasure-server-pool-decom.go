// Copyright (c) 2015-2021 MinIO, Inc.
//
// This file is part of MinIO Object Storage stack
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

package cmd

import (
	"context"
	"encoding/binary"
	"errors"
	"fmt"
	"net/http"
	"sort"
	"time"

	"github.com/dustin/go-humanize"
	"github.com/minio/minio/internal/hash"
	"github.com/minio/minio/internal/logger"
	"github.com/minio/pkg/console"
)

// PoolDecommissionInfo currently decommissioning information
type PoolDecommissionInfo struct {
	StartTime   time.Time `json:"startTime" msg:"st"`
	StartSize   int64     `json:"startSize" msg:"ss"`
	TotalSize   int64     `json:"totalSize" msg:"ts"`
	CurrentSize int64     `json:"currentSize" msg:"cs"`

	Complete bool `json:"complete" msg:"cmp"`
	Failed   bool `json:"failed" msg:"fl"`
	Canceled bool `json:"canceled" msg:"cnl"`

	// Internal information.
	QueuedBuckets         []string `json:"-" msg:"bkts"`
	DecommissionedBuckets []string `json:"-" msg:"dbkts"`

	// Last bucket/object decommissioned.
	Bucket string `json:"-" msg:"bkt"`
	Object string `json:"-" msg:"obj"`

	// Verbose information
	ItemsDecommissioned     int64 `json:"-" msg:"id"`
	ItemsDecommissionFailed int64 `json:"-" msg:"idf"`
	BytesDone               int64 `json:"-" msg:"bd"`
	BytesFailed             int64 `json:"-" msg:"bf"`
}

// bucketPop should be called when a bucket is done decommissioning.
// Adds the bucket to the list of decommissioned buckets and updates resume numbers.
func (pd *PoolDecommissionInfo) bucketPop(bucket string) {
	pd.DecommissionedBuckets = append(pd.DecommissionedBuckets, bucket)
	for i, b := range pd.QueuedBuckets {
		if b == bucket {
			// Bucket is done.
			pd.QueuedBuckets = append(pd.QueuedBuckets[:i], pd.QueuedBuckets[i+1:]...)
			// Clear tracker info.
			if pd.Bucket == bucket {
				pd.Bucket = "" // empty this out for next bucket
				pd.Object = "" // empty this out for next object
			}
			return
		}
	}
}

func (pd *PoolDecommissionInfo) bucketsToDecommission() []string {
	queuedBuckets := make([]string, len(pd.QueuedBuckets))
	copy(queuedBuckets, pd.QueuedBuckets)
	return queuedBuckets
}

func (pd *PoolDecommissionInfo) isBucketDecommissioned(bucket string) bool {
	for _, b := range pd.DecommissionedBuckets {
		if b == bucket {
			return true
		}
	}
	return false
}

func (pd *PoolDecommissionInfo) bucketPush(bucket string) {
	for _, b := range pd.QueuedBuckets {
		if pd.isBucketDecommissioned(b) {
			return
		}
		if b == bucket {
			return
		}
	}
	pd.QueuedBuckets = append(pd.QueuedBuckets, bucket)
	pd.Bucket = bucket
}

// PoolStatus captures current pool status
type PoolStatus struct {
	ID           int                   `json:"id" msg:"id"`
	CmdLine      string                `json:"cmdline" msg:"cl"`
	LastUpdate   time.Time             `json:"lastUpdate" msg:"lu"`
	Decommission *PoolDecommissionInfo `json:"decommissionInfo,omitempty" msg:"dec"`
}

//go:generate msgp -file $GOFILE -unexported
type poolMeta struct {
	Version int          `msg:"v"`
	Pools   []PoolStatus `msg:"pls"`
}

// A decommission resumable tells us if decommission is worth
// resuming upon restart of a cluster.
func (p *poolMeta) returnResumablePools(n int) []PoolStatus {
	var newPools []PoolStatus
	for _, pool := range p.Pools {
		if pool.Decommission == nil {
			continue
		}
		if pool.Decommission.Complete || pool.Decommission.Canceled {
			// Do not resume decommission upon startup for
			// - decommission complete
			// - decommission canceled
			continue
		} // In all other situations we need to resume
		newPools = append(newPools, pool)
		if n > 0 && len(newPools) == n {
			return newPools
		}
	}
	return nil
}

func (p *poolMeta) DecommissionComplete(idx int) bool {
	if p.Pools[idx].Decommission != nil {
		p.Pools[idx].LastUpdate = UTCNow()
		p.Pools[idx].Decommission.Complete = true
		p.Pools[idx].Decommission.Failed = false
		p.Pools[idx].Decommission.Canceled = false
		return true
	}
	return false
}

func (p *poolMeta) DecommissionFailed(idx int) bool {
	if p.Pools[idx].Decommission != nil {
		p.Pools[idx].LastUpdate = UTCNow()
		p.Pools[idx].Decommission.StartTime = time.Time{}
		p.Pools[idx].Decommission.Complete = false
		p.Pools[idx].Decommission.Failed = true
		p.Pools[idx].Decommission.Canceled = false
		return true
	}
	return false
}

func (p *poolMeta) DecommissionCancel(idx int) bool {
	if p.Pools[idx].Decommission != nil {
		p.Pools[idx].LastUpdate = UTCNow()
		p.Pools[idx].Decommission.StartTime = time.Time{}
		p.Pools[idx].Decommission.Complete = false
		p.Pools[idx].Decommission.Failed = false
		p.Pools[idx].Decommission.Canceled = true
		return true
	}
	return false
}

func (p poolMeta) isBucketDecommissioned(idx int, bucket string) bool {
	return p.Pools[idx].Decommission.isBucketDecommissioned(bucket)
}

func (p *poolMeta) BucketDone(idx int, bucket string) {
	if p.Pools[idx].Decommission == nil {
		// Decommission not in progress.
		return
	}
	p.Pools[idx].Decommission.bucketPop(bucket)
}

func (p poolMeta) ResumeBucketObject(idx int) (bucket, object string) {
	if p.Pools[idx].Decommission != nil {
		bucket = p.Pools[idx].Decommission.Bucket
		object = p.Pools[idx].Decommission.Object
	}
	return
}

func (p *poolMeta) TrackCurrentBucketObject(idx int, bucket string, object string) {
	if p.Pools[idx].Decommission == nil {
		// Decommission not in progress.
		return
	}
	p.Pools[idx].Decommission.Bucket = bucket
	p.Pools[idx].Decommission.Object = object
}

func (p *poolMeta) PendingBuckets(idx int) []string {
	if p.Pools[idx].Decommission == nil {
		// Decommission not in progress.
		return nil
	}

	return p.Pools[idx].Decommission.bucketsToDecommission()
}

func (p *poolMeta) QueueBuckets(idx int, buckets []BucketInfo) {
	// add new queued buckets
	for _, bucket := range buckets {
		p.Pools[idx].Decommission.bucketPush(bucket.Name)
	}
}

var (
	errDecommissionAlreadyRunning = errors.New("decommission is already in progress")
	errDecommissionComplete       = errors.New("decommission is complete, please remove the servers from command-line")
)

func (p *poolMeta) Decommission(idx int, pi poolSpaceInfo) error {
	for i, pool := range p.Pools {
		if idx == i {
			continue
		}
		if pool.Decommission != nil {
			// Do not allow multiple decommissions at the same time.
			// We shall for now only allow one pool decommission at
			// a time.
			return fmt.Errorf("%w at index: %d", errDecommissionAlreadyRunning, i)
		}
	}

	now := UTCNow()
	if p.Pools[idx].Decommission == nil {
		p.Pools[idx].LastUpdate = now
		p.Pools[idx].Decommission = &PoolDecommissionInfo{
			StartTime:   now,
			StartSize:   pi.Free,
			CurrentSize: pi.Free,
			TotalSize:   pi.Total,
		}
		return nil
	}

	// Completed pool doesn't need to be decommissioned again.
	if p.Pools[idx].Decommission.Complete {
		return errDecommissionComplete
	}

	// Canceled or Failed decommission can be triggered again.
	if p.Pools[idx].Decommission.StartTime.IsZero() {
		if p.Pools[idx].Decommission.Canceled || p.Pools[idx].Decommission.Failed {
			p.Pools[idx].LastUpdate = now
			p.Pools[idx].Decommission = &PoolDecommissionInfo{
				StartTime:   now,
				StartSize:   pi.Free,
				CurrentSize: pi.Free,
				TotalSize:   pi.Total,
			}
			return nil
		}
	} // In-progress pool doesn't need to be decommissioned again.

	// In all other scenarios an active decommissioning is in progress.
	return errDecommissionAlreadyRunning
}

func (p poolMeta) IsSuspended(idx int) bool {
	return p.Pools[idx].Decommission != nil
}

func (p *poolMeta) validate(pools []*erasureSets) (bool, error) {
	type poolInfo struct {
		position     int
		completed    bool
		decomStarted bool // started but not finished yet
	}

	rememberedPools := make(map[string]poolInfo)
	for idx, pool := range p.Pools {
		complete := false
		decomStarted := false
		if pool.Decommission != nil {
			if pool.Decommission.Complete {
				complete = true
			}
			decomStarted = true
		}
		rememberedPools[pool.CmdLine] = poolInfo{
			position:     idx,
			completed:    complete,
			decomStarted: decomStarted,
		}
	}

	specifiedPools := make(map[string]int)
	for idx, pool := range pools {
		specifiedPools[pool.endpoints.CmdLine] = idx
	}

	// Check if specified pools need to remove decommissioned pool.
	for k := range specifiedPools {
		pi, ok := rememberedPools[k]
		if ok && pi.completed {
			return false, fmt.Errorf("pool(%s) = %s is decommissioned, please remove from server command line", humanize.Ordinal(pi.position+1), k)
		}
	}

	// check if remembered pools are in right position or missing from command line.
	for k, pi := range rememberedPools {
		if pi.completed {
			continue
		}
		_, ok := specifiedPools[k]
		if !ok {
			return false, fmt.Errorf("pool(%s) = %s is not specified, please specify on server command line", humanize.Ordinal(pi.position+1), k)
		}
	}

	// check when remembered pools and specified pools are same they are at the expected position
	if len(rememberedPools) == len(specifiedPools) {
		for k, pi := range rememberedPools {
			pos, ok := specifiedPools[k]
			if !ok {
				return false, fmt.Errorf("pool(%s) = %s is not specified, please specify on server command line", humanize.Ordinal(pi.position+1), k)
			}
			if pos != pi.position {
				return false, fmt.Errorf("pool order change detected for %s, expected position is (%s) but found (%s)", k, humanize.Ordinal(pi.position+1), humanize.Ordinal(pos+1))
			}
		}
	}

	update := len(rememberedPools) != len(specifiedPools)
	if update {
		for k, pi := range rememberedPools {
			if pi.decomStarted && !pi.completed {
				return false, fmt.Errorf("pool(%s) = %s is being decommissioned, No changes should be made to the command line arguments. Please complete the decommission in progress", humanize.Ordinal(pi.position+1), k)
			}
		}
	}
	return update, nil
}

func (p *poolMeta) load(ctx context.Context, pool *erasureSets, pools []*erasureSets) error {
	data, err := readConfig(ctx, pool, poolMetaName)
	if err != nil {
		if errors.Is(err, errConfigNotFound) || isErrObjectNotFound(err) {
			return nil
		}
		return err
	}
	if len(data) == 0 {
		// Seems to be empty create a new poolMeta object.
		return nil
	}
	if len(data) <= 4 {
		return fmt.Errorf("poolMeta: no data")
	}
	// Read header
	switch binary.LittleEndian.Uint16(data[0:2]) {
	case poolMetaFormat:
	default:
		return fmt.Errorf("poolMeta: unknown format: %d", binary.LittleEndian.Uint16(data[0:2]))
	}
	switch binary.LittleEndian.Uint16(data[2:4]) {
	case poolMetaVersion:
	default:
		return fmt.Errorf("poolMeta: unknown version: %d", binary.LittleEndian.Uint16(data[2:4]))
	}

	// OK, parse data.
	if _, err = p.UnmarshalMsg(data[4:]); err != nil {
		return err
	}

	switch p.Version {
	case poolMetaVersionV1:
	default:
		return fmt.Errorf("unexpected pool meta version: %d", p.Version)
	}

	return nil
}

func (p *poolMeta) CountItem(idx int, size int64, failed bool) {
	pd := p.Pools[idx].Decommission
	if pd != nil {
		if failed {
			pd.ItemsDecommissionFailed++
			pd.BytesFailed += size
		} else {
			pd.ItemsDecommissioned++
			pd.BytesDone += size
		}
		p.Pools[idx].Decommission = pd
	}
}

func (p *poolMeta) updateAfter(ctx context.Context, idx int, pools []*erasureSets, duration time.Duration) (bool, error) {
	if p.Pools[idx].Decommission == nil {
		return false, errInvalidArgument
	}
	now := UTCNow()
	if now.Sub(p.Pools[idx].LastUpdate) >= duration {
		if serverDebugLog {
			console.Debugf("decommission: persisting poolMeta on disk: threshold:%s, poolMeta:%#v\n", now.Sub(p.Pools[idx].LastUpdate), p.Pools[idx])
		}
		p.Pools[idx].LastUpdate = now
		if err := p.save(ctx, pools); err != nil {
			return false, err
		}
		return true, nil
	}
	return false, nil
}

func (p poolMeta) save(ctx context.Context, pools []*erasureSets) error {
	data := make([]byte, 4, p.Msgsize()+4)

	// Initialize the header.
	binary.LittleEndian.PutUint16(data[0:2], poolMetaFormat)
	binary.LittleEndian.PutUint16(data[2:4], poolMetaVersion)

	buf, err := p.MarshalMsg(data)
	if err != nil {
		return err
	}

	// Saves on all pools to make sure decommissioning of first pool is allowed.
	for _, eset := range pools {
		if err = saveConfig(ctx, eset, poolMetaName, buf); err != nil {
			return err
		}
	}
	return nil
}

const (
	poolMetaName      = "pool.bin"
	poolMetaFormat    = 1
	poolMetaVersionV1 = 1
	poolMetaVersion   = poolMetaVersionV1
)

// Init() initializes pools and saves additional information about them
// in 'pool.bin', this is eventually used for decommissioning the pool.
func (z *erasureServerPools) Init(ctx context.Context) error {
	meta := poolMeta{}

	if err := meta.load(ctx, z.serverPools[0], z.serverPools); err != nil {
		return err
	}

	update, err := meta.validate(z.serverPools)
	if err != nil {
		return err
	}

	// if no update is needed return right away.
	if !update {
		// We are only supporting single pool decommission at this time
		// so it makes sense to only resume single pools at any given
		// time, in future meta.returnResumablePools() might take
		// '-1' as argument to decommission multiple pools at a time
		// but this is not a priority at the moment.
		for _, pool := range meta.returnResumablePools(1) {
			err := z.Decommission(ctx, pool.ID)
			switch err {
			case errDecommissionAlreadyRunning:
				fallthrough
			case nil:
				go z.doDecommissionInRoutine(ctx, pool.ID)
			}
		}
		z.poolMeta = meta

		return nil
	}

	meta = poolMeta{} // to update write poolMeta fresh.
	// looks like new pool was added we need to update,
	// or this is a fresh installation (or an existing
	// installation with pool removed)
	meta.Version = poolMetaVersion
	for idx, pool := range z.serverPools {
		meta.Pools = append(meta.Pools, PoolStatus{
			CmdLine:    pool.endpoints.CmdLine,
			ID:         idx,
			LastUpdate: UTCNow(),
		})
	}
	if err = meta.save(ctx, z.serverPools); err != nil {
		return err
	}
	z.poolMeta = meta
	return nil
}

func (z *erasureServerPools) decommissionObject(ctx context.Context, bucket string, gr *GetObjectReader) (err error) {
	defer gr.Close()
	objInfo := gr.ObjInfo
	if objInfo.isMultipart() {
		uploadID, err := z.NewMultipartUpload(ctx, bucket, objInfo.Name, ObjectOptions{
			VersionID:   objInfo.VersionID,
			MTime:       objInfo.ModTime,
			UserDefined: objInfo.UserDefined,
		})
		if err != nil {
			return err
		}
		defer z.AbortMultipartUpload(ctx, bucket, objInfo.Name, uploadID, ObjectOptions{})
		parts := make([]CompletePart, len(objInfo.Parts))
		for i, part := range objInfo.Parts {
			hr, err := hash.NewReader(gr, part.Size, "", "", part.Size)
			if err != nil {
				return err
			}
			pi, err := z.PutObjectPart(ctx, bucket, objInfo.Name, uploadID,
				part.Number,
				NewPutObjReader(hr),
				ObjectOptions{})
			if err != nil {
				return err
			}
			parts[i] = CompletePart{
				ETag:       pi.ETag,
				PartNumber: pi.PartNumber,
			}
		}
		_, err = z.CompleteMultipartUpload(ctx, bucket, objInfo.Name, uploadID, parts, ObjectOptions{
			MTime: objInfo.ModTime,
		})
		return err
	}
	hr, err := hash.NewReader(gr, objInfo.Size, "", "", objInfo.Size)
	if err != nil {
		return err
	}
	_, err = z.PutObject(ctx,
		bucket,
		objInfo.Name,
		NewPutObjReader(hr),
		ObjectOptions{
			VersionID:   objInfo.VersionID,
			MTime:       objInfo.ModTime,
			UserDefined: objInfo.UserDefined,
		})
	return err
}

// versionsSorter sorts FileInfo slices by version.
//msgp:ignore versionsSorter
type versionsSorter []FileInfo

func (v versionsSorter) reverse() {
	sort.Slice(v, func(i, j int) bool {
		return v[i].ModTime.Before(v[j].ModTime)
	})
}

func (z *erasureServerPools) decommissionPool(ctx context.Context, idx int, pool *erasureSets, bName string) error {
	var forwardTo string
	// If we resume to the same bucket, forward to last known item.
	rbucket, robject := z.poolMeta.ResumeBucketObject(idx)
	if rbucket != "" && rbucket == bName {
		forwardTo = robject
	}

	versioned := globalBucketVersioningSys.Enabled(bName)
	for _, set := range pool.sets {
		disks := set.getOnlineDisks()
		if len(disks) == 0 {
			logger.LogIf(GlobalContext, fmt.Errorf("no online disks found for set with endpoints %s",
				set.getEndpoints()))
			continue
		}

		decommissionEntry := func(entry metaCacheEntry) {
			if entry.isDir() {
				return
			}

			fivs, err := entry.fileInfoVersions(bName)
			if err != nil {
				return
			}

			// We need a reversed order for Decommissioning,
			// to create the appropriate stack.
			versionsSorter(fivs.Versions).reverse()

			for _, version := range fivs.Versions {
				// TODO: Skip transitioned objects for now.
				if version.IsRemote() {
					continue
				}
				// We will skip decommissioning delete markers
				// with single version, its as good as there
				// is no data associated with the object.
				if version.Deleted && len(fivs.Versions) == 1 {
					continue
				}
				if version.Deleted {
					_, err := z.DeleteObject(ctx,
						bName,
						version.Name,
						ObjectOptions{
							Versioned:         versioned,
							VersionID:         version.VersionID,
							MTime:             version.ModTime,
							DeleteReplication: version.ReplicationState,
						})
					if err != nil {
						logger.LogIf(ctx, err)
						z.poolMetaMutex.Lock()
						z.poolMeta.CountItem(idx, 0, true)
						z.poolMetaMutex.Unlock()
					} else {
						set.DeleteObject(ctx,
							bName,
							version.Name,
							ObjectOptions{
								VersionID: version.VersionID,
							})
						z.poolMetaMutex.Lock()
						z.poolMeta.CountItem(idx, 0, false)
						z.poolMetaMutex.Unlock()
					}
					continue
				}
				gr, err := set.GetObjectNInfo(ctx,
					bName,
					version.Name,
					nil,
					http.Header{},
					noLock, // all mutations are blocked reads are safe without locks.
					ObjectOptions{
						VersionID: version.VersionID,
					})
				if err != nil {
					logger.LogIf(ctx, err)
					z.poolMetaMutex.Lock()
					z.poolMeta.CountItem(idx, version.Size, true)
					z.poolMetaMutex.Unlock()
					continue
				}
				// gr.Close() is ensured by decommissionObject().
				if err = z.decommissionObject(ctx, bName, gr); err != nil {
					logger.LogIf(ctx, err)
					z.poolMetaMutex.Lock()
					z.poolMeta.CountItem(idx, version.Size, true)
					z.poolMetaMutex.Unlock()
					continue
				}
				set.DeleteObject(ctx,
					bName,
					version.Name,
					ObjectOptions{
						VersionID: version.VersionID,
					})
				z.poolMetaMutex.Lock()
				z.poolMeta.CountItem(idx, version.Size, false)
				z.poolMetaMutex.Unlock()
			}
			z.poolMetaMutex.Lock()
			z.poolMeta.TrackCurrentBucketObject(idx, bName, entry.name)
			ok, err := z.poolMeta.updateAfter(ctx, idx, z.serverPools, 30*time.Second)
			logger.LogIf(ctx, err)
			if ok {
				globalNotificationSys.ReloadPoolMeta(ctx)
			}
			z.poolMetaMutex.Unlock()
		}

		// How to resolve partial results.
		resolver := metadataResolutionParams{
			dirQuorum: len(disks) / 2, // make sure to capture all quorum ratios
			objQuorum: len(disks) / 2, // make sure to capture all quorum ratios
			bucket:    bName,
		}

		if err := listPathRaw(ctx, listPathRawOptions{
			disks:          disks,
			bucket:         bName,
			recursive:      true,
			forwardTo:      forwardTo,
			minDisks:       len(disks) / 2, // to capture all quorum ratios
			reportNotFound: false,
			agreed:         decommissionEntry,
			partial: func(entries metaCacheEntries, nAgreed int, errs []error) {
				entry, ok := entries.resolve(&resolver)
				if ok {
					decommissionEntry(*entry)
				}
			},
			finished: nil,
		}); err != nil {
			// Decommissioning failed and won't continue
			return err
		}
	}
	return nil
}

func (z *erasureServerPools) decommissionInBackground(ctx context.Context, idx int) error {
	pool := z.serverPools[idx]
	for _, bucket := range z.poolMeta.PendingBuckets(idx) {
		if z.poolMeta.isBucketDecommissioned(idx, bucket) {
			if serverDebugLog {
				console.Debugln("decommission: already done, moving on", bucket)
			}

			z.poolMetaMutex.Lock()
			z.poolMeta.BucketDone(idx, bucket) // remove from pendingBuckets and persist.
			z.poolMeta.save(ctx, z.serverPools)
			z.poolMetaMutex.Unlock()
			continue
		}
		if serverDebugLog {
			console.Debugln("decommission: currently on bucket", bucket)
		}
		if err := z.decommissionPool(ctx, idx, pool, bucket); err != nil {
			return err
		}
		z.poolMetaMutex.Lock()
		z.poolMeta.BucketDone(idx, bucket)
		z.poolMeta.save(ctx, z.serverPools)
		z.poolMetaMutex.Unlock()
	}
	return nil
}

func (z *erasureServerPools) doDecommissionInRoutine(ctx context.Context, idx int) {
	z.poolMetaMutex.Lock()
	var dctx context.Context
	dctx, z.decommissionCancelers[idx] = context.WithCancel(GlobalContext)
	z.poolMetaMutex.Unlock()

	if err := z.decommissionInBackground(dctx, idx); err != nil {
		logger.LogIf(GlobalContext, err)
		logger.LogIf(GlobalContext, z.DecommissionFailed(dctx, idx))
		return
	}
	// Complete the decommission..
	logger.LogIf(GlobalContext, z.CompleteDecommission(dctx, idx))
}

func (z *erasureServerPools) IsSuspended(idx int) bool {
	z.poolMetaMutex.Lock()
	defer z.poolMetaMutex.Unlock()
	return z.poolMeta.IsSuspended(idx)
}

// Decommission - start decommission session.
func (z *erasureServerPools) Decommission(ctx context.Context, idx int) error {
	if idx < 0 {
		return errInvalidArgument
	}

	if z.SinglePool() {
		return errInvalidArgument
	}

	// Make pool unwritable before decommissioning.
	if err := z.StartDecommission(ctx, idx); err != nil {
		return err
	}

	go z.doDecommissionInRoutine(ctx, idx)

	// Successfully started decommissioning.
	return nil
}

type decomError struct {
	Err string
}

func (d decomError) Error() string {
	return d.Err
}

type poolSpaceInfo struct {
	Free  int64
	Total int64
	Used  int64
}

func (z *erasureServerPools) getDecommissionPoolSpaceInfo(idx int) (pi poolSpaceInfo, err error) {
	if idx < 0 {
		return pi, errInvalidArgument
	}
	if idx+1 > len(z.serverPools) {
		return pi, errInvalidArgument
	}
	info, errs := z.serverPools[idx].StorageInfo(context.Background())
	for _, err := range errs {
		if err != nil {
			return pi, errInvalidArgument
		}
	}
	info.Backend = z.BackendInfo()
	for _, disk := range info.Disks {
		if disk.Healing {
			return pi, decomError{
				Err: fmt.Sprintf("%s drive is healing, decommission will not be started", disk.Endpoint),
			}
		}
	}

	usableTotal := int64(GetTotalUsableCapacity(info.Disks, info))
	usableFree := int64(GetTotalUsableCapacityFree(info.Disks, info))
	return poolSpaceInfo{
		Total: usableTotal,
		Free:  usableFree,
		Used:  usableTotal - usableFree,
	}, nil
}

func (z *erasureServerPools) Status(ctx context.Context, idx int) (PoolStatus, error) {
	if idx < 0 {
		return PoolStatus{}, errInvalidArgument
	}

	z.poolMetaMutex.RLock()
	defer z.poolMetaMutex.RUnlock()

	pi, err := z.getDecommissionPoolSpaceInfo(idx)
	if err != nil {
		return PoolStatus{}, errInvalidArgument
	}

	poolInfo := z.poolMeta.Pools[idx]
	if poolInfo.Decommission != nil {
		poolInfo.Decommission.TotalSize = pi.Total
		poolInfo.Decommission.CurrentSize = poolInfo.Decommission.StartSize + poolInfo.Decommission.BytesDone
	} else {
		poolInfo.Decommission = &PoolDecommissionInfo{
			TotalSize:   pi.Total,
			CurrentSize: pi.Free,
		}
	}
	return poolInfo, nil
}

func (z *erasureServerPools) ReloadPoolMeta(ctx context.Context) (err error) {
	meta := poolMeta{}

	if err = meta.load(ctx, z.serverPools[0], z.serverPools); err != nil {
		return err
	}

	z.poolMetaMutex.Lock()
	defer z.poolMetaMutex.Unlock()

	z.poolMeta = meta
	return nil
}

func (z *erasureServerPools) DecommissionCancel(ctx context.Context, idx int) (err error) {
	if idx < 0 {
		return errInvalidArgument
	}

	if z.SinglePool() {
		return errInvalidArgument
	}

	z.poolMetaMutex.Lock()
	defer z.poolMetaMutex.Unlock()

	if z.poolMeta.DecommissionCancel(idx) {
		z.decommissionCancelers[idx]() // cancel any active thread.
		if err = z.poolMeta.save(ctx, z.serverPools); err != nil {
			return err
		}
		globalNotificationSys.ReloadPoolMeta(ctx)
	}
	return nil
}

func (z *erasureServerPools) DecommissionFailed(ctx context.Context, idx int) (err error) {
	if idx < 0 {
		return errInvalidArgument
	}

	if z.SinglePool() {
		return errInvalidArgument
	}

	z.poolMetaMutex.Lock()
	defer z.poolMetaMutex.Unlock()

	if z.poolMeta.DecommissionFailed(idx) {
		z.decommissionCancelers[idx]() // cancel any active thread.
		if err = z.poolMeta.save(ctx, z.serverPools); err != nil {
			return err
		}
		globalNotificationSys.ReloadPoolMeta(ctx)
	}
	return nil
}

func (z *erasureServerPools) CompleteDecommission(ctx context.Context, idx int) (err error) {
	if idx < 0 {
		return errInvalidArgument
	}

	if z.SinglePool() {
		return errInvalidArgument
	}

	z.poolMetaMutex.Lock()
	defer z.poolMetaMutex.Unlock()

	if z.poolMeta.DecommissionComplete(idx) {
		if err = z.poolMeta.save(ctx, z.serverPools); err != nil {
			return err
		}
		globalNotificationSys.ReloadPoolMeta(ctx)
	}
	return nil
}

func (z *erasureServerPools) StartDecommission(ctx context.Context, idx int) (err error) {
	if idx < 0 {
		return errInvalidArgument
	}

	if z.SinglePool() {
		return errInvalidArgument
	}

	buckets, err := z.ListBuckets(ctx)
	if err != nil {
		return err
	}

	// TODO: Support decommissioning transition tiers.
	for _, bucket := range buckets {
		if lc, err := globalLifecycleSys.Get(bucket.Name); err == nil {
			if lc.HasTransition() {
				return decomError{
					Err: fmt.Sprintf("Bucket is part of transitioned tier %s: decommission is not allowed in Tier'd setups", bucket.Name),
				}
			}
		}
	}

	// Buckets data are dispersed in multiple zones/sets, make
	// sure to decommission the necessary metadata.
	buckets = append(buckets, BucketInfo{
		Name: pathJoin(minioMetaBucket, minioConfigPrefix),
	})
	buckets = append(buckets, BucketInfo{
		Name: pathJoin(minioMetaBucket, bucketMetaPrefix),
	})

	var pool *erasureSets
	for pidx := range z.serverPools {
		if pidx == idx {
			pool = z.serverPools[idx]
			break
		}
	}

	if pool == nil {
		return errInvalidArgument
	}

	pi, err := z.getDecommissionPoolSpaceInfo(idx)
	if err != nil {
		return err
	}

	z.poolMetaMutex.Lock()
	defer z.poolMetaMutex.Unlock()

	if err = z.poolMeta.Decommission(idx, pi); err != nil {
		return err
	}
	z.poolMeta.QueueBuckets(idx, buckets)
	if err = z.poolMeta.save(ctx, z.serverPools); err != nil {
		return err
	}
	globalNotificationSys.ReloadPoolMeta(ctx)
	return nil
}
