=================
 Welcome to Ceph
=================

Ceph uniquely delivers **object, block, and file storage in one unified
system**.

.. container:: columns-3

   .. container:: column

      .. raw:: html

          <h3>Ceph Object Store</h3>

      - RESTful Interface
      - S3- and Swift-compliant APIs
      - S3-style subdomains
      - Unified S3/Swift namespace
      - User management
      - Usage tracking
      - Striped objects
      - Cloud solution integration
      - Multi-site deployment
      - Multi-site replication

   .. container:: column

      .. raw:: html

          <h3>Ceph Block Device</h3>

      - Thin-provisioned
      - Images up to 16 exabytes
      - Configurable striping
      - In-memory caching
      - Snapshots
      - Copy-on-write cloning
      - Kernel driver support
      - KVM/libvirt support
      - Back-end for cloud solutions
      - Incremental backup
      - Disaster recovery (multisite asynchronous replication)

   .. container:: column

      .. raw:: html

          <h3>Ceph File System</h3>

      - POSIX-compliant semantics
      - Separates metadata from data
      - Dynamic rebalancing
      - Subdirectory snapshots
      - Configurable striping
      - Kernel driver support
      - FUSE support
      - NFS/CIFS deployable
      - Use with Hadoop (replace HDFS)

.. container:: columns-3

   .. container:: column

      See `Ceph Object Store`_ for additional details.

   .. container:: column

      See `Ceph Block Device`_ for additional details.

   .. container:: column

      See `Ceph File System`_ for additional details.

Ceph is highly reliable, easy to manage, and free. The power of Ceph
can transform your company's IT infrastructure and your ability to manage vast
amounts of data. To try Ceph, see our `Getting Started`_ guides. To learn more
about Ceph, see our `Architecture`_ section.



.. _Ceph Object Store: radosgw
.. _Ceph Block Device: rbd
.. _Ceph File System: cephfs
.. _Getting Started: install
.. _Architecture: architecture

.. toctree::
   :maxdepth: 3
   :hidden:

   start/intro
   install/index
   cephadm/index
   rados/index
   cephfs/index
   rbd/index
   radosgw/index
   mgr/index
   mgr/dashboard
   api/index
   architecture
   Developer Guide <dev/developer_guide/index>
   dev/internals
   governance
   foundation
   ceph-volume/index
   releases/general
   releases/index
   security/index
   Glossary <glossary>
   Tracing <jaegertracing/index>
