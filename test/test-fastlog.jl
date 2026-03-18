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

function fast_sqrt_log(::Type{F}, u) where F
    Base.sqrt_llvm(-2*PhiloxRNG._fast_log(F, u))
end

function ref_sqrt_log(u::UInt32)
    x = Float64(u)*Float64(2)^(-32) + Float64(2)^(-33)
    sqrt(-2 * log(x))
end

function ref_sqrt_log(u::UInt64)
    g = if u < UInt64(2)^63
        x = fma(Float64(u), Float64(2)^(-64), Float64(2)^(-65))
        log(x)
    else
        x = fma(Float64(~u), Float64(2)^(-64), Float64(2)^(-65))
        log1p(-x)
    end
    sqrt(-2 * g)
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
    err, i_max = max_error_u32(x->fast_sqrt_log(Float32, x), ref_sqrt_log)
    @test err < 5E-7
    err, i_max = max_error_u32(x->fast_sqrt_log(Float64, x), ref_sqrt_log)
    @test err < 3E-15
    # Ensure accurate msd
    msd = mean_u32(x->PhiloxRNG._fast_log(Float32, x))
    @test abs(msd + 1) < 1E-9
    # Edge cases
    @test PhiloxRNG._fast_log(Float32, typemax(UInt32)) < 0
    @test PhiloxRNG._fast_log(Float32, typemin(UInt32)) > -Inf
    # Sample UInt32 error
    err, i_max = sample_max_error_u64(x->fast_sqrt_log(Float64, x), ref_sqrt_log)
    @test err < 3E-15
    err, i_max = sample_max_error_u64(x->fast_sqrt_log(Float32, x), ref_sqrt_log)
    @test err < 5E-7
end
