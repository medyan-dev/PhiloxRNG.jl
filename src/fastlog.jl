# Core log algorithm (polynomial coefficients, ln2 splitting, and reconstruction)
# adapted from fdlibm's e_log.c / e_logf.c (Sun Microsystems, 1993).
# See: https://github.com/JuliaMath/openlibm/blob/v0.8.7/src/e_log.c

const _SQRT_HALF_I32 = reinterpret(Int32, Float32(sqrt(0.5)))

const _LOG_ODD_F32  = (0.6666666f0, 0.28498787f0)
const _LOG_EVEN_F32 = (0.40000972f0, 0.24279079f0)

@inline function _fast_log(::Type{Float32}, u::Union{UInt32, UInt64})
    x = u01(Float32, u)

    ix = reinterpret(Int32, x) - _SQRT_HALF_I32
    k = ix >> Int32(23)
    f_std = reinterpret(Float32, (ix & Int32(0x007fffff)) + _SQRT_HALF_I32) - 1.0f0

    f_comp = -u01(Float32, ~u)
    f = ifelse(k == Int32(0), f_comp, f_std)

    s = f / (2.0f0 + f)
    z = s * s; w = z * z
    R = z * evalpoly(w, _LOG_ODD_F32) + w * evalpoly(w, _LOG_EVEN_F32)

    hfsq = 0.5f0 * f * f

    Float32(k) * 0.6931381f0 -
        ((hfsq - (s * (hfsq + R) +
          Float32(k) * 9.058001f-6)) - f)
end

const _SQRT_HALF_I64 = reinterpret(Int64, sqrt(0.5))

const _LOG_ODD_F64  = (6.666666666666735130e-01, 2.857142874366239149e-01, 1.818357216161805012e-01, 1.479819860511658591e-01)
const _LOG_EVEN_F64 = (3.999999999940941908e-01, 2.222219843214978396e-01, 1.531383769920937332e-01)

@inline function _fast_log(::Type{Float64}, u::Union{UInt32, UInt64})
    x = u01(Float64, u)

    ix = reinterpret(Int64, x) - _SQRT_HALF_I64
    k = ix >> Int64(52)
    f_std = reinterpret(Float64, (ix & Int64(0x000fffffffffffff)) + _SQRT_HALF_I64) - 1.0

    f_comp = -u01(Float64, ~u)
    f = ifelse(k == Int64(0), f_comp, f_std)

    s = f / (2.0 + f)
    z = s * s; w = z * z
    R = z * evalpoly(w, _LOG_ODD_F64) + w * evalpoly(w, _LOG_EVEN_F64)
    hfsq = 0.5 * f * f

    Float64(k) * 6.93147180369123816490e-01 -
        ((hfsq - (s * (hfsq + R) + Float64(k) * 1.90821492927058500170e-10)) - f)
end
