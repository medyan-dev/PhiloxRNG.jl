# Horner's method using explicit `fma` instead of `muladd`.
# `Base.evalpoly` uses `muladd`, which lets the compiler choose whether to fuse
# depending on context (e.g. inlining), giving results that can differ by an ulp.
# Using `fma` makes the result deterministic.
# Written out for the coefficient tuple lengths used in this package.
@inline function fma_evalpoly(x, p::NTuple{4, Any})
    fma(x, fma(x, fma(x, p[4], p[3]), p[2]), p[1])
end
@inline function fma_evalpoly(x, p::NTuple{7, Any})
    fma(x, fma(x, fma(x, fma(x, fma(x, fma(x, p[7], p[6]), p[5]), p[4]), p[3]), p[2]), p[1])
end
