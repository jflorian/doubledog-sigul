<!--
This file is part of the doubledog-sigul Puppet module.
Copyright 2018-2021 John Florian
SPDX-License-Identifier: GPL-3.0-or-later

Template

## [VERSION] WIP
### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security

-->

# Change log

All notable changes to this project (since v1.1.0) will be documented in this file.  The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [3.0.0] WIP
### Added
- new `sigul::server` parameters:
    - `sigul::server::bridge_port`
    - `sigul::server::max_file_payload_size`
    - `sigul::server::max_memory_payload_size`
    - `sigul::server::max_rpms_payload_size`
    - `sigul::server::signing_timeout`
    - `sigul::server::lenient_username_check`
    - `sigul::server::proxy_usernames`
    - `sigul::server::gnupg_home`
    - `sigul::server::gnupg_key_type`
- dependency on `puppetlabs/stdlib`
### Changed
- `sigul::server::packages` now includes `python3-cryptography`
- enforce absolute paths for these parameters:
    - `sigul::bridge::home_dir`
    - `sigul::bridge::koji_dir`
    - `sigul::bridge::top_dir`
    - `sigul::client::config::filename`
    - `sigul::server::database_path`
- Boolean values no longer accepted for these parameters:
    - `sigul::bridge::ensure`
    - `sigul::server::ensure`
- enforce URL format for these parameters:
    - `sigul::bridge::downloads`
    - `sigul::bridge::hub`
    - `sigul::bridge::web`
- enforce hostname/IP address format for these parameters:
    - `sigul::client::config::bridge_hostname`
    - `sigul::client::config::server_hostname`
    - `sigul::server::bridge_hostname`
### Deprecated
### Removed
- kludge support where gpg1 was required for older Sigul builds
- `sigul::server::gpg_kludge` and `sigul::server::gpg_kludge_packages` parameters
### Fixed
- CentOS 8 support for `sigul::bridge` and `sigul::server`
- don't allow negative values for `sigul::bridge::max_rpms_payload_size`
### Security

## [2.2.0] 2019-12-28
### Added
- Fedora 31 support
### Changed
- expect CentOS packaging to provide sigul-0.207 or newer
### Removed
- special Fedora support requiring `python2-koji` package on the Bridge (rpm deps are again responsible)
- Fedora 28 support

## [2.1.0] 2019-10-21
### Added
- Fedora 30 support
- CentOS 8 support
### Changed
- dependency on `puppetlabs/firewall` now allows version 2

## [2.0.1] 2019-02-13
### Fixed
- `sigul::bridge::firewall` still used connection tracking for Client connections.  Evidence suggest that the Server may also act as a Client under one of these long term connections.

## [2.0.0] 2019-01-16
### Added
- `sigul::logrotate_kludge` option to allow enabling/disabling the kludge handling that has been forced in prior versions.
- `sigul::client` class to provision the Client only.
- `sigul::bridge::client_listen_port` parameter.
- `sigul::bridge::server_listen_port` parameter.
- `sigul::bridge::max_rpms_payload_size` parameter.
- `sigul::bridge::nss_min_tls` parameter.
- `sigul::bridge::nss_max_tls` parameter.
- `sigul::bridge::home_dir` parameter.
- `sigul::bridge::x509` class to provision the X.509 certificates.  See more details in the *Changed* section below.
- `sigul::bridge::firewall` class to manage iptables.  See more details in the *Changed* section below.
### Changed
- Fedora support to account for packaging split.
- `sigul::client_config` defined type has been renamed to `sigul::client::config`.
- TLS X.509 certificate management is now optional.  If desired, `include sigul::bridge::x509`.
    - Several related parameters have moved from `sigul::bridge` to `sigul::bridge::x509` and have been renamed:
        - `client_ca_cert` is now `client_ca_cert_source`
        - `hub_ca_cert` is now `hub_ca_cert_source`
        - `sigul_cert` is now `client_cert_source`
    - The following are simply new:
        - `client_ca_cert_content`
        - `client_cert_content`
        - `hub_ca_cert_content`
- iptables firewall management is now:
    - optional.  If desired, `include sigul::bridge::firewall`.
    - If used, connection tracking is no longer used for the Bridge accepting Server connections rule to avoid hung communications due to long inactivity periods that caused the state tracking to be evicted by the kernel.
### Fixed
- Fedora support requires `python2-koji` package on the Bridge.
- Several readability issues with the `README.md` and its formatting.
- Missing dependency on `puppetlabs-firewall` in `metadata.json`.

## [1.1.0 and prior] 2018-12-15

This and prior releases predate this project's keeping of a formal CHANGELOG.  If you are truly curious, see the Git history.
