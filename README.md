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

**Defined types:**


### Classes

#### sigul class

This class manages resources common to all usages of Sigul be it Client, Bridge or
Server.

##### `packages`
An array of package names needed for the Sigul installation.  The default should be correct for supported platforms.


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

##### `sigul_cert` (required)
Puppet source URI providing the Sigul Bridge's identity certificate which must be in PEM format.  This certificate is used to authenticate the Sigul Bridge to the Koji Hub.

##### `web` (required)
URL of your Koji Web service.

##### `top_dir` (required)
Directory containing Koji's `repos/` directory.

##### `enable`
Instance is to be started at boot.  Either `true` (default) or `false`.

##### `ensure`
Instance is to be `running` (default) or `stopped`.  Alternatively, a Boolean value may also be used with `true` equivalent to `running` and `false` equivalent to `stopped`.

##### `koji_dir`
Directory that is to contain the Koji integration files: configuration, certificates, keys, etc.  Defaults to `/var/lib/sigul/.koji`.

##### `service`
The service name of the Sigul Bridge.


### Defined types


## Limitations

Tested on modern Fedora and CentOS releases, but likely to work on any Red Hat variant.  Adaptations for other operating systems should be trivial as this module follows the data-in-module paradigm.  See `data/common.yaml` for the most likely obstructions.  If "one size can't fit all", the value should be moved from `data/common.yaml` to `data/os/%{facts.os.name}.yaml` instead.  See `hiera.yaml` for how this is handled.

This should be compatible with Puppet 3.x and is being used with Puppet 4.x as well.

## Development

Contributions are welcome via pull requests.  All code should generally be compliant with puppet-lint.
