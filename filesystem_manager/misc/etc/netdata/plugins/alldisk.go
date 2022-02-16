package main

import (
	"encoding/json"
	"fmt"
	"github.com/shirou/gopsutil/disk"
	"io/ioutil"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"
)

/* 수집하고자 하는 디스크 목록 */
var pvs []string

/* 최근 PV의 I/O 양 */
var currReads map[string]uint64
var currWrites map[string]uint64

/* VG 여과를 위한 정규표현식 */
var validName = regexp.MustCompile(`^(vg_)`)
var mpathName = regexp.MustCompile(`/mpath.+`)

func main() {
	/* 명령행 인자로 입력 받은 주기를 정수형으로 변환 */
	updateEvery, err := strconv.ParseInt(os.Args[1], 10, 32)

	if err != nil {
		fmt.Print("DISABLE")
		os.Exit(1)
	}

	/* PV 목록을 조회 */
	reloadDisk()

	/* 최근 디스크의 I/O를 저장하기 위해 메모리 할당 */
	currReads = make(map[string]uint64)
	currWrites = make(map[string]uint64)

	/* CHART 정보와 METRIC을 선언 */
	fmt.Println("CHART disk.all disk.all DiskAll kilobytes/s alldisk disk.io")
	fmt.Println("DIMENSION reads")
	fmt.Println("DIMENSION writes")

	/* Tick을 생성한다.
	   Tick은 Duration을 주기로 하여 주기적으로 호출이 된다. */
	tick := time.Tick(time.Duration(updateEvery) * time.Second)
	cnt := 0

	/* 생성한 Tick을 실행
	   즉, updateEvery 주기마다 코드가 실행된다. */
	for _ = range tick {
		/* 데이터 수집 */
		collect()

		cnt += 1

		/* 1분마다 PV 목록을 갱신 */
		if cnt >= 60 {
			reloadDisk()
			cnt = 0
		}
	}
}

func reloadDisk() {
	hostname, err := os.Hostname()

	if err != nil {
		fmt.Print("DISABLE")
		os.Exit(1)
	}

	/* 로컬 etcd의 PV 정보를 가져온다. */
	file, err := ioutil.ReadFile(fmt.Sprintf("/var/lib/gms/local_etcd/%s/PV", hostname))

	if err == nil {
		pvs = []string{}
		var tempDb map[string]interface{}

		/* JSON 파싱 */
		err = json.Unmarshal(file, &tempDb)

		if err != nil {
			fmt.Print("DISABLE")
			os.Exit(1)
		}

		/* 수집한 PV 목록 중 조건에 맞는 PV만 pvs 변수에 추가 */
		for key, val := range tempDb {
			dev := val.(map[string]interface{})

			/* VG가 validName 정규표현식에 일치하는 PV만 추가 */
			if !validName.MatchString(dev["vg"].(string)) {
				continue
			}

			if mpathName.MatchString(key) {
				link, _ := os.Readlink(key)
				pvs = append(pvs,
					strings.Replace(link, "../", "", 1))
			} else {
				pvs = append(pvs,
					strings.Replace(key, "/dev/", "", -1))
			}
		}
	}
}

func collect() {
	perf := []uint64{0, 0}

	/* PV가 없을 경우에는 0으로 추가 */
	if len(pvs) == 0 {
		fmt.Println("BEGIN disk.all")
		fmt.Println("SET reads = 0.0")
		fmt.Println("SET writes = -0.0")
		fmt.Println("END")

		return
	}

	/* PV들에 대해 반복문 수행 */
	for _, dev := range pvs {
		/* PV의 IO 정보 조회 */
		devInfo, err := disk.IOCounters(dev)

		if err != nil {
			fmt.Print("DISABLE")
			os.Exit(1)
		}

		/* 조회되는 IO 정보는 누적 데이터이기 때문에 변화량을 계산 */
		if currReads[dev] != 0 {
			perf[0] += devInfo[dev].ReadBytes - currReads[dev]
			perf[1] += devInfo[dev].WriteBytes - currWrites[dev]
		}

		currReads[dev] = devInfo[dev].ReadBytes
		currWrites[dev] = devInfo[dev].WriteBytes
	}

	/* 수집된 값을 출력, 단위가 kilobytes/s이기 때문에 /1024 */
	fmt.Println("BEGIN disk.all")
	fmt.Printf("SET reads = %f\n", float64(perf[0])/1024)
	fmt.Printf("SET writes = -%f\n", float64(perf[1])/1024)
	fmt.Println("END")
}
