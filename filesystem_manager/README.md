# GMS

[![pipeline status](https://gitlab.gluesys.com/ac2/GMS/badges/master/pipeline.svg)](https://gitlab.gluesys.com/ac2/GMS/-/commits/master)
[![coverage report](https://gitlab.gluesys.com/ac2/GMS/badges/master/coverage.svg)](https://gitlab.gluesys.com/ac2/GMS/-/commits/master)

GMS helps you make and manage your storage system.

## Features

* All-in-one web management UI for multiple storage cluster nodes.
* NAS features based on file-level protocols such things.
    * FTP
    * SFTP
    * NFS v3/v4/v4.1
    * SMB
    * AFP
* SAN features based on block-level protocols such things.
    * iSCSI (TBD)
    * FCoE (TBD)
    * NVMeoF (TBD)

## Installation

### Operating System Support

We currently support below distros.

* [AnyStor](https://anystor.github.io)
* RHEL
* CentOS

### Perl Support

The API is only certified to run against above Perl 5.18.

### Setup

* `perl Makefile.PL`
* `make test`
* `make install`

### Configuration

## Documents

* [GMS Architecture Design(prototype)](http://redmine.gluesys.com/redmine/boards/170/topics/2005)
* [Developer Note](http://redmine.gluesys.com/redmine/projects/anycloud/wiki/AC2_%EA%B0%9C%EB%B0%9C%EC%9E%90_%EB%85%B8%ED%8A%B8)

## License

Copyright 2015-2021. [Gluesys Co., Ltd.](http://www.gluesys.com/) All rights reserved.
