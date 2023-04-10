module DojoEnvironments

# constants
global const X_AXIS = [1;0;0]
global const Y_AXIS = [0;1;0]
global const Z_AXIS = [0;0;1]

using LinearAlgebra
using Random

using MeshCat
using StaticArrays
using Dojo

import Dojo: string_to_symbol, add_limits, RotX, RotY, RotZ, rotation_vector

export
    Environment,
    get_environment,
    get_mechanism,
    step!,
    get_state,
    visualize

include("mechanisms.jl")
include("environments.jl")
include("utilities.jl")
include("mechanisms/include.jl")
include("environments/include.jl")

end # module
