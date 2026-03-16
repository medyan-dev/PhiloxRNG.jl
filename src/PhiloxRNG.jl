module PhiloxRNG

if VERSION >= v"1.11.0-DEV.469"
    eval(Meta.parse("""
        public
            u01,
            uneg11,
            boxmuller
    """))
end

export philox4x32_10
export randu01_f32
export randu01_f64
export randuneg11_f32
export randuneg11_f64
export randn_f32
export randn_f64

include("philox.jl")
include("fastlog.jl")
include("fastsincospi.jl")
include("distributions.jl")
end
