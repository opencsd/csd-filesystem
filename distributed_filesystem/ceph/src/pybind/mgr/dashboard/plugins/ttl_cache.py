"""
This is a minimal implementation of TTL-ed lru_cache function.

Based on Python 3 functools and backports.functools_lru_cache.
"""

from collections import OrderedDict
from functools import wraps
from threading import RLock
from time import time

try:
    from typing import Tuple
except ImportError:
    pass  # For typing only


def ttl_cache(ttl, maxsize=128, typed=False):
    if typed is not False:
        raise NotImplementedError("typed caching not supported")

    def decorating_function(function):
        cache = OrderedDict()  # type: OrderedDict[object, Tuple[bool, float]]
        stats = [0, 0, 0]
        rlock = RLock()
        setattr(function, 'cache_info', lambda:
                "hits={}, misses={}, expired={}, maxsize={}, currsize={}".format(
                    stats[0], stats[1], stats[2], maxsize, len(cache)))

        @wraps(function)
        def wrapper(*args, **kwargs):
            key = args + tuple(kwargs.items())
            with rlock:
                refresh = True
                if key in cache:
                    (ret, ts) = cache[key]
                    del cache[key]
                    if time() - ts < ttl:
                        refresh = False
                        stats[0] += 1
                    else:
                        stats[2] += 1

                if refresh:
                    ret = function(*args, **kwargs)
                    ts = time()
                    if len(cache) == maxsize:
                        cache.popitem(last=False)
                    stats[1] += 1

                cache[key] = (ret, ts)

            return ret

        return wrapper
    return decorating_function
