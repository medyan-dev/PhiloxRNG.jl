# Constants from philox.h
const PHILOX_M4x32_0 = 0xD2511F53
const PHILOX_M4x32_1 = 0xCD9E8D57

const PHILOX_W32_0 = 0x9E3779B9
const PHILOX_W32_1 = 0xBB67AE85

const PHILOX4x32_DEFAULT_ROUNDS = 10

@inline function _philox4x32round(ctr::NTuple{4, UInt32}, key::NTuple{2, UInt32})::NTuple{4, UInt32}
    mul0 = widemul(PHILOX_M4x32_0, ctr[1])
    mul1 = widemul(PHILOX_M4x32_1, ctr[3])
    hi0 = (mul0>>32)%UInt32
    hi1 = (mul1>>32)%UInt32
    lo0 = mul0%UInt32
    lo1 = mul1%UInt32
    (hi1 ⊻ ctr[2] ⊻ key[1], lo1, hi0 ⊻ ctr[4] ⊻ key[2], lo0)
end

@inline function _philox4x32bumpkey(key::NTuple{2, UInt32})::NTuple{2, UInt32}
    (key[1] + PHILOX_W32_0, key[2] + PHILOX_W32_1)
end

"""
    philox4x32_10(ctr::NTuple{4, UInt32}, key::NTuple{2, UInt32})::NTuple{4, UInt32}
    philox4x32_10(ctr0::UInt64, ctr1::UInt64, key::UInt64)::NTuple{4, UInt32}

Run 10 rounds of the Philox4x32 counter-based random number generator, returning four `UInt32` outputs.

Ported from [Random123 philox.h](https://github.com/DEShawResearch/random123/blob/v1.14.0/include/Random123/philox.h).
"""
@inline function philox4x32_10(ctr::NTuple{4, UInt32}, key::NTuple{2, UInt32})::NTuple{4, UInt32}
    ctr = _philox4x32round(ctr, key)
    for i in 1:PHILOX4x32_DEFAULT_ROUNDS-1
        key = _philox4x32bumpkey(key)
        ctr = _philox4x32round(ctr, key)
    end
    ctr
end

@inline function philox4x32_10(ctr0::UInt64, ctr1::UInt64, key::UInt64)::NTuple{4, UInt32}
    philox4x32_10((ctr0%UInt32, (ctr0>>32)%UInt32, ctr1%UInt32, (ctr1>>32)%UInt32), (key%UInt32, (key>>32)%UInt32))
end
