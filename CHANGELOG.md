# Release Notes

All notable changes to this package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## Unreleased

## [v1.1.1](https://github.com/medyan-dev/PhiloxRNG.jl/tree/v1.1.1) - 2026-04-21

- Float64 randn is now much faster on CUDA.jl [#4](https://github.com/medyan-dev/PhiloxRNG.jl/pull/4)

## [v1.1.0](https://github.com/medyan-dev/PhiloxRNG.jl/tree/v1.1.0) - 2026-03-20

- `boxmuller` now has full support for `UInt64` to `Float32` [#2](https://github.com/medyan-dev/PhiloxRNG.jl/pull/2)
- All random functions have clean `infer_effects` [#1](https://github.com/medyan-dev/PhiloxRNG.jl/pull/1)

## [v1.0.0](https://github.com/medyan-dev/PhiloxRNG.jl/tree/v1.0.0) - 2026-03-16

### Added

- Initial release