# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.3.0] - 2023-02-03

### Added:
- This changelog, which serves as a replacement to the github releases changelog.
- Ringbuffers and their range interfaces can now be indexed using the `[n]` operator.
- Elements can now be added to the "read" end of the buffer with `unshift`.
- The range interface now implements `save()`, `back()` and `popBack()`, making it a [*bidirectional range*](https://dlang.org/phobos/std_range_primitives.html#isBidirectionalRange).
	- In combination with the indexing mentioned above, this also makes the interface a [*random access range*](https://dlang.org/phobos/std_range_primitives.html#isRandomAccessRange).
- More bounds checking contracts have been added.

### Changed:
- The documentation has been marginally improved to reflect the differences between `push` and the new `unshift`.

### Fixed:
- All functions are now completely tested to work with both reference types and value types.
- Some functions that should have had the `inout` attribute were missing it.

## [2.2.0] - 2022-09-07
### Fixed:
- reference types can now be used, for real this time. this is why you write the unit tests first, folks!
	- contrary to what was stated in the 2.1.0 release notes, using `inout` rather than `in` did *not* make reference types usable; classes were still forced to be `const`.
- the documentation now includes the module as a whole.

## [2.1.0] - 2022-07-21
### Fixed:
- several incorrect `in` attributes have been replaced with `inout`, allowing reference types to be used.

## [2.0.0] - 2022-02-18
### Changed:
- the range interface no longer consumes the buffer; rather, an intermediary representation is used that points back to the original buffer as per convention.
- a buffer may now be used with nonsafe / gc-using / ect. types.

## [1.0.0] - 2022-02-05
- initial release.
