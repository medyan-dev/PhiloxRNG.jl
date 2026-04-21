# Core log algorithm (polynomial coefficients, ln2 splitting, and reconstruction)
# adapted from fdlibm's e_log.c / e_logf.c (Sun Microsystems, 1993).
# See: https://github.com/JuliaMath/openlibm/blob/v0.8.7/src/e_log.c
#      https://github.com/JuliaMath/openlibm/blob/v0.8.7/src/e_logf.c

const _SQRT_HALF_I32 = reinterpret(Int32, Float32(sqrt(0.5)))
const _LOG_POLY_F32 = (0.6666666f0, 0.40000972f0, 0.28498787f0, 0.24279079f0)
const _LN2_HI_F32 = 0.6931381f0
const _LN2_LO_F32 = 9.058001f-6

@inline function _fast_log(::Type{Float32}, u::Union{UInt32, UInt64})
    x = u01(Float32, u)

    # Goal find k and f such that
    # x = 2^k * (1+f)
    # where sqrt(2)/2 ≤ (1+f) < sqrt(2)
    # if k is zero
    # we calculate f by -u01(Float32, ~u) which is more accurate for x near 1

    # Float32 has 23 fractional bits.
    # Float32 are ordered by value in Int32 space.
    # So k starts at 0, then ix becomes negative at x = prevfloat(sqrt(0.5f0))
    # making k = -1. For each power of 2 scale in x,
    # k changes by one, because we shift out the 23 fraction bits.
    ix = reinterpret(Int32, x) - _SQRT_HALF_I32
    k = ix >> Int32(23)

    # `f_plus_one_std` will have the same fraction bits as `x`
    # because `- _SQRT_HALF_I32` and `+ _SQRT_HALF_I32` cancel out in the low 23 bits.
    # `& Int32(0x007fffff)` clears the exponent field.
    # `f_plus_one_std` must either have an exponent of -1 or 0.
    # If x's fractional bits were less than the fractional bits of _SQRT_HALF_I32
    # the subtraction would borrow a 2^23 from the exponent field of x,
    # which then shows up as an extra 2^23 in the low 23 bits after masking.
    # When adding _SQRT_HALF_I32 back this extra 2^23 will propagate up and
    # bump the exponent from -1 to 0.
    f_plus_one_std = reinterpret(Float32, (ix & Int32(0x007fffff)) + _SQRT_HALF_I32)
    f_std = f_plus_one_std - 1.0f0

    f_comp = -u01(Float32, ~u)
    f = ifelse(k == Int32(0), f_comp, f_std)

    # Goal get log(1+f) via a polynomial approx
    # s = f / (2 + f)
    # log(1+f) = 2s + s^3*log_poly(s^2)
    # R = s^2*log_poly(s^2)
    # log(1+f) = f - f^2/2 + s(f^2/2 + R)
    s = f / (2.0f0 + f)
    z = s * s
    R = z * evalpoly(z, _LOG_POLY_F32)
    hfsq = 0.5f0 * f * f

    # log(x) = k*log(2) + log(1+f)
    k_f32 = Float32(k)
    # Simpler version, but fails the mean test by 2E-9
    # fma(k_f32, 0.6931472f0 #= log(2) =#, fma(s, R-f, f))
    # log(2) = _LN2_HI_F32 + _LN2_LO_F32
    fma(k_f32, _LN2_HI_F32,
        f - (hfsq - fma(s, (hfsq + R), k_f32 * _LN2_LO_F32))
    )
end

const _SQRT_HALF_I64 = reinterpret(Int64, sqrt(0.5))
const _LOG_POLY_F64 = (
    6.666666666666735130e-01,
    3.999999999940941908e-01,
    2.857142874366239149e-01,
    2.222219843214978396e-01,
    1.818357216161805012e-01,
    1.531383769920937332e-01,
    1.479819860511658591e-01,
)
const _LN2_HI_F64 = 6.93147180369123816490e-01
const _LN2_LO_F64 = 1.90821492927058770002e-10

@inline function _fast_log(::Type{Float64}, u::Union{UInt32, UInt64})
    # See Float32 version for commentary
    x = u01(Float64, u)

    ix = reinterpret(Int64, x) - _SQRT_HALF_I64
    k = ix >> Int64(52)
    f_std = reinterpret(Float64, (ix & Int64(0x000fffffffffffff)) + _SQRT_HALF_I64) - 1.0

    f_comp = -u01(Float64, ~u)
    f = ifelse(k == Int64(0), f_comp, f_std)

    s = f / (2.0 + f)
    z = s * s
    R = z * evalpoly(z, _LOG_POLY_F64)
    hfsq = 0.5 * f * f

    # log(x) = k*ln2 + log(1+f)
    k_f64 = Float64(k)
    fma(k_f64, _LN2_HI_F64,
        f - (hfsq - fma(s, (hfsq + R), k_f64 * _LN2_LO_F64))
    )
end
