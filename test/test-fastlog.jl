using Test
using PhiloxRNG: PhiloxRNG
using MultiFloats: Float64x2

# Return the max error between a and b and which input causes it.
function max_error_u32(a,b)
    err::Float64 = 0.0
    i_max::UInt32 = 0
    for i in UInt32(0):typemax(UInt32)
        d = abs(a(i) - b(i))
        d < err && continue
        err = d
        i_max = i
    end
    err, i_max
end

# Return the mean value over u32
function mean_u32(a)
    r::Float64x2 = 0.0
    for i in UInt32(0):typemax(UInt32)
        r += a(i)
    end
    r*Float64x2(2)^-32
end

function fast_sqrt_log(u)
    Base.FastMath.sqrt_fast(-2*PhiloxRNG._fast_log(u))
end

function ref_sqrt_log(u::UInt32)
    x = Float64(u)*Float64(2)^(-32) + Float64(2)^(-33)
    Float32(sqrt(-2 * log(x)))
end

function ref_sqrt_log(u::UInt64)
    g = if u < UInt64(2)^63
        x = fma(Float64(u), Float64(2)^(-64), Float64(2)^(-65))
        log(x)
    else
        x = fma(Float64(~u), Float64(2)^(-64), Float64(2)^(-65))
        log1p(-x)
    end
    Float64(sqrt(-Float64(2) * g))
end

function sample_max_error_u64(a,b)
    err::Float64 = 0.0
    i_max::UInt64 = 0
    u2 = UInt64(2)
    # First, middle and last densely sampled values
    for i in UInt64(0) : u2^32-1
        # if iszero(mod(i, 2^28))
        #     @show i, err
        # end
        d = abs(a(i) - b(i))
        d < err && continue
        err = d
        i_max = i
    end
    for i in u2^63-u2^32 : u2^63+u2^32
        # if iszero(mod(i, 2^28))
        #     @show i, err
        # end
        d = abs(a(i) - b(i))
        d < err && continue
        err = d
        i_max = i
    end
    for i in u2^64-u2^32 : u2^64-1
        # if iszero(mod(i, 2^28))
        #     @show i, err
        # end
        d = abs(a(i) - b(i))
        d < err && continue
        err = d
        i_max = i
    end
    # Now sample every 2^32 through the whole range
    for i in UInt64(0) : u2^32 : u2^64-1
        d = abs(a(i) - b(i))
        d < err && continue
        err = d
        i_max = i
    end
    err, i_max
end

@testset "_fast_log" begin
    # Exhaustive Float32 error
    err, i_max = max_error_u32(fast_sqrt_log, ref_sqrt_log)
    @test err < 5E-7
    # Ensure accurate msd
    msd = mean_u32(PhiloxRNG._fast_log)
    @test abs(msd + 1) < 1E-9
    # Edge cases
    @test PhiloxRNG._fast_log(typemax(UInt32)) < 0
    @test PhiloxRNG._fast_log(typemin(UInt32)) > -Inf
    # Sample Float64 error
    err, i_max = sample_max_error_u64(fast_sqrt_log, ref_sqrt_log)
    @test err < 3E-15
end
