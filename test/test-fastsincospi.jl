using Test
using PhiloxRNG: PhiloxRNG
using MultiFloats: Float64x2

function max_error_u32_2(a,b)
    err::Float64 = 0.0
    i_max::UInt32 = 0
    for i in UInt32(0):typemax(UInt32)
        d = max(abs(a(i)[1] - b(i)[1]), abs(a(i)[2] - b(i)[2]))
        d < err && continue
        err = d
        i_max = i
    end
    err, i_max
end

# Return the mean value over u32
function mean_u32_2(a)
    r1::Float64x2 = 0.0
    r2::Float64x2 = 0.0
    for i in UInt32(0):typemax(UInt32)
        r1 += a(i)[1]
        r2 += a(i)[2]
    end
    r1*Float64x2(2)^-32, r2*Float64x2(2)^-32
end

function sample_max_error_u64_2(a,b)
    err::Float64 = 0.0
    i_max::UInt64 = 0
    u2 = UInt64(2)
    # First, middle and last densely sampled values
    for i in UInt64(0) : u2^32-1
        # if iszero(mod(i, 2^28))
        #     @show i, err
        # end
        d = max(abs(a(i)[1] - b(i)[1]), abs(a(i)[2] - b(i)[2]))
        d < err && continue
        err = d
        i_max = i
    end
    for i in u2^63-u2^32 : u2^63+u2^32
        # if iszero(mod(i, 2^28))
        #     @show i, err
        # end
        d = max(abs(a(i)[1] - b(i)[1]), abs(a(i)[2] - b(i)[2]))
        d < err && continue
        err = d
        i_max = i
    end
    for i in u2^64-u2^32 : u2^64-1
        # if iszero(mod(i, 2^28))
        #     @show i, err
        # end
        d = max(abs(a(i)[1] - b(i)[1]), abs(a(i)[2] - b(i)[2]))
        d < err && continue
        err = d
        i_max = i
    end
    # Now sample every 2^32 through the whole range
    for i in UInt64(0) : u2^32 : u2^64-1
        d = max(abs(a(i)[1] - b(i)[1]), abs(a(i)[2] - b(i)[2]))
        d < err && continue
        err = d
        i_max = i
    end
    err, i_max
end

function ref_sincospi(u::UInt32)
    oct = (u % Int32) & Int32(7)
    y = fma(Float64(u & ~UInt32(7)), Float64(2)^(-34), Float64(2)^(-32))

    sp = sinpi(y)
    cp = cospi(y)

    swap    = (oct & Int32(1)) != Int32(0)
    sin_neg = (oct & Int32(2)) != Int32(0)
    cos_neg = (oct & Int32(4)) != Int32(0)

    s_raw = ifelse(swap, cp, sp)
    c_raw = ifelse(swap, sp, cp)
    sin_val = ifelse(sin_neg, -s_raw, s_raw)
    cos_val = ifelse(cos_neg, -c_raw, c_raw)
    (sin_val, cos_val)
end

function ref_sincospi(u::UInt64)
    oct = (u % Int64) & Int64(7)
    y = fma(Float64(u & ~UInt64(7)), Float64(2)^(-66), Float64(2)^(-64))

    sp = sinpi(y)
    cp = cospi(y)

    swap    = (oct & Int64(1)) != Int64(0)
    sin_neg = (oct & Int64(2)) != Int64(0)
    cos_neg = (oct & Int64(4)) != Int64(0)

    s_raw = ifelse(swap, cp, sp)
    c_raw = ifelse(swap, sp, cp)
    sin_val = ifelse(sin_neg, -s_raw, s_raw)
    cos_val = ifelse(cos_neg, -c_raw, c_raw)
    (sin_val, cos_val)
end

@testset "fast_sincospi" begin
    # Exhaustive UInt32 error
    err, i_max = max_error_u32_2(x->PhiloxRNG.fast_sincospi(Float32, x), ref_sincospi)
    @test err < 2E-7
    err, i_max = max_error_u32_2(x->PhiloxRNG.fast_sincospi(Float64, x), ref_sincospi)
    @test err < 4E-16
    # Ensure accurate mean
    m = mean_u32_2(x->PhiloxRNG.fast_sincospi(Float32, x))
    @test abs(m[1]) < 1E-9
    @test abs(m[2]) < 1E-9
    # Edge cases
    @test PhiloxRNG.fast_sincospi(Float32, typemin(UInt32)) === (Float32(2*pi*2^-33), 1.0f0)
    @test PhiloxRNG.fast_sincospi(Float64, typemin(UInt32)) === (Float64(2*pi*2^-33), 1.0)
    @test PhiloxRNG.fast_sincospi(Float32, typemin(UInt64)) === (Float32(2*pi*2^-65), 1.0f0)
    @test PhiloxRNG.fast_sincospi(Float64, typemin(UInt64)) === (Float64(2*pi*2^-65), 1.0)
    # Sample UInt64 error
    err, i_max = sample_max_error_u64_2(x->PhiloxRNG.fast_sincospi(Float64, x), ref_sincospi)
    @test err < 4E-16
    err, i_max = sample_max_error_u64_2(x->PhiloxRNG.fast_sincospi(Float32, x), ref_sincospi)
    @test err < 2E-7
end
