<!--
# This file is part of the doubledog-sigul Puppet module.
# Copyright 2018-2019 John Florian
# SPDX-License-Identifier: GPL-3.0-or-later

Template

## [VERSION] DATE/WIP
### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security

-->

# Change log

All notable changes to this project (since v1.1.0) will be documented in this file.  The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [2.0.0] WIP
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
### Deprecated
### Removed
### Fixed
- Fedora support requires `python2-koji` package on the Bridge.
- Several readability issues with the `README.md` and its formatting.
- Missing dependency on `puppetlabs-firewall` in `metadata.json`.
### Security

## [1.1.0 and prior] 2018-12-15

This and prior releases predate this project's keeping of a formal CHANGELOG.  If you are truly curious, see the Git history.
