const _SQRT_HALF_I32 = reinterpret(Int32, Float32(sqrt(0.5)))

const _LOG_ODD_F32  = (reinterpret(Float32, Int32(0x3f2aaaaa)), reinterpret(Float32, Int32(0x3e91e9ee)))
const _LOG_EVEN_F32 = (reinterpret(Float32, Int32(0x3eccce13)), reinterpret(Float32, Int32(0x3e789e26)))

@inline function _fast_log(u::UInt32)
    x = fma(Float32(u), Float32(2)^(-32), Float32(2)^(-33))

    ix = reinterpret(Int32, x) - _SQRT_HALF_I32
    k = ix >> Int32(23)
    f_std = reinterpret(Float32, (ix & Int32(0x007fffff)) + _SQRT_HALF_I32) - 1.0f0

    f_comp = -fma(Float32(~u), Float32(2)^(-32), Float32(2)^(-33))
    f = ifelse(k == Int32(0), f_comp, f_std)

    s = f / (2.0f0 + f)
    z = s * s; w = z * z
    R = z * evalpoly(w, _LOG_ODD_F32) + w * evalpoly(w, _LOG_EVEN_F32)

    hfsq = 0.5f0 * f * f

    Float32(k) * reinterpret(Float32, Int32(0x3f317180)) -
        ((hfsq - (s * (hfsq + R) +
          Float32(k) * reinterpret(Float32, Int32(0x3717f7d1)))) - f)
end

const _SQRT_HALF_I64 = reinterpret(Int64, sqrt(0.5))

const _LOG_ODD_F64  = (6.666666666666735130e-01, 2.857142874366239149e-01, 1.818357216161805012e-01, 1.479819860511658591e-01)
const _LOG_EVEN_F64 = (3.999999999940941908e-01, 2.222219843214978396e-01, 1.531383769920937332e-01)

@inline function _fast_log(u::UInt64)
    x = fma(Float64(u), Float64(2)^(-64), Float64(2)^(-65))

    ix = reinterpret(Int64, x) - _SQRT_HALF_I64
    k = ix >> Int64(52)
    f_std = reinterpret(Float64, (ix & Int64(0x000fffffffffffff)) + _SQRT_HALF_I64) - 1.0

    f_comp = -fma(Float64(~u), Float64(2)^(-64), Float64(2)^(-65))
    f = ifelse(k == Int64(0), f_comp, f_std)

    s = f / (2.0 + f)
    z = s * s; w = z * z
    R = z * evalpoly(w, _LOG_ODD_F64) + w * evalpoly(w, _LOG_EVEN_F64)
    hfsq = 0.5 * f * f

    Float64(k) * 6.93147180369123816490e-01 -
        ((hfsq - (s * (hfsq + R) + Float64(k) * 1.90821492927058500170e-10)) - f)
end
