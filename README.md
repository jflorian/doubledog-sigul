<!--
This file is part of the doubledog-sigul Puppet module.
Copyright 2018-2021 John Florian <jflorian@doubledog.org>
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

This module optionally depends on and leverages several other Puppet modules to achieve a reliable, integrated solution.  At present these are:

* [doubledog-openssl](https://github.com/jflorian/doubledog-openssl)
** Only required when using the `sigul::bridge::x509` class
* [puppetlabs-firewall](https://github.com/puppetlabs/puppetlabs-firewall)
** Only required when using the `sigul::bridge::firewall` class

### Beginning with sigul

## Usage

## Reference

**Classes:**

* [sigul](#sigul-class)
* [sigul::bridge](#sigulbridge-class)
* [sigul::bridge::firewall](#sigulbridgefirewall-class)
* [sigul::bridge::x509](#sigulbridgex509-class)
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

##### `downloads` (required)
URL of your Koji package download site.

##### `hub` (required)
URL of your Koji Hub service.

##### `nss_password` (required)
Password used to protect the NSS certificate database.

##### `packages`
An array of package names needed for the Sigul Bridge installation.  The default should be correct for supported platforms.

##### `web` (required)
URL of your Koji Web service.

##### `top_dir` (required)
Absolute path to the directory containing Koji's `repos/` directory.

##### `client_listen_port`
TCP port number on which the Sigul Bridge expects Sigul Client connections.  The default is `44334`.

##### `enable`
Instance is to be started at boot.  Either `true` (default) or `false`.

##### `ensure`
Instance is to be `'running'` (default) or `'stopped'`.

##### `home_dir`
Absolute path to the home directory of the `sigul` user.  See `getent passwd sigul` on your Bridge.  Defaults to `'/var/lib/sigul'` to match packaging defaults of supported platform.

##### `koji_dir`
Absolute path to the directory that is to contain the Koji integration files: configuration, certificates, keys, etc.  Defaults to `'`*home_dir*`/.koji'`.

##### `max_rpms_payload_size`
Maximum accepted total size of all RPM payloads stored on disk for one request.  The default is `10737418240` (10 GiB).

##### `nss_min_tls`, `nss_max_tls`
Minimum and maximum versions of TLS used.  The default is `'tls1.2'` for both.

##### `server_listen_port`
TCP port number on which the Sigul Bridge expects Sigul Server connections.  The default is `44333`.

##### `service`
The service name of the Sigul Bridge.


#### sigul::bridge::firewall class

This class manages iptables on a host acting as a Sigul Bridge so far as the needs of Sigul itself are concerned.  It's use is optional and should only be included if you wish to use the integrated firewall support offered by the [puppetlabs-firewall](https://github.com/puppetlabs/puppetlabs-firewall) module.


#### sigul::bridge::x509 class

This class manages the X.509 certificates on a host acting as a Sigul Bridge that uses PKI to authenticate itself to a Koji Hub.  It's use is optional and should only be included if you wish to use the integrated X.509 support offered by the
[doubledog-openssl](https://github.com/jflorian/doubledog-openssl) module.

##### `client_ca_cert_content`, `client_ca_cert_source`
Literal string or Puppet source URI providing the CA certificate which signed the certificated provided by *client_cert_content* or *client_cert_source*.  This must be in PEM format and include all intermediate CA certificates, sorted and concatenated from the leaf CA to the root CA.  This certificate is used to authenticate the Sigul Bridge to the Koji Hub.

##### `hub_ca_cert_content`, `hub_ca_cert_source`
Literal string or Puppet source URI providing the CA certificate which signed the Koji Hub certificate.  This must be in PEM format and include all intermediate CA certificates, sorted and concatenated from the leaf CA to the root CA.

##### `client_cert_content`, `client_cert_source`
Literal string or Puppet source URI providing the Sigul Bridge's identity certificate which must be in PEM format.  This certificate is used to authenticate the Sigul Bridge to the Koji Hub.


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

##### `bridge_port`
TCP port number on the Sigul Bridge to which the Sigul Server is to connect.  The default is `44333`.

##### `gnupg_home`
Absolute path to directory containing GPG configuration and key rings.  Defaults to `/var/lib/sigul/gnupg`.

##### `gnupg_key_type`
Primary key type for newly created keys.  Defaults to `DSA`.

##### `lenient_username_check`
Whether to relax the Common Name (CN) versus user name check.  Either `true` or `false` (default).

##### `max_file_payload_size`
Maximum accepted size of payload stored on disk for one request.  The default is `1073741824` (1 GiB).

##### `max_memory_payload_size`
Maximum accepted size of payload stored in the Sigul Servers memory for one request.  The default is `1048576` (1 MiB).

##### `max_rpms_payload_size`
Maximum accepted total size of all RPM payloads stored on disk for one request.  The default is `10737418240` (10 GiB).

##### `nss_password` (required)
Password used to protect the NSS certificate database.

##### `packages`
An array of package names needed for the Sigul Server installation.  The default should be correct for supported platforms.

##### `proxy_usernames`
An array of Common Names (CNs) which are allowed to use different user names.  The default is `null` (none).

##### `server_cert_nickname` (required)
This must be the nickname given to the Sigul Server's certificate within the NSS certificate database.  The named certificate is used to authenticate the Sigul Server to the Sigul Bridge.

##### `signing_timeout`
Maximum number of seconds to wait for signing one package.  The default is `60` (1 minute).

##### `database_path`
Absolute path to the server's SQLite database.  Defaults to `'/var/lib/sigul/server.sqlite'`.

##### `enable`
Instance is to be started at boot.  Either `true` (default) or `false`.

##### `ensure`
Instance is to be `'running'` (default) or `'stopped'`.

##### `service`
The service name of the Sigul Server.


### Defined types

#### sigul::client::config defined type

This defined type manages a Sigul Client's configuration file.

##### `namevar` (required)
An arbitrary identifier for the client configuration instance unless the *filename* parameter is not set in which case this must provide the value normally set with the *filename* parameter.

##### `bridge_hostname` (required)
The hostname of your Sigul Bridge that will relay requests for this client.

##### `server_hostname` (required)
The hostname of your Sigul Server that will process requests for this client.

##### `ensure`
Instance is to be `'present'` (default) or `'absent'`.

##### `client_cert_nickname`
This must be the nickname given to the Sigul Client's certificate within their NSS certificate database.  The named certificate is used to authenticate this Sigul Client to the Sigul Bridge.  The default is `'sigul-client-cert'`.

##### `owner`
User name or UID to own the configuration file.

##### `group`
Group name or GID to which the configuration file belongs.

##### `mode`
File mode for the configuration file.

##### `filename`
This may be used in place of *namevar* if it's beneficial to give namevar an arbitrary value.  This must specify an absolute path to the configuration file.

##### `nss_password`
Password for the client's NSS certificate database.  The default is to prompt the client at run-time for this password.


## Limitations

Tested on modern Fedora and CentOS releases, but likely to work on any Red Hat variant.  Adaptations for other operating systems should be trivial as this module follows the data-in-module paradigm.  See `data/common.yaml` for the most likely obstructions.  If "one size can't fit all", the value should be moved from `data/common.yaml` to `data/os/%{facts.os.name}.yaml` instead.  See `hiera.yaml` for how this is handled.

## Development

Contributions are welcome via pull requests.  All code should generally be compliant with puppet-lint.
