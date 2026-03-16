using Test
using LinearAlgebra
using PhiloxRNG
using Statistics
using HypothesisTests
using Distributions
using Aqua: Aqua

Aqua.test_all(PhiloxRNG)

include("test-philox.jl")
include("test-distributions.jl")

"""
Function for jittering data to remove ties so KS test can be used
"""
function jitter(a::Array)
    for i in setdiff(collect(eachindex(a)), unique(i -> a[i], eachindex(a)))
        a[i] = nextfloat(a[i])
    end
    return a
end

@testset "Statistical distribution tests" begin
    nsamples = 10_000_000
    key = UInt64(42)
    ctr1 = UInt64(7)

    @testset "randu01_f32" begin
        samples = Float32[]
        for i in UInt64(1):UInt64(nsamples)
            append!(samples, collect(PhiloxRNG.randu01_f32(i, ctr1, key)))
        end
        println("randu01_f32")
        @show ks = ExactOneSampleKSTest(jitter(samples), Uniform(0.0, 1.0))
        @test pvalue(ks) > 0.01
    end

    @testset "randu01_f64" begin
        samples = Float64[]
        for i in UInt64(1):UInt64(nsamples)
            append!(samples, collect(PhiloxRNG.randu01_f64(i, ctr1, key)))
        end
        println("randu01_f64")
        @show ks = ExactOneSampleKSTest(samples, Uniform(0.0, 1.0))
        @test pvalue(ks) > 0.01
    end

    @testset "randuneg11_f32" begin
        samples = Float32[]
        for i in UInt64(1):UInt64(nsamples)
            append!(samples, collect(PhiloxRNG.randuneg11_f32(i, ctr1, key)))
        end
        println("randuneg11_f32")
        @show ks = ExactOneSampleKSTest(jitter(samples), Uniform(-1.0, 1.0))
        @test pvalue(ks) > 0.01
    end

    @testset "randuneg11_f64" begin
        samples = Float64[]
        for i in UInt64(1):UInt64(nsamples)
            append!(samples, collect(PhiloxRNG.randuneg11_f64(i, ctr1, key)))
        end
        println("randuneg11_f64")
        @show ks = ExactOneSampleKSTest(samples, Uniform(-1.0, 1.0))
        @test pvalue(ks) > 0.01
    end

    @testset "randn_f32" begin
        samples = Float32[]
        for i in UInt64(1):UInt64(nsamples)
            append!(samples, collect(PhiloxRNG.randn_f32(i, ctr1, key)))
        end
        println("randn_f32")
        @show ks = ExactOneSampleKSTest(jitter(samples), Normal(0.0, 1.0))
        @test pvalue(ks) > 0.01
    end

    @testset "randn_f64" begin
        samples = Float64[]
        for i in UInt64(1):UInt64(nsamples)
            append!(samples, collect(PhiloxRNG.randn_f64(i, ctr1, key)))
        end
        println("randn_f64")
        @show ks = ExactOneSampleKSTest(samples, Normal(0.0, 1.0))
        @test pvalue(ks) > 0.01
    end
end
