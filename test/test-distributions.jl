using Test
using PhiloxRNG: u01, randu01_f32, randu01_f64,
    uneg11, randuneg11_f32, randuneg11_f64,
    boxmuller, randn_f32, randn_f64

@testset "u01 edge cases" begin
    # UInt32 boundaries
    @test u01(Float32, 0x00000000) === Float32(2)^(-33)
    @test u01(Float32, 0x7fffffff) === 0.5f0
    @test u01(Float32, 0x80000000) === 0.5f0
    @test u01(Float32, 0xffffffff) === 1.0f0

    @test u01(Float64, 0x00000000) === Float64(2)^(-33)
    @test u01(Float64, 0x7fffffff) < 0.5
    @test u01(Float64, 0x80000000) > 0.5
    @test u01(Float64, 0xffffffff) < 1.0
    @test u01(Float64, 0xffffffff) > 0.999999999

    # UInt64 boundaries
    @test u01(Float32, UInt64(0)) === Float32(2)^(-65)
    @test u01(Float32, typemax(UInt64) ÷ 2) === 0.5f0
    @test u01(Float32, typemax(UInt64) ÷ 2 + 1) === 0.5f0
    @test u01(Float32, typemax(UInt64)) === 1.0f0

    @test u01(Float64, UInt64(0)) === Float64(2)^(-65)
    @test u01(Float64, typemax(UInt64) ÷ 2) === 0.5
    @test u01(Float64, typemax(UInt64) ÷ 2 + 1) === 0.5
    @test u01(Float64, typemax(UInt64)) === 1.0

    ctr0 = UInt64(1234)
    ctr1 = UInt64(5678)
    key = UInt64(91011)
    @test randu01_f32(ctr0, ctr1, key) isa NTuple{4, Float32}
    @test randu01_f64(ctr0, ctr1, key) isa NTuple{2, Float64}
end

@testset "uneg11 edge cases" begin
    # UInt32 boundaries
    @test uneg11(Float32, 0x00000000) === Float32(2)^(-32)
    @test uneg11(Float32, 0x7fffffff) === 1.0f0
    @test uneg11(Float32, 0x80000000) === -1.0f0
    @test uneg11(Float32, 0xffffffff) === -Float32(2)^(-32)

    @test uneg11(Float64, 0x00000000) === Float64(2)^(-32)
    @test uneg11(Float64, 0x7fffffff) < 1.0
    @test uneg11(Float64, 0x7fffffff) > 0.999999999
    @test uneg11(Float64, 0x80000000) > -1.0
    @test uneg11(Float64, 0x80000000) < -0.999999999
    @test uneg11(Float64, 0xffffffff) === -Float64(2)^(-32)

    # UInt64 boundaries
    @test uneg11(Float32, UInt64(0)) === Float32(2)^(-64)
    @test uneg11(Float32, typemax(UInt64) ÷ 2) === 1.0f0
    @test uneg11(Float32, typemax(UInt64) ÷ 2 + 1) === -1.0f0
    @test uneg11(Float32, typemax(UInt64)) === -Float32(2)^(-64)

    @test uneg11(Float64, UInt64(0)) === Float64(2)^(-64)
    @test uneg11(Float64, typemax(UInt64) ÷ 2) === 1.0
    @test uneg11(Float64, typemax(UInt64) ÷ 2 + 1) === -1.0
    @test uneg11(Float64, typemax(UInt64)) === -Float64(2)^(-64)

    ctr0 = UInt64(1234)
    ctr1 = UInt64(5678)
    key = UInt64(91011)
    @test randuneg11_f32(ctr0, ctr1, key) isa NTuple{4, Float32}
    @test randuneg11_f64(ctr0, ctr1, key) isa NTuple{2, Float64}
end

@testset "boxmuller basic properties" begin
    # output should be a tuple of two floats
    g = boxmuller(Float32, UInt32(12345), UInt32(67890))
    @test length(g) == 2
    @test all(isfinite, g)

    g64 = boxmuller(Float64, UInt64(12345), UInt64(67890))
    @test length(g64) == 2
    @test all(isfinite, g64)
end
