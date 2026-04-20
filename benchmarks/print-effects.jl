#!/usr/bin/env -S JULIA_LOAD_PATH=@ julia --project=@script --startup-file=no

# This script prints inferred effects for PhiloxRNG entry points.

using PhiloxRNG

const EFFECT_SIGNATURE = (UInt64, UInt64, UInt64)
const EFFECT_FUNCTIONS = (
    ("philox4x32_10", philox4x32_10),
    ("randu01_f32", randu01_f32),
    ("randu01_f64", randu01_f64),
    ("randuneg11_f32", randuneg11_f32),
    ("randuneg11_f64", randuneg11_f64),
    ("randn_f32", randn_f32),
    ("randn_f64", randn_f64),
)

function print_effects(io::IO=stdout)
    for (index, (name, func)) in pairs(EFFECT_FUNCTIONS)
        println(io, "julia> Base.infer_effects($name, $EFFECT_SIGNATURE)")
        println(io, Base.infer_effects(func, EFFECT_SIGNATURE))
        if index != length(EFFECT_FUNCTIONS)
            println(io)
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    print_effects()
end