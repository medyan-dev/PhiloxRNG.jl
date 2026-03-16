"""
    u01(F, u::Union{UInt32, UInt64})::F

Convert an unsigned integer to a float of type `F` uniformly distributed in (0, 1].

Ported from [Random123 uniform.hpp](https://github.com/DEShawResearch/random123/blob/v1.14.0/include/Random123/uniform.hpp#L175).
"""
@inline function u01(::Type{F}, u::UInt32)::F where F
    fma(F(u), F(2)^(-32), F(2)^(-33))
end

@inline function u01(::Type{F}, u::UInt64)::F where F
    fma(F(u), F(2)^(-64), F(2)^(-65))
end

"""
    randu01_f64(ctr0::UInt64, ctr1::UInt64, key::UInt64)::NTuple{2, Float64}

Return two `Float64` values uniformly distributed in (0, 1] from a Philox4x32 counter-based RNG.
"""
@inline function randu01_f64(ctr0::UInt64, ctr1::UInt64, key::UInt64)::NTuple{2, Float64}
    a1, a2, a3, a4 = philox4x32_10(ctr0, ctr1, key)
    (
        u01(Float64, (UInt64(a1) | UInt64(a2)<<32)),
        u01(Float64, (UInt64(a3) | UInt64(a4)<<32)),
    )
end

"""
    randu01_f32(ctr0::UInt64, ctr1::UInt64, key::UInt64)::NTuple{4, Float32}

Return four `Float32` values uniformly distributed in (0, 1] from a Philox4x32 counter-based RNG.
"""
@inline function randu01_f32(ctr0::UInt64, ctr1::UInt64, key::UInt64)::NTuple{4, Float32}
    a1, a2, a3, a4 = philox4x32_10(ctr0, ctr1, key)
    (
        u01(Float32, a1),
        u01(Float32, a2),
        u01(Float32, a3),
        u01(Float32, a4),
    )
end


"""
    uneg11(F, u::Union{UInt32, UInt64})::F

Convert an unsigned integer to a float of type `F` uniformly distributed in [-1, 1].

Ported from [Random123 uniform.hpp](https://github.com/DEShawResearch/random123/blob/v1.14.0/include/Random123/uniform.hpp#L206).
"""
@inline function uneg11(::Type{F}, u::UInt32)::F where F
    fma(F(u%Int32), F(2)^(-31), F(2)^(-32))
end

@inline function uneg11(::Type{F}, u::UInt64)::F where F
    fma(F(u%Int64), F(2)^(-63), F(2)^(-64))
end

"""
    randuneg11_f64(ctr0::UInt64, ctr1::UInt64, key::UInt64)::NTuple{2, Float64}

Return two `Float64` values uniformly distributed in [-1, 1] from a Philox4x32 counter-based RNG.
"""
@inline function randuneg11_f64(ctr0::UInt64, ctr1::UInt64, key::UInt64)::NTuple{2, Float64}
    a1, a2, a3, a4 = philox4x32_10(ctr0, ctr1, key)
    (
        uneg11(Float64, (UInt64(a1) | UInt64(a2)<<32)),
        uneg11(Float64, (UInt64(a3) | UInt64(a4)<<32)),
    )
end

"""
    randuneg11_f32(ctr0::UInt64, ctr1::UInt64, key::UInt64)::NTuple{4, Float32}

Return four `Float32` values uniformly distributed in [-1, 1] from a Philox4x32 counter-based RNG.
"""
@inline function randuneg11_f32(ctr0::UInt64, ctr1::UInt64, key::UInt64)::NTuple{4, Float32}
    a1, a2, a3, a4 = philox4x32_10(ctr0, ctr1, key)
    (
        uneg11(Float32, a1),
        uneg11(Float32, a2),
        uneg11(Float32, a3),
        uneg11(Float32, a4),
    )
end


"""
    boxmuller(F, u1::Union{UInt32, UInt64}, u2::Union{UInt32, UInt64})::NTuple{2, F}

Transform two uniformly distributed unsigned integers into two normally distributed
floats of type `F` using the Box-Muller method with fast polynomial approximations
of log and sincospi.
"""
@inline function boxmuller(::Type{F}, u1::T, u2::T)::NTuple{2, F} where {F, T <: Union{UInt32, UInt64}}
    r = Base.FastMath.sqrt_fast(-2 * _fast_log(u2))
    s, c = _fast_sincospi(u1)
    (F(r * s), F(r * c))
end

"""
    randn_f64(ctr0::UInt64, ctr1::UInt64, key::UInt64)::NTuple{2, Float64}

Return two normally distributed `Float64` values using the Box-Muller method, from a Philox4x32 counter-based RNG.
"""
@inline function randn_f64(ctr0::UInt64, ctr1::UInt64, key::UInt64)::NTuple{2, Float64}
    a1, a2, a3, a4 = philox4x32_10(ctr0, ctr1, key)
    boxmuller(Float64, (UInt64(a1) | UInt64(a2)<<32), (UInt64(a3) | UInt64(a4)<<32))
end

"""
    randn_f32(ctr0::UInt64, ctr1::UInt64, key::UInt64)::NTuple{4, Float32}

Return four normally distributed `Float32` values using the Box-Muller method, from a Philox4x32 counter-based RNG.
"""
@inline function randn_f32(ctr0::UInt64, ctr1::UInt64, key::UInt64)::NTuple{4, Float32}
    a1, a2, a3, a4 = philox4x32_10(ctr0, ctr1, key)
    n1, n2 = boxmuller(Float32, a1, a2)
    n3, n4 = boxmuller(Float32, a3, a4)
    (n1, n2, n3, n4)
end
