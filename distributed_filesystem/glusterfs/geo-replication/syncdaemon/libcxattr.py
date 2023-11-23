#
# Copyright (c) 2011-2014 Red Hat, Inc. <http://www.redhat.com>
# This file is part of GlusterFS.

# This file is licensed to you under your choice of the GNU Lesser
# General Public License, version 3 or any later version (LGPLv3 or
# later), or the GNU General Public License, version 2 (GPLv2), in all
# cases as published by the Free Software Foundation.
#

import os
from ctypes import CDLL, get_errno
from py2py3 import (bytearray_to_str, gr_create_string_buffer,
                    gr_query_xattr, gr_lsetxattr, gr_lremovexattr)


class Xattr(object):

    """singleton that wraps the extended attributes system
       interface for python using ctypes

       Just implement it to the degree we need it, in particular
       - we need just the l*xattr variants, ie. we never want symlinks to be
         followed
       - don't need size discovery for getxattr, as we always know the exact
         sizes we expect
    """

    libc = CDLL("libc.so.6", use_errno=True)

    @classmethod
    def geterrno(cls):
        return get_errno()

    @classmethod
    def raise_oserr(cls):
        errn = cls.geterrno()
        raise OSError(errn, os.strerror(errn))

    @classmethod
    def _query_xattr(cls, path, siz, syscall, *a):
        if siz:
            buf = gr_create_string_buffer(siz)
        else:
            buf = None
        ret = getattr(cls.libc, syscall)(*((path,) + a + (buf, siz)))
        if ret == -1:
            cls.raise_oserr()
        if siz:
            # py2 and py3 compatibility. Convert bytes array
            # to string
            result = bytearray_to_str(buf.raw)
            return result[:ret]
        else:
            return ret

    @classmethod
    def lgetxattr(cls, path, attr, siz=0):
        return gr_query_xattr(cls, path, siz, 'lgetxattr', attr)

    @classmethod
    def lgetxattr_buf(cls, path, attr):
        """lgetxattr variant with size discovery"""
        size = cls.lgetxattr(path, attr)
        if size == -1:
            cls.raise_oserr()
        if size == 0:
            return ''
        return cls.lgetxattr(path, attr, size)

    @classmethod
    def llistxattr(cls, path, siz=0):
        ret = gr_query_xattr(cls, path, siz, 'llistxattr')
        if isinstance(ret, str):
            ret = ret.strip('\0')
            ret = ret.split('\0') if ret else []
        return ret

    @classmethod
    def lsetxattr(cls, path, attr, val):
        ret = gr_lsetxattr(cls, path, attr, val)
        if ret == -1:
            cls.raise_oserr()

    @classmethod
    def lremovexattr(cls, path, attr):
        ret = gr_lremovexattr(cls, path, attr)
        if ret == -1:
            cls.raise_oserr()

    @classmethod
    def llistxattr_buf(cls, path):
        """listxattr variant with size discovery"""
        try:
            # Assuming no more than 100 xattrs in a file/directory and
            # each xattr key length will be less than 256 bytes
            # llistxattr will be called with bigger size so that
            # listxattr will not fail with ERANGE. OSError will be
            # raised if fails even with the large size specified.
            size = 256 * 100
            return cls.llistxattr(path, size)
        except OSError:
            # If fixed length failed for getting list of xattrs then
            # use the llistxattr call to get the size and use that
            # size to get the list of xattrs.
            size = cls.llistxattr(path)
            if size == -1:
                cls.raise_oserr()
            if size == 0:
                return []

            return cls.llistxattr(path, size)
