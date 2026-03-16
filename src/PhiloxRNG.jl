module PhiloxRNG

export philox4x32_10
public u01
export randu01_f32
export randu01_f64
public uneg11
export randuneg11_f32
export randuneg11_f64
public boxmuller
export randn_f32
export randn_f64

include("philox.jl")
include("fastlog.jl")
include("fastsincospi.jl")
include("distributions.jl")
end
