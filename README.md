<!--
This file is part of the doubledog-sigul Puppet module.
Copyright 2018 John Florian <jflorian@doubledog.org>
SPDX-License-Identifier: GPL-3.0-or-later
-->

# sigul

#### Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with sigul](#setup)
    * [What sigul affects](#what-sigul-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with sigul](#beginning-with-sigul)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Classes](#classes)
    * [Defined types](#defined-types)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This module lets you manage Sigul for its Bridge and Server as well as its Clients.

## Setup

### What sigul Affects

### Setup Requirements

### Beginning with sigul

## Usage

## Reference

**Classes:**

* [sigul](#sigul-class)
* [sigul::bridge](#sigulbridge-class)
* [sigul::client](#sigulclient-class)
* [sigul::server](#sigulserver-class)

**Defined types:**

* [sigul::client::config](#sigulclientconfig-defined-type)


### Classes

#### sigul class

This class manages resources common to all usages of Sigul be it Client, Bridge or
Server.

##### `logrotate_kludge`
If neither the Server nor Bridge reopen their log files after logrotate truncates them (and thus they stop receiving log messages), this option may be set to `true` to make logrotate use its `copytruncate` option as a means for working around the problem.  The default is `false`, except for platforms known to have issues.


#### sigul::bridge class

This class manages a host as a Sigul Bridge to relay requests between Sigul Clients and the Sigul Server.

##### `bridge_cert_nickname` (required)
This must be the nickname given to the Sigul Bridge's certificate within the NSS certificate database.  The named certificate is used to authenticate the Sigul Bridge to the Sigul Server.

##### `client_ca_cert` (required)
Puppet source URI providing the CA certificate which signed `sigul_cert`.  This must be in PEM format and include all intermediate CA certificates, sorted and concatenated from the leaf CA to the root CA.  This certificate is used to authenticate the Sigul Bridge to the Koji Hub.

##### `downloads` (required)
URL of your Koji package download site.

##### `hub` (required)
URL of your Koji Hub service.

##### `hub_ca_cert` (required)
Puppet source URI providing the CA certificate which signed the Koji Hub certificate.  This must be in PEM format and include all intermediate CA certificates, sorted and concatenated from the leaf CA to the root CA.

##### `nss_password` (required)
Password used to protect the NSS certificate database.

##### `packages`
An array of package names needed for the Sigul Bridge installation.  The default should be correct for supported platforms.

##### `sigul_cert` (required)
Puppet source URI providing the Sigul Bridge's identity certificate which must be in PEM format.  This certificate is used to authenticate the Sigul Bridge to the Koji Hub.

##### `web` (required)
URL of your Koji Web service.

##### `top_dir` (required)
Directory containing Koji's `repos/` directory.

##### `client_listen_port`
TCP port number on which the Sigul Bridge expects Sigul Client connections.  The default is `44334`.

##### `enable`
Instance is to be started at boot.  Either `true` (default) or `false`.

##### `ensure`
Instance is to be `running` (default) or `stopped`.  Alternatively, a Boolean value may also be used with `true` equivalent to `running` and `false` equivalent to `stopped`.

##### `koji_dir`
Directory that is to contain the Koji integration files: configuration, certificates, keys, etc.  Defaults to `/var/lib/sigul/.koji`.

##### `max_rpms_payload_size`
Maximum accepted total size of all RPM payloads stored on disk for one request.  The default is `10737418240` (10 GiB).

##### `nss_min_tls`, `nss_max_tls`
Minimum and maximum versions of TLS used.  The default is `tls1.2` for both.

##### `server_listen_port`
TCP port number on which the Sigul Bridge expects Sigul Server connections.  The default is `44333`.

##### `service`
The service name of the Sigul Bridge.


#### sigul::client class

This class manages a host as a Sigul Client to make request of the Sigul Server.

##### `configs`
A hash whose keys are Client configuration resource names and whose values are hashes comprising the same parameters you would otherwise pass to the [sigul::client::config](#sigulclientconfig-defined-type) defined type.  The default is none.

##### `packages`
An array of package names needed for the Sigul Client installation.  The default should be correct for supported platforms.


#### sigul::server class

This class manages a host as a Sigul Server.

For security reasons the Sigul Server should be highly isolated and not accept incoming network connections.  Its sole mode of communication should be with the Sigul Bridge via connections that the Sigul Server itself establishes.

##### `bridge_hostname` (required)
The hostname of your Sigul Bridge that will relay requests to this Sigul Server.

##### `gpg_kludge` (required)
This must be set to `true` on hosts where gpg defaults to gpg2 until such time that Sigul can work acceptably with gpg2.  For more details, see:
    https://bugzilla.redhat.com/show_bug.cgi?id=1329747

##### `nss_password` (required)
Password used to protect the NSS certificate database.

##### `packages`
An array of package names needed for the Sigul Server installation.  The default should be correct for supported platforms.

##### `server_cert_nickname` (required)
This must be the nickname given to the Sigul Server's certificate within the NSS certificate database.  The named certificate is used to authenticate the Sigul Server to the Sigul Bridge.

##### `database_path`
Filesystem path to the server's SQLite database.  Defaults to `/var/lib/sigul/server.sqlite`.

##### `enable`
Instance is to be started at boot.  Either `true` (default) or `false`.

##### `ensure`
Instance is to be `running` (default) or `stopped`.  Alternatively, a Boolean value may also be used with `true` equivalent to `running` and `false` equivalent to `stopped`.

##### `gpg_kludge_packages`
An array of package names needed for the kludging the Sigul installation to work around issues with GPGME.  This is only used if `gpg_kludge` is `true`.

##### `service`
The service name of the Sigul Server.


### Defined types

#### sigul::client::config defined type

This defined type manages a Sigul Client's configuration file.

##### `namevar` (required)
An arbitrary identifier for the client configuration instance unless the `filename` parameter is not set in which case this must provide the value normally set with the `filename` parameter.

##### `bridge_hostname` (required)
The hostname of your Sigul Bridge that will relay requests for this client.

##### `server_hostname` (required)
The hostname of your Sigul Server that will process requests for this client.

##### `ensure`
Instance is to be `present` (default) or `absent`.

##### `client_cert_nickname`
This must be the nickname given to the Sigul Client's certificate within their NSS certificate database.  The named certificate is used to authenticate this Sigul Client to the Sigul Bridge.  The default is `sigul-client-cert`.

##### `owner`
User name or UID to own the configuration file.

##### `group`
Group name or GID to which the configuration file belongs.

##### `mode`
File mode for the configuration file.

##### `filename`
This may be used in place of `namevar` if it's beneficial to give namevar an arbitrary value.  This should specify the absolute filesystem path to the configuration file.

##### `nss_password`
Password for the client's NSS certificate database.  The default is to prompt the client at run-time for this password.


## Limitations

Tested on modern Fedora and CentOS releases, but likely to work on any Red Hat variant.  Adaptations for other operating systems should be trivial as this module follows the data-in-module paradigm.  See `data/common.yaml` for the most likely obstructions.  If "one size can't fit all", the value should be moved from `data/common.yaml` to `data/os/%{facts.os.name}.yaml` instead.  See `hiera.yaml` for how this is handled.

This should be compatible with Puppet 3.x and is being used with Puppet 4.x as well.

## Development

Contributions are welcome via pull requests.  All code should generally be compliant with puppet-lint.
