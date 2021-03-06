# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/)
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]
- (nothing to record here)

## [0.1.4] - 2021-05-23
### Fixed
- Fix issue #7: cannot tokenize a string contains any spaces.

## [0.1.3] - 2021-05-15
### Added
- Add `Lexer#skip_token(offset)`

### Changed
- Modify `Lexer#next_token` to accept an argument to specify the
  offset to read position.

### Fixed
- Fix issue #4: Some "peculiar identifiers" are regarded as illegal.

## [0.1.2] - 2021-05-07
### Added
- Add a mechanism to initialize a Parser instance from an array of
  tokens, which already created from source of Scheme.

### Fixed
- Fix issue #3: a wrong link in `README.md`.

## [0.1.1] - 2021-05-06
### Fixed
- Fix issue #1: `rbscmlex` fails to read from STDIN.

## [0.1.0] - 2021-05-06
- Initial release
