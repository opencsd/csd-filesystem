Zabbix Module
=============

The Zabbix module actively sends information to a Zabbix server like:

- Ceph status
- I/O operations
- I/O bandwidth
- OSD status
- Storage utilization

Requirements
------------

The module requires that the *zabbix_sender* executable is present on *all*
machines running ceph-mgr. It can be installed on most distributions using
the package manager.

Dependencies
^^^^^^^^^^^^
Installing zabbix_sender can be done under Ubuntu or CentOS using either apt
or dnf.

On Ubuntu Xenial:

::

    apt install zabbix-agent

On Fedora:

::

    dnf install zabbix-sender


Enabling
--------
You can enable the *zabbix* module with:

::

    ceph mgr module enable zabbix

Configuration
-------------

Two configuration keys are vital for the module to work:

- zabbix_host
- identifier (optional)

The parameter *zabbix_host* controls the hostname of the Zabbix server to which
*zabbix_sender* will send the items. This can be a IP-Address if required by
your installation.

The *identifier* parameter controls the identifier/hostname to use as source
when sending items to Zabbix. This should match the name of the *Host* in
your Zabbix server.

When the *identifier* parameter is not configured the ceph-<fsid> of the cluster
will be used when sending data to Zabbix.

This would for example be *ceph-c4d32a99-9e80-490f-bd3a-1d22d8a7d354*

Additional configuration keys which can be configured and their default values:

- zabbix_port: 10051
- zabbix_sender: /usr/bin/zabbix_sender
- interval: 60
- discovery_interval: 100

Configuration keys
^^^^^^^^^^^^^^^^^^^

Configuration keys can be set on any machine with the proper cephx credentials,
these are usually Monitors where the *client.admin* key is present.

::

    ceph zabbix config-set <key> <value>

For example:

::

    ceph zabbix config-set zabbix_host zabbix.localdomain
    ceph zabbix config-set identifier ceph.eu-ams02.local

The current configuration of the module can also be shown:

::

   ceph zabbix config-show


Template
^^^^^^^^
A `template <https://raw.githubusercontent.com/ceph/ceph/master/src/pybind/mgr/zabbix/zabbix_template.xml>`_. 
(XML) to be used on the Zabbix server can be found in the source directory of the module.

This template contains all items and a few triggers. You can customize the triggers afterwards to fit your needs.


Multiple Zabbix servers
^^^^^^^^^^^^^^^^^^^^^^^
It is possible to instruct zabbix module to send data to multiple Zabbix servers.

Parameter *zabbix_host* can be set with multiple hostnames separated by commas.
Hostnames (or IP addresses) can be followed by colon and port number. If a port
number is not present module will use the port number defined in *zabbix_port*.

For example:

::

    ceph zabbix config-set zabbix_host "zabbix1,zabbix2:2222,zabbix3:3333"


Manually sending data
---------------------
If needed the module can be asked to send data immediately instead of waiting for
the interval.

This can be done with this command:

::

    ceph zabbix send

The module will now send its latest data to the Zabbix server.

Items discovery is accomplished also via zabbix_sender, and runs every `discovery_interval * interval` seconds. If you wish to launch discovery 
manually, this can be done with this command:

::

    ceph zabbix discovery


Debugging
---------

Should you want to debug the Zabbix module increase the logging level for
ceph-mgr and check the logs.

::

    [mgr]
        debug mgr = 20

With logging set to debug for the manager the module will print various logging
lines prefixed with *mgr[zabbix]* for easy filtering.
