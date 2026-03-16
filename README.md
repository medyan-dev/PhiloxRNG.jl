# PhiloxRNG

[![Build Status](https://github.com/medyan-dev/PhiloxRNG.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/medyan-dev/PhiloxRNG.jl/actions/workflows/CI.yml?query=branch%3Amain)

Stateless random number generation for parallel and GPU workloads. Zero dependencies.

PhiloxRNG.jl implements the [Philox4x32](https://doi.org/10.1145/2063384.2063405) counter-based RNG as pure, inlineable functions with no global state. Each call maps a `(counter, key)` pair directly to random output — making it trivially parallel across threads, tasks, or GPU lanes. Includes built-in uniform and normal distributions.

While the raw integer outputs of `philox4x32_10` are identical on all devices, floating-point distribution outputs may differ slightly due to fast-math approximations.

Ported from the C++ [Random123](https://github.com/DEShawResearch/random123) library.

## Installation

```julia
using Pkg
Pkg.add("PhiloxRNG")
```

## Basic usage

Every function takes three `UInt64` arguments: `(ctr0, ctr1, key)`.

- **`ctr0`, `ctr1`** — a 128-bit counter. Each unique `(ctr0, ctr1)` pair produces independent output.
- **`key`** — a seed. Different keys give independent streams.

```julia
using PhiloxRNG

key = UInt64(42)

# 4 normally distributed Float32 values
randn_f32(UInt64(0), UInt64(0), key)

# 2 normally distributed Float64 values
randn_f64(UInt64(0), UInt64(0), key)

# 4 uniform Float32 values in (0, 1]
randu01_f32(UInt64(0), UInt64(0), key)
```

### Functions

All take `(ctr0::UInt64, ctr1::UInt64, key::UInt64)`:

| Function | Returns |
|---|---|
| `randn_f32` | `NTuple{4, Float32}` — normal |
| `randn_f64` | `NTuple{2, Float64}` — normal |
| `randu01_f32` | `NTuple{4, Float32}` — uniform (0, 1] |
| `randu01_f64` | `NTuple{2, Float64}` — uniform (0, 1] |
| `randuneg11_f32` | `NTuple{4, Float32}` — uniform [-1, 1] |
| `randuneg11_f64` | `NTuple{2, Float64}` — uniform [-1, 1] |
| `philox4x32_10` | `NTuple{4, UInt32}` — raw RNG output |

Lower-level `public` helpers (access via `PhiloxRNG.u01`, etc.):

| Function | Description |
|---|---|
| `u01(F, x::Unsigned)` | Convert unsigned int to `F` in (0, 1] |
| `uneg11(F, x::Unsigned)` | Convert unsigned int to `F` in [-1, 1] |
| `boxmuller(F, u1, u2)` | Box-Muller transform: 2 unsigned ints to 2 normal floats |

## Benchmarks

Julia 1.12.5, AMD Ryzen 7 9800X3D, NVIDIA GeForce RTX 3080.

### CPU (ns/value, N = 100,000,000)

| Function | PhiloxRNG | Random stdlib |
|---|---|---|
| `rand` F32 | 0.791 | 0.522 |
| `rand` F64 | 1.997 | 1.052 |
| `randn` F32 | 1.009 | 2.114 |
| `randn` F64 | 3.098 | 1.795 |

### GPU (ns/value, N = 100,000,000)

| Function | PhiloxRNG | CUDA.jl |
|---|---|---|
| `rand` F32 | 0.006 | 0.006 |
| `randn` F32 | 0.007 | 0.032 |

See `benchmarks/` for the full benchmark scripts.

## When to use PhiloxRNG.jl vs Random123.jl

- **[Random123.jl](https://github.com/JuliaRandom/Random123.jl)** provides an `AbstractRNG` interface for multiple counter-based RNG families (Philox, Threefry, ARS, AESNI). Use it when you need a drop-in replacement for Julia's standard `rand(rng, ...)` API.

- **PhiloxRNG.jl** exposes bare functions with no `AbstractRNG` wrapper, no dependencies, and built-in fast distributions. Use it in GPU kernels or hot loops where the function-call interface is a better fit than a mutable RNG object.

## References

1. Salmon, J. K., Moraes, M. A., Dror, R. O., & Shaw, D. E. (2011). Parallel random numbers. Proceedings of 2011 International Conference for High Performance Computing, Networking, Storage and Analysis, 1–12. https://doi.org/10.1145/2063384.2063405
