<span style="color:#0000BB">RPM Installation</span>
====

### Setting SELinux

1. Edit '/etc/selinux/config' file as below using `vim`
2. Save and Reboot

    ...
    SELINUX=disabled
    ...

### Settting repository for AnyStor-E

    # vim /etc/yum.repos.d/anystor-e.repo

    [anystor-e]
    name=AnyStor Enterprise Repository for production
    baseurl=http://abs.gluesys.com/repo/anystor/3.0/os/x86_64
    enabled=1
    gpgcheck=0

    [anystor-e-testing]
    name=AnyStor Enterprise Repository for development
    baseurl=http://abs.gluesys.com/repo/testing/3.0/os/x86_64
    enabled=0
    gpgcheck=0

    [anystor-e-debuginfo]
    name=AnyStor Enterprise Repository for DebugInfo
    baseurl=http://abs.gluesys.com/repo/anystor/3.0/debuginfo/x86_64
    enabled=0
    gpgcheck=0

    [anystor-e-testing-debuginfo]
    name=AnyStor Enterprise Repository for DebugInfo
    baseurl=http://abs.gluesys.com/repo/testing/3.0/debuginfo/x86_64
    enabled=0
    gpgcheck=0

    # yum clean all

#### Install the AnyStor-E cluster storage management

    # yum install anystor-e

