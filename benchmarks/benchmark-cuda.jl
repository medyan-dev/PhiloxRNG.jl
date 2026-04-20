#!/usr/bin/env -S JULIA_LOAD_PATH=@ julia --project=@script --startup-file=no

# CUDA benchmark for PhiloxRNG
# Compares PhiloxRNG GPU kernels against CUDA.jl's built-in cuRAND

using Chairmarks
using CUDA
using PhiloxRNG
using Random: Random
using Statistics

# --- GPU kernels ---

function kernel_randn_f32!(out, ctr1::UInt64, key::UInt64)
    i = (blockIdx().x - Int32(1)) * blockDim().x + threadIdx().x
    stride = gridDim().x * blockDim().x
    len = length(out)
    while 4*i <= len
        ctr0 = UInt64(i)
        a, b, c, d = randn_f32(ctr0, ctr1, key)
        @inbounds out[4*i - 3] = a
        @inbounds out[4*i - 2] = b
        @inbounds out[4*i - 1] = c
        @inbounds out[4*i]     = d
        i += stride
    end
    # Handle remaining 1-3 elements (single thread)
    if threadIdx().x == Int32(1) && blockIdx().x == Int32(1)
        rem = len % 4
        if rem > 0
            base = len - rem
            ctr0 = UInt64(base ÷ 4 + 1)
            a, b, c, d = randn_f32(ctr0, ctr1, key)
            vals = (a, b, c, d)
            for j in 1:rem
                @inbounds out[base + j] = vals[j]
            end
        end
    end
    return nothing
end

function kernel_randn_f64!(out, ctr1::UInt64, key::UInt64)
    i = (blockIdx().x - Int32(1)) * blockDim().x + threadIdx().x
    stride = gridDim().x * blockDim().x
    len = length(out)
    while 2*i <= len
        ctr0 = UInt64(i)
        a, b = randn_f64(ctr0, ctr1, key)
        @inbounds out[2*i - 1] = a
        @inbounds out[2*i]     = b
        i += stride
    end
    # Handle remaining element
    if threadIdx().x == Int32(1) && blockIdx().x == Int32(1)
        if isodd(len)
            ctr0 = UInt64(len ÷ 2 + 1)
            a, _ = randn_f64(ctr0, ctr1, key)
            @inbounds out[len] = a
        end
    end
    return nothing
end

function kernel_randu01_f32!(out, ctr1::UInt64, key::UInt64)
    i = (blockIdx().x - Int32(1)) * blockDim().x + threadIdx().x
    stride = gridDim().x * blockDim().x
    len = length(out)
    while 4*i <= len
        ctr0 = UInt64(i)
        a, b, c, d = randu01_f32(ctr0, ctr1, key)
        @inbounds out[4*i - 3] = a
        @inbounds out[4*i - 2] = b
        @inbounds out[4*i - 1] = c
        @inbounds out[4*i]     = d
        i += stride
    end
    # Handle remaining 1-3 elements (single thread)
    if threadIdx().x == Int32(1) && blockIdx().x == Int32(1)
        rem = len % 4
        if rem > 0
            base = len - rem
            ctr0 = UInt64(base ÷ 4 + 1)
            a, b, c, d = randu01_f32(ctr0, ctr1, key)
            vals = (a, b, c, d)
            for j in 1:rem
                @inbounds out[base + j] = vals[j]
            end
        end
    end
    return nothing
end

function kernel_randu01_f64!(out, ctr1::UInt64, key::UInt64)
    i = (blockIdx().x - Int32(1)) * blockDim().x + threadIdx().x
    stride = gridDim().x * blockDim().x
    len = length(out)
    while 2*i <= len
        ctr0 = UInt64(i)
        a, b = randu01_f64(ctr0, ctr1, key)
        @inbounds out[2*i - 1] = a
        @inbounds out[2*i]     = b
        i += stride
    end
    # Handle remaining element
    if threadIdx().x == Int32(1) && blockIdx().x == Int32(1)
        if isodd(len)
            ctr0 = UInt64(len ÷ 2 + 1)
            a, _ = randu01_f64(ctr0, ctr1, key)
            @inbounds out[len] = a
        end
    end
    return nothing
end

# --- Launch helpers ---

function philox_randn!(out::CuVector{Float32}; ctr1=UInt64(12345), key=rand(UInt64))
    n_calls = cld(length(out), 4)
    threads = 256
    blocks = cld(n_calls, threads)
    @cuda threads=threads blocks=blocks kernel_randn_f32!(out, ctr1, key)
    out
end

function philox_randn!(out::CuVector{Float64}; ctr1=UInt64(12345), key=rand(UInt64))
    n_calls = cld(length(out), 2)
    threads = 256
    blocks = cld(n_calls, threads)
    @cuda threads=threads blocks=blocks kernel_randn_f64!(out, ctr1, key)
    out
end

function philox_randu01!(out::CuVector{Float32}; ctr1=UInt64(12345), key=rand(UInt64))
    n_calls = cld(length(out), 4)
    threads = 256
    blocks = cld(n_calls, threads)
    @cuda threads=threads blocks=blocks kernel_randu01_f32!(out, ctr1, key)
    out
end

function philox_randu01!(out::CuVector{Float64}; ctr1=UInt64(12345), key=rand(UInt64))
    n_calls = cld(length(out), 4)
    threads = 256
    blocks = cld(n_calls, threads)
    @cuda threads=threads blocks=blocks kernel_randu01_f64!(out, ctr1, key)
    out
end

# --- Benchmark helper ---

function bench_fill(f!, ::Type{F}, size) where F
    @be(
        CuVector{F}(undef, size),
        (x) -> CUDA.@sync(f!(x)),
        evals=1,
        seconds=10,
    )
end

function run_benchmarks(; size=100_000_000)
    results = Tuple{String,Float64}[]

    benchmarks = [
        ("Random.rand!     F32", () -> bench_fill(Random.rand!, Float32, size), size),
        ("philox_randu01!  F32", () -> bench_fill(philox_randu01!, Float32, size), size),
        ("Random.randn!    F32", () -> bench_fill(Random.randn!, Float32, size), size),
        ("philox_randn!    F32", () -> bench_fill(philox_randn!, Float32, size), size),
        ("Random.rand!     F64", () -> bench_fill(Random.rand!, Float64, size), size),
        ("philox_randu01!  F64", () -> bench_fill(philox_randu01!, Float64, size), size),
        ("Random.randn!    F64", () -> bench_fill(Random.randn!, Float64, size), size),
        ("philox_randn!    F64", () -> bench_fill(philox_randn!, Float64, size), size),
    ]

    println("GPU: $(CUDA.name(CUDA.device()))")
    println()

    for (name, bench_fn, n_values) in benchmarks
        @info "Benchmarking $name..."
        push!(results, (name, minimum(bench_fn()).time * 1E9 / n_values))
    end

    # Print table
    println()
    println("CUDA Benchmark results (N = $size elements)")
    println("="^60)
    header = lpad("Function", 30) * lpad("ns/value", 14)
    println(header)
    println("-"^60)
    for (name, mintime) in results
        row = lpad(name, 30) * lpad("$(round(mintime, digits=6))", 14)
        println(row)
    end
    println("="^60)
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_benchmarks()
end
