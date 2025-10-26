# Changelog

All notable changes to this project will be documented in this file.

## [Release 0.3.0] - 2025-10-26

### Summary

Major update of underlying components and dependencies. Module functionality
is largely the same, but this release is not backwards compatible.

### Changed

  - Updated to use version 2  of the 1password CLI. This version has a different
    JSON output format which means all existing JMESPath selectors need to be
    updated.

  - Update Bolt compatiblity to 4.0 and newer.

  - Update Puppet compatibility to 7.0 and newer.

  - Update Linux acceptance tests to use Ubuntu 24.04.

  - Update Mac acceptance tests to use macOS 15.

  - Windows acceptance tests have been suspended for now pending further fixes
    to test logic.


## [Release 0.2.0] - 2020-05-06

### Summary

Backwards compatible feature release of the `op_data` module.

### Features

  - Windows is now supported.

  - Acceptance test coverage for Windows, Linux, and macOS.


## [Release 0.1.0] - 2020-05-04

### Summary

Initial release of the `op_data` module.

### Features

  - Bolt inventory plugin that allows data to be retrieved from 1password
    accounts.

  - Support for using JMESPath expressions to select or re-shape 1password data.

[Release 0.3.0]: https://github.com/Sharpie/bolt-op_data/compare/0.2.0...0.3.0
[Release 0.2.0]: https://github.com/Sharpie/bolt-op_data/compare/0.1.0...0.2.0
[Release 0.1.0]: https://github.com/Sharpie/bolt-op_data/compare/8e002cc...0.1.0
