# Horner's method using explicit `fma` instead of `muladd`.
# `Base.evalpoly` uses `muladd`, which lets the compiler choose whether to fuse
# depending on context (e.g. inlining), giving results that can differ by an ulp.
# Using `fma` makes the result deterministic.
@inline fma_evalpoly(x, p::Tuple{Any}) = p[1]
@inline fma_evalpoly(x, p::Tuple) = fma(x, fma_evalpoly(x, Base.tail(p)), p[1])
