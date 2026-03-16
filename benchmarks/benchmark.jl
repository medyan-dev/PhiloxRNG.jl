#!/usr/bin/env -S OPENBLAS_NUM_THREADS=1 JULIA_LOAD_PATH=@ julia --project=@script --threads=1 --startup-file=no

# This script prints a benchmark results table

using Chairmarks
using PhiloxRNG
using PhiloxRNG: boxmuller
using Random
using Statistics

# --- Benchmark functions ---

# Fill a vector with randn using Philox counter-based RNG

function philox_randn!(out::Vector{Float32}, ctr1::UInt64=UInt64(12345), key::UInt64=rand(UInt64))
    l = length(out)
    n = l ÷ 4
    @inbounds @simd ivdep for i in 1:n
        a, b, c, d = randn_f32(UInt64(i), ctr1, key)
        out[4*i - 3] = a
        out[4*i - 2] = b
        out[4*i - 1] = c
        out[4*i]     = d
    end
    # Handle remaining 1-3 elements
    rem = l % 4
    if rem > 0
        a, b, c, d = randn_f32(UInt64(n + 1), ctr1, key)
        vals = (a, b, c, d)
        for j in 1:rem
            @inbounds out[end - rem + j] = vals[j]
        end
    end
    out
end

function philox_randu01!(out::Vector{Float32}, ctr1::UInt64=UInt64(12345), key::UInt64=rand(UInt64))
    l = length(out)
    n = l ÷ 4
    @inbounds @simd ivdep for i in 1:n
        a, b, c, d = randu01_f32(UInt64(i), ctr1, key)
        out[4*i - 3] = a
        out[4*i - 2] = b
        out[4*i - 1] = c
        out[4*i]     = d
    end
    # Handle remaining 1-3 elements
    rem = l % 4
    if rem > 0
        a, b, c, d = randu01_f32(UInt64(n + 1), ctr1, key)
        vals = (a, b, c, d)
        for j in 1:rem
            @inbounds out[end - rem + j] = vals[j]
        end
    end
    out
end

function philox_randn!(out::Vector{Float64}, ctr1::UInt64=UInt64(12345), key::UInt64=rand(UInt64))
    l = length(out)
    n = l ÷ 2
    @inbounds @simd ivdep for i in 1:n
        a, b = randn_f64(UInt64(i), ctr1, key)
        out[2*i - 1] = a
        out[2*i]     = b
    end
    # Handle remaining element
    if isodd(l)
        a, _ = randn_f64(UInt64(n + 1), ctr1, key)
        @inbounds out[end] = a
    end
    out
end

function philox_randu01!(out::Vector{Float64}, ctr1::UInt64=UInt64(12345), key::UInt64=rand(UInt64))
    l = length(out)
    n = l ÷ 2
    @inbounds @simd ivdep for i in 1:n
        a, b = randu01_f64(UInt64(i), ctr1, key)
        out[2*i - 1] = a
        out[2*i]     = b
    end
    # Handle remaining element
    if isodd(l)
        a, _ = randu01_f64(UInt64(n + 1), ctr1, key)
        @inbounds out[end] = a
    end
    out
end

function bench_fill(f!, ::Type{F}, size) where F
    @be(
        Vector{F}(undef, size),
        (x)->f!(x),
        evals=1,
        seconds=10,
    )
end

function run_benchmarks(; size=100_000_000)
    results = Tuple{String,Float64}[]

    # Each entry: (name, type, bench_fn, total_values_produced)
    # All benchmarks fill a vector of `size` elements
    benchmarks = [
        ("Random.rand!    F32", () -> bench_fill(rand!, Float32, size), size),
        ("philox_randu01! F32", () -> bench_fill(philox_randu01!, Float32, size), size),
        ("Random.rand!    F64", () -> bench_fill(rand!, Float64, size), size),
        ("philox_randu01! F64", () -> bench_fill(philox_randu01!, Float64, size), size),
        ("Random.randn!   F32", () -> bench_fill(randn!, Float32, size), size),
        ("philox_randn!   F32", () -> bench_fill(philox_randn!, Float32, size), size),
        ("Random.randn!   F64", () -> bench_fill(randn!, Float64, size), size),
        ("philox_randn!   F64", () -> bench_fill(philox_randn!, Float64, size), size),
    ]

    for (name, bench_fn, n_values) in benchmarks
        @info "Benchmarking $name..."
        push!(results, (name, minimum(bench_fn()).time * 1E9 / n_values))
    end

    # Print table
    println()
    println("Benchmark results (N = $size calls)")
    println("="^60)
    header = lpad("Function", 30) * lpad("ns/value", 14)
    println(header)
    println("-"^60)
    for (name, mintime) in results
        row = lpad(name, 30) * lpad("$(round(mintime, digits=3))", 14)
        println(row)
    end
    println("="^60)
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_benchmarks()
end
