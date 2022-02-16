# Buliding AnyStor-E Package

## Architecture

```
    export ac2/GMS, ac2/GWM with tagging
    packaging
```

## How to use

test with CentOS 6, 7

1. `git clone git@gitlab.gluesys.com:ac2/build`
2. `cd build
3. `./rpm_packaging.sh --gms-repo ac2/GMS --gms-branch <COMMIT|BRANCH|TAG>`

```
[root@localhost ~]# ./gms/build/rpm_packaging.sh --gms-repo ac2/GMS --gms-branch master

[Fri Mar 30 17:07:24 KST 2018] Starting to package AnyStor-E

GMS
  - REPO   : potatogim/GMS
  - BRANCH : centos7
  - SRC    : /root/AnyStor-E/build/gms
  - LOCAL  : 0

OPTIONS
  - WITH_PP : 0

[Fri Mar 30 17:07:24 KST 2018] Exporting potatogim/GMS with centos7...
[Fri Mar 30 17:07:29 KST 2018] Exporting packages to be compiled...
[Fri Mar 30 17:07:38 KST 2018] Write rpm spec
[Fri Mar 30 17:07:40 KST 2018] Make rpm installer

...

=======================================================
  Results
      - GMS    : 3.0.0
      - OUTPUT : /root/AnyStor-E

  Fri Mar 30 17:07:24 KST 2018 - Fri Mar 30 17:08:07 KST 2018
=======================================================

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

Complete.

```

## Copyright

Copyright 2015-2021. [Gluesys Co., Ltd.](http://www.gluesys.com/) All rights reserved.
