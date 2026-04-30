# ============================================================
# Fast sincospi for Box-Muller
#
# Computes (sin(θ), cos(θ)) from a uniform UInt32 (or UInt64),
# placing 2^N points uniformly around the unit circle with
# no point landing exactly on an axis.
#
# The bottom 3 bits of u select one of 8 octants (π/4 each).
# The upper bits give the reduced argument y ∈ (0, 0.25),
# with a +0.5 bias to avoid y = 0. The polynomials evaluate
# sin(πy) and cos(πy) — with π baked into the coefficients —
# then each octant bit directly controls one operation:
#   bit 0 → swap sin/cos
#   bit 1 → negate sin
#   bit 2 → negate cos
#
# The octants are not in geometric order, but the 2^N points
# are uniformly distributed around the unit circle regardless.
# ============================================================

# --- Float32 minimax coefficients for sin(πy)/y and cos(πy) in y² ---
#
# 4-term (degree 3 in y²) minimax via Remez algorithm on [0, 0.0625].
const SP_F32 = (3.1415927f0, -5.167708f0, 2.5497673f0, -0.58907866f0)
const CP_F32 = (1.0f0, -4.934788f0, 4.057578f0, -1.3061346f0)

@inline function fast_sincospi(::Type{Float32}, u::Union{UInt32, UInt64})
    oct = (u % Int32) & Int32(7)
    y = fma(Float32(u & ~oftype(u, 7)), Float32(2)^Int32(-(sizeof(u)*8+2)), Float32(2)^Int32(-(sizeof(u)*8)))

    sp = y * evalpoly(y * y, SP_F32)
    cp = evalpoly(y * y, CP_F32)

    swap    = !iszero(oct & Int32(1))
    sin_neg = !iszero(oct & Int32(2))
    cos_neg = !iszero(oct & Int32(4))

    s_raw = ifelse(swap, cp, sp)
    c_raw = ifelse(swap, sp, cp)
    sin_val = ifelse(sin_neg, -s_raw, s_raw)
    cos_val = ifelse(cos_neg, -c_raw, c_raw)
    (sin_val, cos_val)
end

# ============================================================
# Float64 / UInt64 version
#
# Same structure as Float32: bottom 3 bits → octant, upper
# 61 bits → reduced argument, +0.5 bias, direct bit mapping.
# ============================================================

const SP_F64 = (3.141592653589793, -5.167712780049954, 2.5501640398733785,
               -0.5992645289398095, 0.08214586918507949, -0.007370021659123395,
               0.0004615322405282014)
const CP_F64 = (1.0, -4.934802200544605, 4.0587121263978485,
               -1.3352627670374702, 0.23533054723811608, -0.025804938901032953,
               0.0019068114005246046)

@inline function fast_sincospi(::Type{Float64}, u::Union{UInt32, UInt64})
    oct = (u % Int32) & Int32(7)
    y = fma(Float64(u & ~oftype(u, 7)), Float64(2)^Int32(-(sizeof(u)*8+2)), Float64(2)^Int32(-(sizeof(u)*8)))

    sp = y * evalpoly(y * y, SP_F64)
    cp = evalpoly(y * y, CP_F64)

    swap    = !iszero(oct & Int32(1))
    sin_neg = !iszero(oct & Int32(2))
    cos_neg = !iszero(oct & Int32(4))

    s_raw = ifelse(swap, cp, sp)
    c_raw = ifelse(swap, sp, cp)
    sin_val = ifelse(sin_neg, -s_raw, s_raw)
    cos_val = ifelse(cos_neg, -c_raw, c_raw)
    (sin_val, cos_val)
end
