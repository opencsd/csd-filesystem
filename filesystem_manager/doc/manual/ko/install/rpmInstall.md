<span style="color:#0000BB">RPM 설치</span>
====

### SELinux 설정

vim 등의 편집기를 통해 `/etc/selinux/config` 파일을 아래와 같이 편집한 후 재부팅을 수행합니다.

    ...
    SELINUX=disabled
    ...

### AnyStor-E 저장소 설정 내려 받기

vim 명령을 사용하여 AnyStor-E 저장소 설정 파일을 생성한 후에 패키지 관리자 캐시정보를 초기화합니다.

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

#### AnyStor-E 클러스터 스토리지 관리자 설치

아래 명령을 통하여 AnyStor-E 클러스터 스토리지 관리자를 설치합니다.

    # yum install anystor-e

**이후 작업은 [구성 작업](#install.xhtml#구성 작업)부터 수행합니다.**
