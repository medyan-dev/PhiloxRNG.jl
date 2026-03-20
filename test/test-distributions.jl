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

    # cross-type: Float32 output from UInt64 input
    g32_64 = boxmuller(Float32, UInt64(12345), UInt64(67890))
    @test length(g32_64) == 2
    @test all(isfinite, g32_64)
    @test eltype(g32_64) == Float32

    # cross-type: Float64 output from UInt32 input
    g64_32 = boxmuller(Float64, UInt32(12345), UInt32(67890))
    @test length(g64_32) == 2
    @test all(isfinite, g64_32)
    @test eltype(g64_32) == Float64

end

# All 16 edge-case combinations: F ∈ {Float32,Float64}, T ∈ {UInt32,UInt64}, u1 ∈ {min,max}, u2 ∈ {min,max}
# u1=min → oct=0, y≈0: small-angle sin(πy) ≈ πy, cos(πy) ≈ 1
# u1=max → oct=7, y≈¼: sin=cos=1/√2, both negated by octant
# u2=min → x = 2^-(N+1), r = √(2(N+1)ln2)
# u2=max → small-angle log(1-ε) ≈ -ε where ε=2^-(N+1), r ≈ 2^(-N/2)
@testset "boxmuller edge cases" begin
    for F in (Float32, Float64), T in (UInt32, UInt64)
        N = 8 * sizeof(T)
        r_lo = sqrt(F(2) * (N + 1) * log(F(2)))
        r_hi = F(2) ^ (-N ÷ 2)
        s_small = F(π) * F(2) ^ (-N)
        invsqrt2 = F(inv(sqrt(2)))

        # u1=min, u2=min: (r_lo · πy, r_lo · 1)
        g = boxmuller(F, typemin(T), typemin(T))
        @test g[1] ≈ r_lo * s_small
        @test g[2] ≈ r_lo

        # u1=min, u2=max: (r_hi · πy, r_hi · 1)
        g = boxmuller(F, typemin(T), typemax(T))
        @test g[1] ≈ r_hi * s_small
        @test g[2] ≈ r_hi

        # u1=max, u2=min: (-r_lo/√2, -r_lo/√2)
        g = boxmuller(F, typemax(T), typemin(T))
        @test g[1] ≈ -r_lo * invsqrt2
        @test g[2] ≈ -r_lo * invsqrt2

        # u1=max, u2=max: (-r_hi/√2, -r_hi/√2)
        g = boxmuller(F, typemax(T), typemax(T))
        @test g[1] ≈ -r_hi * invsqrt2
        @test g[2] ≈ -r_hi * invsqrt2
    end
end
