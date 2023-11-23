# vim: expandtab smarttab shiftwidth=4 softtabstop=4
from nose.tools import assert_raises, assert_equal, assert_not_equal, assert_greater, with_setup
import cephfs as libcephfs
import fcntl
import os
import random
import time
import stat
import uuid
from datetime import datetime

cephfs = None

def setup_module():
    global cephfs
    cephfs = libcephfs.LibCephFS(conffile='')
    cephfs.mount()

def teardown_module():
    global cephfs
    cephfs.shutdown()

def setup_test():
    d = cephfs.opendir(b"/")
    dent = cephfs.readdir(d)
    while dent:
        if (dent.d_name not in [b".", b".."]):
            if dent.is_dir():
                cephfs.rmdir(b"/" + dent.d_name)
            else:
                cephfs.unlink(b"/" + dent.d_name)

        dent = cephfs.readdir(d)

    cephfs.closedir(d)

    cephfs.chdir(b"/")
    _, ret_buf = cephfs.listxattr("/")
    print(f'ret_buf={ret_buf}')
    xattrs = ret_buf.decode('utf-8').split('\x00')
    for xattr in xattrs[:-1]:
        cephfs.removexattr("/", xattr)

@with_setup(setup_test)
def test_conf_get():
    fsid = cephfs.conf_get("fsid")
    assert(len(fsid) > 0)

@with_setup(setup_test)
def test_version():
    cephfs.version()

@with_setup(setup_test)
def test_fstat():
    fd = cephfs.open(b'file-1', 'w', 0o755)
    stat = cephfs.fstat(fd)
    assert(len(stat) == 13)
    cephfs.close(fd)

@with_setup(setup_test)
def test_statfs():
    stat = cephfs.statfs(b'/')
    assert(len(stat) == 11)

@with_setup(setup_test)
def test_statx():
    stat = cephfs.statx(b'/', libcephfs.CEPH_STATX_MODE, 0)
    assert('mode' in stat.keys())
    stat = cephfs.statx(b'/', libcephfs.CEPH_STATX_BTIME, 0)
    assert('btime' in stat.keys())
    
    fd = cephfs.open(b'file-1', 'w', 0o755)
    cephfs.write(fd, b"1111", 0)
    cephfs.close(fd)
    cephfs.symlink(b'file-1', b'file-2')
    stat = cephfs.statx(b'file-2', libcephfs.CEPH_STATX_MODE | libcephfs.CEPH_STATX_BTIME, libcephfs.AT_SYMLINK_NOFOLLOW)
    assert('mode' in stat.keys())
    assert('btime' in stat.keys())
    cephfs.unlink(b'file-2')
    cephfs.unlink(b'file-1')

@with_setup(setup_test)
def test_syncfs():
    stat = cephfs.sync_fs()

@with_setup(setup_test)
def test_fsync():
    fd = cephfs.open(b'file-1', 'w', 0o755)
    cephfs.write(fd, b"asdf", 0)
    stat = cephfs.fsync(fd, 0)
    cephfs.write(fd, b"qwer", 0)
    stat = cephfs.fsync(fd, 1)
    cephfs.close(fd)
    #sync on non-existing fd (assume fd 12345 is not exists)
    assert_raises(libcephfs.Error, cephfs.fsync, 12345, 0)

@with_setup(setup_test)
def test_directory():
    cephfs.mkdir(b"/temp-directory", 0o755)
    cephfs.mkdirs(b"/temp-directory/foo/bar", 0o755)
    cephfs.chdir(b"/temp-directory")
    assert_equal(cephfs.getcwd(), b"/temp-directory")
    cephfs.rmdir(b"/temp-directory/foo/bar")
    cephfs.rmdir(b"/temp-directory/foo")
    cephfs.rmdir(b"/temp-directory")
    assert_raises(libcephfs.ObjectNotFound, cephfs.chdir, b"/temp-directory")

@with_setup(setup_test)
def test_walk_dir():
    cephfs.chdir(b"/")
    dirs = [b"dir-1", b"dir-2", b"dir-3"]
    for i in dirs:
        cephfs.mkdir(i, 0o755)
    handler = cephfs.opendir(b"/")
    d = cephfs.readdir(handler)
    dirs += [b".", b".."]
    while d:
        assert(d.d_name in dirs)
        dirs.remove(d.d_name)
        d = cephfs.readdir(handler)
    assert(len(dirs) == 0)
    dirs = [b"/dir-1", b"/dir-2", b"/dir-3"]
    for i in dirs:
        cephfs.rmdir(i)
    cephfs.closedir(handler)

@with_setup(setup_test)
def test_xattr():
    assert_raises(libcephfs.OperationNotSupported, cephfs.setxattr, "/", "key", b"value", 0)
    cephfs.setxattr("/", "user.key", b"value", 0)
    assert_equal(b"value", cephfs.getxattr("/", "user.key"))

    cephfs.setxattr("/", "user.big", b"x" * 300, 0)

    # Default size is 255, get ERANGE
    assert_raises(libcephfs.OutOfRange, cephfs.getxattr, "/", "user.big")

    # Pass explicit size, and we'll get the value
    assert_equal(300, len(cephfs.getxattr("/", "user.big", 300)))

    cephfs.removexattr("/", "user.key")
    # user.key is already removed
    assert_raises(libcephfs.NoData, cephfs.getxattr, "/", "user.key")

    # user.big is only listed
    ret_val, ret_buff = cephfs.listxattr("/")
    assert_equal(9, ret_val)
    assert_equal("user.big\x00", ret_buff.decode('utf-8'))

@with_setup(setup_test)
def test_ceph_mirror_xattr():
    def gen_mirror_xattr():
        cluster_id = str(uuid.uuid4())
        fs_id = random.randint(1, 10)
        mirror_xattr = f'cluster_id={cluster_id} fs_id={fs_id}'
        return mirror_xattr.encode('utf-8')

    mirror_xattr_enc_1 = gen_mirror_xattr()

    # mirror xattr is only allowed on root
    cephfs.mkdir('/d0', 0o755)
    assert_raises(libcephfs.InvalidValue, cephfs.setxattr,
                  '/d0', 'ceph.mirror.info', mirror_xattr_enc_1, os.XATTR_CREATE)
    cephfs.rmdir('/d0')

    cephfs.setxattr('/', 'ceph.mirror.info', mirror_xattr_enc_1, os.XATTR_CREATE)
    assert_equal(mirror_xattr_enc_1, cephfs.getxattr('/', 'ceph.mirror.info'))

    # setting again with XATTR_CREATE should fail
    assert_raises(libcephfs.ObjectExists, cephfs.setxattr,
                  '/', 'ceph.mirror.info', mirror_xattr_enc_1, os.XATTR_CREATE)

    # ceph.mirror.info should not show up in listing
    ret_val, _ = cephfs.listxattr("/")
    assert_equal(0, ret_val)

    mirror_xattr_enc_2 = gen_mirror_xattr()

    cephfs.setxattr('/', 'ceph.mirror.info', mirror_xattr_enc_2, os.XATTR_REPLACE)
    assert_equal(mirror_xattr_enc_2, cephfs.getxattr('/', 'ceph.mirror.info'))

    cephfs.removexattr('/', 'ceph.mirror.info')
    # ceph.mirror.info is already removed
    assert_raises(libcephfs.NoData, cephfs.getxattr, '/', 'ceph.mirror.info')
    # removing again should throw error
    assert_raises(libcephfs.NoData, cephfs.removexattr, "/", "ceph.mirror.info")

    # check mirror info xattr format
    assert_raises(libcephfs.InvalidValue, cephfs.setxattr, '/', 'ceph.mirror.info', b"unknown", 0)

@with_setup(setup_test)
def test_fxattr():
    fd = cephfs.open(b'/file-fxattr', 'w', 0o755)
    assert_raises(libcephfs.OperationNotSupported, cephfs.fsetxattr, fd, "key", b"value", 0)
    assert_raises(TypeError, cephfs.fsetxattr, "fd", "user.key", b"value", 0)
    assert_raises(TypeError, cephfs.fsetxattr, fd, "user.key", "value", 0)
    assert_raises(TypeError, cephfs.fsetxattr, fd, "user.key", b"value", "0")
    cephfs.fsetxattr(fd, "user.key", b"value", 0)
    assert_equal(b"value", cephfs.fgetxattr(fd, "user.key"))

    cephfs.fsetxattr(fd, "user.big", b"x" * 300, 0)

    # Default size is 255, get ERANGE
    assert_raises(libcephfs.OutOfRange, cephfs.fgetxattr, fd, "user.big")

    # Pass explicit size, and we'll get the value
    assert_equal(300, len(cephfs.fgetxattr(fd, "user.big", 300)))

    cephfs.fremovexattr(fd, "user.key")
    # user.key is already removed
    assert_raises(libcephfs.NoData, cephfs.fgetxattr, fd, "user.key")

    # user.big is only listed
    ret_val, ret_buff = cephfs.flistxattr(fd)
    assert_equal(9, ret_val)
    assert_equal("user.big\x00", ret_buff.decode('utf-8'))
    cephfs.close(fd)
    cephfs.unlink(b'/file-fxattr')

@with_setup(setup_test)
def test_rename():
    cephfs.mkdir(b"/a", 0o755)
    cephfs.mkdir(b"/a/b", 0o755)
    cephfs.rename(b"/a", b"/b")
    cephfs.stat(b"/b/b")
    cephfs.rmdir(b"/b/b")
    cephfs.rmdir(b"/b")

@with_setup(setup_test)
def test_open():
    assert_raises(libcephfs.ObjectNotFound, cephfs.open, b'file-1', 'r')
    assert_raises(libcephfs.ObjectNotFound, cephfs.open, b'file-1', 'r+')
    fd = cephfs.open(b'file-1', 'w', 0o755)
    cephfs.write(fd, b"asdf", 0)
    cephfs.close(fd)
    fd = cephfs.open(b'file-1', 'r', 0o755)
    assert_equal(cephfs.read(fd, 0, 4), b"asdf")
    cephfs.close(fd)
    fd = cephfs.open(b'file-1', 'r+', 0o755)
    cephfs.write(fd, b"zxcv", 4)
    assert_equal(cephfs.read(fd, 4, 8), b"zxcv")
    cephfs.close(fd)
    fd = cephfs.open(b'file-1', 'w+', 0o755)
    assert_equal(cephfs.read(fd, 0, 4), b"")
    cephfs.write(fd, b"zxcv", 4)
    assert_equal(cephfs.read(fd, 4, 8), b"zxcv")
    cephfs.close(fd)
    fd = cephfs.open(b'file-1', os.O_RDWR, 0o755)
    cephfs.write(fd, b"asdf", 0)
    assert_equal(cephfs.read(fd, 0, 4), b"asdf")
    cephfs.close(fd)
    assert_raises(libcephfs.OperationNotSupported, cephfs.open, b'file-1', 'a')
    cephfs.unlink(b'file-1')

@with_setup(setup_test)
def test_link():
    fd = cephfs.open(b'file-1', 'w', 0o755)
    cephfs.write(fd, b"1111", 0)
    cephfs.close(fd)
    cephfs.link(b'file-1', b'file-2')
    fd = cephfs.open(b'file-2', 'r', 0o755)
    assert_equal(cephfs.read(fd, 0, 4), b"1111")
    cephfs.close(fd)
    fd = cephfs.open(b'file-2', 'r+', 0o755)
    cephfs.write(fd, b"2222", 4)
    cephfs.close(fd)
    fd = cephfs.open(b'file-1', 'r', 0o755)
    assert_equal(cephfs.read(fd, 0, 8), b"11112222")
    cephfs.close(fd)
    cephfs.unlink(b'file-2')

@with_setup(setup_test)
def test_symlink():
    fd = cephfs.open(b'file-1', 'w', 0o755)
    cephfs.write(fd, b"1111", 0)
    cephfs.close(fd)
    cephfs.symlink(b'file-1', b'file-2')
    fd = cephfs.open(b'file-2', 'r', 0o755)
    assert_equal(cephfs.read(fd, 0, 4), b"1111")
    cephfs.close(fd)
    fd = cephfs.open(b'file-2', 'r+', 0o755)
    cephfs.write(fd, b"2222", 4)
    cephfs.close(fd)
    fd = cephfs.open(b'file-1', 'r', 0o755)
    assert_equal(cephfs.read(fd, 0, 8), b"11112222")
    cephfs.close(fd)
    cephfs.unlink(b'file-2')

@with_setup(setup_test)
def test_readlink():
    fd = cephfs.open(b'/file-1', 'w', 0o755)
    cephfs.write(fd, b"1111", 0)
    cephfs.close(fd)
    cephfs.symlink(b'/file-1', b'/file-2')
    d = cephfs.readlink(b"/file-2",100)
    assert_equal(d, b"/file-1")
    cephfs.unlink(b'/file-2')
    cephfs.unlink(b'/file-1')

@with_setup(setup_test)
def test_delete_cwd():
    assert_equal(b"/", cephfs.getcwd())

    cephfs.mkdir(b"/temp-directory", 0o755)
    cephfs.chdir(b"/temp-directory")
    cephfs.rmdir(b"/temp-directory")

    # getcwd gives you something stale here: it remembers the path string
    # even when things are unlinked.  It's up to the caller to find out
    # whether it really still exists
    assert_equal(b"/temp-directory", cephfs.getcwd())

@with_setup(setup_test)
def test_flock():
    fd = cephfs.open(b'file-1', 'w', 0o755)

    cephfs.flock(fd, fcntl.LOCK_EX, 123);
    fd2 = cephfs.open(b'file-1', 'w', 0o755)

    assert_raises(libcephfs.WouldBlock, cephfs.flock, fd2,
                  fcntl.LOCK_EX | fcntl.LOCK_NB, 456);
    cephfs.close(fd2)

    cephfs.close(fd)

@with_setup(setup_test)
def test_mount_unmount():
    test_directory()
    cephfs.unmount()
    cephfs.mount()
    test_open()

@with_setup(setup_test)
def test_lxattr():
    fd = cephfs.open(b'/file-lxattr', 'w', 0o755)
    cephfs.close(fd)
    cephfs.setxattr(b"/file-lxattr", "user.key", b"value", 0)
    cephfs.symlink(b"/file-lxattr", b"/file-sym-lxattr")
    assert_equal(b"value", cephfs.getxattr(b"/file-sym-lxattr", "user.key"))
    assert_raises(libcephfs.NoData, cephfs.lgetxattr, b"/file-sym-lxattr", "user.key")

    cephfs.lsetxattr(b"/file-sym-lxattr", "trusted.key-sym", b"value-sym", 0)
    assert_equal(b"value-sym", cephfs.lgetxattr(b"/file-sym-lxattr", "trusted.key-sym"))
    cephfs.lsetxattr(b"/file-sym-lxattr", "trusted.big", b"x" * 300, 0)

    # Default size is 255, get ERANGE
    assert_raises(libcephfs.OutOfRange, cephfs.lgetxattr, b"/file-sym-lxattr", "trusted.big")

    # Pass explicit size, and we'll get the value
    assert_equal(300, len(cephfs.lgetxattr(b"/file-sym-lxattr", "trusted.big", 300)))

    cephfs.lremovexattr(b"/file-sym-lxattr", "trusted.key-sym")
    # trusted.key-sym is already removed
    assert_raises(libcephfs.NoData, cephfs.lgetxattr, b"/file-sym-lxattr", "trusted.key-sym")

    # trusted.big is only listed
    ret_val, ret_buff = cephfs.llistxattr(b"/file-sym-lxattr")
    assert_equal(12, ret_val)
    assert_equal("trusted.big\x00", ret_buff.decode('utf-8'))
    cephfs.unlink(b'/file-lxattr')
    cephfs.unlink(b'/file-sym-lxattr')

@with_setup(setup_test)
def test_mount_root():
    cephfs.mkdir(b"/mount-directory", 0o755)
    cephfs.unmount()
    cephfs.mount(mount_root = b"/mount-directory")

    assert_raises(libcephfs.Error, cephfs.mount, mount_root = b"/nowhere")
    cephfs.unmount()
    cephfs.mount()

@with_setup(setup_test)
def test_utime():
    fd = cephfs.open(b'/file-1', 'w', 0o755)
    cephfs.write(fd, b'0000', 0)
    cephfs.close(fd)

    stx_pre = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, 0)

    time.sleep(1)
    cephfs.utime(b'/file-1')

    stx_post = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, 0)

    assert_greater(stx_post['atime'], stx_pre['atime'])
    assert_greater(stx_post['mtime'], stx_pre['mtime'])

    atime_pre = int(time.mktime(stx_pre['atime'].timetuple()))
    mtime_pre = int(time.mktime(stx_pre['mtime'].timetuple()))

    cephfs.utime(b'/file-1', (atime_pre, mtime_pre))
    stx_post = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, 0)

    assert_equal(stx_post['atime'], stx_pre['atime'])
    assert_equal(stx_post['mtime'], stx_pre['mtime'])

    cephfs.unlink(b'/file-1')

@with_setup(setup_test)
def test_futime():
    fd = cephfs.open(b'/file-1', 'w', 0o755)
    cephfs.write(fd, b'0000', 0)

    stx_pre = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, 0)

    time.sleep(1)
    cephfs.futime(fd)

    stx_post = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, 0)

    assert_greater(stx_post['atime'], stx_pre['atime'])
    assert_greater(stx_post['mtime'], stx_pre['mtime'])

    atime_pre = int(time.mktime(stx_pre['atime'].timetuple()))
    mtime_pre = int(time.mktime(stx_pre['mtime'].timetuple()))

    cephfs.futime(fd, (atime_pre, mtime_pre))
    stx_post = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, 0)

    assert_equal(stx_post['atime'], stx_pre['atime'])
    assert_equal(stx_post['mtime'], stx_pre['mtime'])

    cephfs.close(fd)
    cephfs.unlink(b'/file-1')

@with_setup(setup_test)
def test_utimes():
    fd = cephfs.open(b'/file-1', 'w', 0o755)
    cephfs.write(fd, b'0000', 0)
    cephfs.close(fd)

    stx_pre = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, 0)

    time.sleep(1)
    cephfs.utimes(b'/file-1')

    stx_post = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, 0)

    assert_greater(stx_post['atime'], stx_pre['atime'])
    assert_greater(stx_post['mtime'], stx_pre['mtime'])

    atime_pre = time.mktime(stx_pre['atime'].timetuple())
    mtime_pre = time.mktime(stx_pre['mtime'].timetuple())

    cephfs.utimes(b'/file-1', (atime_pre, mtime_pre))
    stx_post = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, 0)

    assert_equal(stx_post['atime'], stx_pre['atime'])
    assert_equal(stx_post['mtime'], stx_pre['mtime'])

    cephfs.unlink(b'/file-1')

@with_setup(setup_test)
def test_lutimes():
    fd = cephfs.open(b'/file-1', 'w', 0o755)
    cephfs.write(fd, b'0000', 0)
    cephfs.close(fd)

    cephfs.symlink(b'/file-1', b'/file-2')

    stx_pre_t = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, 0)
    stx_pre_s = cephfs.statx(b'/file-2', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, libcephfs.AT_SYMLINK_NOFOLLOW)

    time.sleep(1)
    cephfs.lutimes(b'/file-2')

    stx_post_t = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, 0)
    stx_post_s = cephfs.statx(b'/file-2', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, libcephfs.AT_SYMLINK_NOFOLLOW)

    assert_equal(stx_post_t['atime'], stx_pre_t['atime'])
    assert_equal(stx_post_t['mtime'], stx_pre_t['mtime'])

    assert_greater(stx_post_s['atime'], stx_pre_s['atime'])
    assert_greater(stx_post_s['mtime'], stx_pre_s['mtime'])

    atime_pre = time.mktime(stx_pre_s['atime'].timetuple())
    mtime_pre = time.mktime(stx_pre_s['mtime'].timetuple())

    cephfs.lutimes(b'/file-2', (atime_pre, mtime_pre))
    stx_post_s = cephfs.statx(b'/file-2', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, libcephfs.AT_SYMLINK_NOFOLLOW)

    assert_equal(stx_post_s['atime'], stx_pre_s['atime'])
    assert_equal(stx_post_s['mtime'], stx_pre_s['mtime'])

    cephfs.unlink(b'/file-2')
    cephfs.unlink(b'/file-1')

@with_setup(setup_test)
def test_futimes():
    fd = cephfs.open(b'/file-1', 'w', 0o755)
    cephfs.write(fd, b'0000', 0)

    stx_pre = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, 0)

    time.sleep(1)
    cephfs.futimes(fd)

    stx_post = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, 0)

    assert_greater(stx_post['atime'], stx_pre['atime'])
    assert_greater(stx_post['mtime'], stx_pre['mtime'])

    atime_pre = time.mktime(stx_pre['atime'].timetuple())
    mtime_pre = time.mktime(stx_pre['mtime'].timetuple())

    cephfs.futimes(fd, (atime_pre, mtime_pre))
    stx_post = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, 0)

    assert_equal(stx_post['atime'], stx_pre['atime'])
    assert_equal(stx_post['mtime'], stx_pre['mtime'])

    cephfs.close(fd)
    cephfs.unlink(b'/file-1')

@with_setup(setup_test)
def test_futimens():
    fd = cephfs.open(b'/file-1', 'w', 0o755)
    cephfs.write(fd, b'0000', 0)

    stx_pre = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, 0)

    time.sleep(1)
    cephfs.futimens(fd)

    stx_post = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, 0)

    assert_greater(stx_post['atime'], stx_pre['atime'])
    assert_greater(stx_post['mtime'], stx_pre['mtime'])

    atime_pre = time.mktime(stx_pre['atime'].timetuple())
    mtime_pre = time.mktime(stx_pre['mtime'].timetuple())

    cephfs.futimens(fd, (atime_pre, mtime_pre))
    stx_post = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_MTIME, 0)

    assert_equal(stx_post['atime'], stx_pre['atime'])
    assert_equal(stx_post['mtime'], stx_pre['mtime'])

    cephfs.close(fd)
    cephfs.unlink(b'/file-1')

@with_setup(setup_test)
def test_lchmod():
    fd = cephfs.open(b'/file-1', 'w', 0o755)
    cephfs.write(fd, b'0000', 0)
    cephfs.close(fd)

    cephfs.symlink(b'/file-1', b'/file-2')

    stx_pre_t = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_MODE, 0)
    stx_pre_s = cephfs.statx(b'/file-2', libcephfs.CEPH_STATX_MODE, libcephfs.AT_SYMLINK_NOFOLLOW)

    time.sleep(1)
    cephfs.lchmod(b'/file-2', 0o400)

    stx_post_t = cephfs.statx(b'/file-1', libcephfs.CEPH_STATX_MODE, 0)
    stx_post_s = cephfs.statx(b'/file-2', libcephfs.CEPH_STATX_MODE, libcephfs.AT_SYMLINK_NOFOLLOW)

    assert_equal(stx_post_t['mode'], stx_pre_t['mode'])
    assert_not_equal(stx_post_s['mode'], stx_pre_s['mode'])
    stx_post_s_perm_bits = stx_post_s['mode'] & ~stat.S_IFMT(stx_post_s["mode"])
    assert_equal(stx_post_s_perm_bits, 0o400)

    cephfs.unlink(b'/file-2')
    cephfs.unlink(b'/file-1')

@with_setup(setup_test)
def test_fchmod():
    fd = cephfs.open(b'/file-fchmod', 'w', 0o655)
    st = cephfs.statx(b'/file-fchmod', libcephfs.CEPH_STATX_MODE, 0)
    mode = st["mode"] | stat.S_IXUSR
    cephfs.fchmod(fd, mode)
    st = cephfs.statx(b'/file-fchmod', libcephfs.CEPH_STATX_MODE, 0)
    assert_equal(st["mode"] & stat.S_IRWXU, stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
    assert_raises(TypeError, cephfs.fchmod, "/file-fchmod", stat.S_IXUSR)
    assert_raises(TypeError, cephfs.fchmod, fd, "stat.S_IXUSR")
    cephfs.close(fd)
    cephfs.unlink(b'/file-fchmod')

@with_setup(setup_test)
def test_fchown():
    fd = cephfs.open(b'/file-fchown', 'w', 0o655)
    uid = os.getuid()
    gid = os.getgid()
    assert_raises(TypeError, cephfs.fchown, b'/file-fchown', uid, gid)
    assert_raises(TypeError, cephfs.fchown, fd, "uid", "gid")
    cephfs.fchown(fd, uid, gid)
    st = cephfs.statx(b'/file-fchown', libcephfs.CEPH_STATX_UID | libcephfs.CEPH_STATX_GID, 0)
    assert_equal(st["uid"], uid)
    assert_equal(st["gid"], gid)
    cephfs.fchown(fd, 9999, 9999)
    st = cephfs.statx(b'/file-fchown', libcephfs.CEPH_STATX_UID | libcephfs.CEPH_STATX_GID, 0)
    assert_equal(st["uid"], 9999)
    assert_equal(st["gid"], 9999)
    cephfs.close(fd)
    cephfs.unlink(b'/file-fchown')

@with_setup(setup_test)
def test_truncate():
    fd = cephfs.open(b'/file-truncate', 'w', 0o755)
    cephfs.write(fd, b"1111", 0)
    cephfs.truncate(b'/file-truncate', 0)
    stat = cephfs.fsync(fd, 0)
    st = cephfs.statx(b'/file-truncate', libcephfs.CEPH_STATX_SIZE, 0)
    assert_equal(st["size"], 0)
    cephfs.close(fd)
    cephfs.unlink(b'/file-truncate')

@with_setup(setup_test)
def test_ftruncate():
    fd = cephfs.open(b'/file-ftruncate', 'w', 0o755)
    cephfs.write(fd, b"1111", 0)
    assert_raises(TypeError, cephfs.ftruncate, b'/file-ftruncate', 0)
    cephfs.ftruncate(fd, 0)
    stat = cephfs.fsync(fd, 0)
    st = cephfs.fstat(fd)
    assert_equal(st.st_size, 0)
    cephfs.close(fd)
    cephfs.unlink(b'/file-ftruncate')

@with_setup(setup_test)
def test_fallocate():
    fd = cephfs.open(b'/file-fallocate', 'w', 0o755)
    assert_raises(TypeError, cephfs.fallocate, b'/file-fallocate', 0, 10)
    cephfs.fallocate(fd, 0, 10)
    stat = cephfs.fsync(fd, 0)
    st = cephfs.fstat(fd)
    assert_equal(st.st_size, 10)
    cephfs.close(fd)
    cephfs.unlink(b'/file-fallocate')

@with_setup(setup_test)
def test_mknod():
    mode = stat.S_IFIFO | stat.S_IRUSR | stat.S_IWUSR
    cephfs.mknod(b'/file-fifo', mode)
    st = cephfs.statx(b'/file-fifo', libcephfs.CEPH_STATX_MODE, 0)
    assert_equal(st["mode"] & mode, mode)
    cephfs.unlink(b'/file-fifo')

@with_setup(setup_test)
def test_lazyio():
    fd = cephfs.open(b'/file-lazyio', 'w', 0o755)
    assert_raises(TypeError, cephfs.lazyio, "fd", 1)
    assert_raises(TypeError, cephfs.lazyio, fd, "1")
    cephfs.lazyio(fd, 1)
    cephfs.write(fd, b"1111", 0)
    assert_raises(TypeError, cephfs.lazyio_propagate, "fd", 0, 4)
    assert_raises(TypeError, cephfs.lazyio_propagate, fd, "0", 4)
    assert_raises(TypeError, cephfs.lazyio_propagate, fd, 0, "4")
    cephfs.lazyio_propagate(fd, 0, 4)
    st = cephfs.fstat(fd)
    assert_equal(st.st_size, 4)
    cephfs.write(fd, b"2222", 4)
    assert_raises(TypeError, cephfs.lazyio_synchronize, "fd", 0, 8)
    assert_raises(TypeError, cephfs.lazyio_synchronize, fd, "0", 8)
    assert_raises(TypeError, cephfs.lazyio_synchronize, fd, 0, "8")
    cephfs.lazyio_synchronize(fd, 0, 8)
    st = cephfs.fstat(fd)
    assert_equal(st.st_size, 8)
    cephfs.close(fd)
    cephfs.unlink(b'/file-lazyio')

@with_setup(setup_test)
def test_replication():
    fd = cephfs.open(b'/file-rep', 'w', 0o755)
    assert_raises(TypeError, cephfs.get_file_replication, "fd")
    l_dict = cephfs.get_layout(fd)
    assert('pool_name' in l_dict.keys())
    cnt = cephfs.get_file_replication(fd)
    get_rep_cnt_cmd = "ceph osd pool get " + l_dict["pool_name"] + " size"
    s=os.popen(get_rep_cnt_cmd).read().strip('\n')
    size=int(s.split(" ")[-1])
    assert_equal(cnt, size)
    cnt = cephfs.get_path_replication(b'/file-rep')
    assert_equal(cnt, size)
    cephfs.close(fd)
    cephfs.unlink(b'/file-rep')

@with_setup(setup_test)
def test_caps():
    fd = cephfs.open(b'/file-caps', 'w', 0o755)
    timeout = cephfs.get_cap_return_timeout()
    assert_equal(timeout, 300)
    fd_caps = cephfs.debug_get_fd_caps(fd)
    file_caps = cephfs.debug_get_file_caps(b'/file-caps')
    assert_equal(fd_caps, file_caps)
    cephfs.close(fd)
    cephfs.unlink(b'/file-caps')

@with_setup(setup_test)
def test_setuuid():
    ses_id_uid = uuid.uuid1()
    ses_id_str = str(ses_id_uid)
    cephfs.set_uuid(ses_id_str)

@with_setup(setup_test)
def test_session_timeout():
    assert_raises(TypeError, cephfs.set_session_timeout, "300")
    cephfs.set_session_timeout(300)

@with_setup(setup_test)
def test_readdirops():
    cephfs.chdir(b"/")
    dirs = [b"dir-1", b"dir-2", b"dir-3"]
    for i in dirs:
        cephfs.mkdir(i, 0o755)
    handler = cephfs.opendir(b"/")
    d1 = cephfs.readdir(handler)
    d2 = cephfs.readdir(handler)
    d3 = cephfs.readdir(handler)
    offset_d4 = cephfs.telldir(handler)
    d4 = cephfs.readdir(handler)
    cephfs.rewinddir(handler)
    d = cephfs.readdir(handler)
    assert_equal(d.d_name, d1.d_name)
    cephfs.seekdir(handler, offset_d4)
    d = cephfs.readdir(handler)
    assert_equal(d.d_name, d4.d_name)
    dirs += [b".", b".."]
    cephfs.rewinddir(handler)
    d = cephfs.readdir(handler)
    while d:
        assert(d.d_name in dirs)
        dirs.remove(d.d_name)
        d = cephfs.readdir(handler)
    assert(len(dirs) == 0)
    dirs = [b"/dir-1", b"/dir-2", b"/dir-3"]
    for i in dirs:
        cephfs.rmdir(i)
    cephfs.closedir(handler)

def test_preadv_pwritev():
    fd = cephfs.open(b'file-1', 'w', 0o755)
    cephfs.pwritev(fd, [b"asdf", b"zxcvb"], 0)
    cephfs.close(fd)
    fd = cephfs.open(b'file-1', 'r', 0o755)
    buf = [bytearray(i) for i in [4, 5]]
    cephfs.preadv(fd, buf, 0)
    assert_equal([b"asdf", b"zxcvb"], list(buf))
    cephfs.close(fd)
    cephfs.unlink(b'file-1')

@with_setup(setup_test)
def test_setattrx():
    fd = cephfs.open(b'file-setattrx', 'w', 0o655)
    cephfs.write(fd, b"1111", 0)
    cephfs.close(fd)
    st = cephfs.statx(b'file-setattrx', libcephfs.CEPH_STATX_MODE, 0)
    mode = st["mode"] | stat.S_IXUSR
    assert_raises(TypeError, cephfs.setattrx, b'file-setattrx', "dict", 0, 0)

    time.sleep(1)
    statx_dict = dict()
    statx_dict["mode"] = mode
    statx_dict["uid"] = 9999
    statx_dict["gid"] = 9999
    dt = datetime.now()
    statx_dict["mtime"] = dt
    statx_dict["atime"] = dt
    statx_dict["ctime"] = dt
    statx_dict["size"] = 10
    statx_dict["btime"] = dt
    cephfs.setattrx(b'file-setattrx', statx_dict, libcephfs.CEPH_SETATTR_MODE | libcephfs.CEPH_SETATTR_UID |
                                                  libcephfs.CEPH_SETATTR_GID | libcephfs.CEPH_SETATTR_MTIME |
                                                  libcephfs.CEPH_SETATTR_ATIME | libcephfs.CEPH_SETATTR_CTIME |
                                                  libcephfs.CEPH_SETATTR_SIZE | libcephfs.CEPH_SETATTR_BTIME, 0)
    st1 = cephfs.statx(b'file-setattrx', libcephfs.CEPH_STATX_MODE | libcephfs.CEPH_STATX_UID |
                                         libcephfs.CEPH_STATX_GID | libcephfs.CEPH_STATX_MTIME |
                                         libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_CTIME |
                                         libcephfs.CEPH_STATX_SIZE | libcephfs.CEPH_STATX_BTIME, 0)
    assert_equal(mode, st1["mode"])
    assert_equal(9999, st1["uid"])
    assert_equal(9999, st1["gid"])
    assert_equal(int(dt.timestamp()), int(st1["mtime"].timestamp()))
    assert_equal(int(dt.timestamp()), int(st1["atime"].timestamp()))
    assert_equal(int(dt.timestamp()), int(st1["ctime"].timestamp()))
    assert_equal(int(dt.timestamp()), int(st1["btime"].timestamp()))
    assert_equal(10, st1["size"])
    cephfs.unlink(b'file-setattrx')

@with_setup(setup_test)
def test_fsetattrx():
    fd = cephfs.open(b'file-fsetattrx', 'w', 0o655)
    cephfs.write(fd, b"1111", 0)
    st = cephfs.statx(b'file-fsetattrx', libcephfs.CEPH_STATX_MODE, 0)
    mode = st["mode"] | stat.S_IXUSR
    assert_raises(TypeError, cephfs.fsetattrx, fd, "dict", 0, 0)

    time.sleep(1)
    statx_dict = dict()
    statx_dict["mode"] = mode
    statx_dict["uid"] = 9999
    statx_dict["gid"] = 9999
    dt = datetime.now()
    statx_dict["mtime"] = dt
    statx_dict["atime"] = dt
    statx_dict["ctime"] = dt
    statx_dict["size"] = 10
    statx_dict["btime"] = dt
    cephfs.fsetattrx(fd, statx_dict, libcephfs.CEPH_SETATTR_MODE | libcephfs.CEPH_SETATTR_UID |
                                                  libcephfs.CEPH_SETATTR_GID | libcephfs.CEPH_SETATTR_MTIME |
                                                  libcephfs.CEPH_SETATTR_ATIME | libcephfs.CEPH_SETATTR_CTIME |
                                                  libcephfs.CEPH_SETATTR_SIZE | libcephfs.CEPH_SETATTR_BTIME)
    st1 = cephfs.statx(b'file-fsetattrx', libcephfs.CEPH_STATX_MODE | libcephfs.CEPH_STATX_UID |
                                         libcephfs.CEPH_STATX_GID | libcephfs.CEPH_STATX_MTIME |
                                         libcephfs.CEPH_STATX_ATIME | libcephfs.CEPH_STATX_CTIME |
                                         libcephfs.CEPH_STATX_SIZE | libcephfs.CEPH_STATX_BTIME, 0)
    assert_equal(mode, st1["mode"])
    assert_equal(9999, st1["uid"])
    assert_equal(9999, st1["gid"])
    assert_equal(int(dt.timestamp()), int(st1["mtime"].timestamp()))
    assert_equal(int(dt.timestamp()), int(st1["atime"].timestamp()))
    assert_equal(int(dt.timestamp()), int(st1["ctime"].timestamp()))
    assert_equal(int(dt.timestamp()), int(st1["btime"].timestamp()))
    assert_equal(10, st1["size"])
    cephfs.close(fd)
    cephfs.unlink(b'file-fsetattrx')

@with_setup(setup_test)
def test_get_layout():
    fd = cephfs.open(b'file-get-layout', 'w', 0o755)
    cephfs.write(fd, b"1111", 0)
    assert_raises(TypeError, cephfs.get_layout, "fd")
    l_dict = cephfs.get_layout(fd)
    assert('stripe_unit' in l_dict.keys())
    assert('stripe_count' in l_dict.keys())
    assert('object_size' in l_dict.keys())
    assert('pool_id' in l_dict.keys())
    assert('pool_name' in l_dict.keys())

    cephfs.close(fd)
    cephfs.unlink(b'file-get-layout')

@with_setup(setup_test)
def test_get_default_pool():
    dp_dict = cephfs.get_default_pool()
    assert('pool_id' in dp_dict.keys())
    assert('pool_name' in dp_dict.keys())

@with_setup(setup_test)
def test_get_pool():
    dp_dict = cephfs.get_default_pool()
    assert('pool_id' in dp_dict.keys())
    assert('pool_name' in dp_dict.keys())
    assert_equal(cephfs.get_pool_id(dp_dict["pool_name"]), dp_dict["pool_id"])
    get_rep_cnt_cmd = "ceph osd pool get " + dp_dict["pool_name"] + " size"
    s=os.popen(get_rep_cnt_cmd).read().strip('\n')
    size=int(s.split(" ")[-1])
    assert_equal(cephfs.get_pool_replication(dp_dict["pool_id"]), size)

@with_setup(setup_test)
def test_disk_quota_exceeeded_error():
    cephfs.mkdir("/dir-1", 0o755)
    cephfs.setxattr("/dir-1", "ceph.quota.max_bytes", b"5", 0)
    fd = cephfs.open(b'/dir-1/file-1', 'w', 0o755)
    assert_raises(libcephfs.DiskQuotaExceeded, cephfs.write, fd, b"abcdeghiklmnopqrstuvwxyz", 0)
    cephfs.close(fd)
    cephfs.unlink(b"/dir-1/file-1")

@with_setup(setup_test)
def test_empty_snapshot_info():
    cephfs.mkdir("/dir-1", 0o755)

    # snap without metadata
    cephfs.mkdir("/dir-1/.snap/snap0", 0o755)
    snap_info = cephfs.snap_info("/dir-1/.snap/snap0")
    assert_equal(snap_info["metadata"], {})
    assert_greater(snap_info["id"], 0)
    cephfs.rmdir("/dir-1/.snap/snap0")

    # remove directory
    cephfs.rmdir("/dir-1")

@with_setup(setup_test)
def test_snapshot_info():
    cephfs.mkdir("/dir-1", 0o755)

    # snap with custom metadata
    md = {"foo": "bar", "zig": "zag", "abcdefg": "12345"}
    cephfs.mksnap("/dir-1", "snap0", 0o755, metadata=md)
    snap_info = cephfs.snap_info("/dir-1/.snap/snap0")
    assert_equal(snap_info["metadata"]["foo"], md["foo"])
    assert_equal(snap_info["metadata"]["zig"], md["zig"])
    assert_equal(snap_info["metadata"]["abcdefg"], md["abcdefg"])
    assert_greater(snap_info["id"], 0)
    cephfs.rmsnap("/dir-1", "snap0")

    # remove directory
    cephfs.rmdir("/dir-1")

@with_setup(setup_test)
def test_set_mount_timeout_post_mount():
    assert_raises(libcephfs.LibCephFSStateError, cephfs.set_mount_timeout, 5)

@with_setup(setup_test)
def test_set_mount_timeout():
    cephfs.unmount()
    cephfs.set_mount_timeout(5)
    cephfs.mount()

@with_setup(setup_test)
def test_set_mount_timeout_lt0():
    cephfs.unmount()
    assert_raises(libcephfs.InvalidValue, cephfs.set_mount_timeout, -5)
    cephfs.mount()
