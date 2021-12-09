################################################################################
# Quadruped
################################################################################
struct Quadruped end 

function quadruped(; mode::Symbol=:min, dt::T=0.05, g::T=-9.81, cf=0.8,
    damper=10.0, spring=0.0,
    s::Int=1, contact::Bool=true, vis::Visualizer=Visualizer()) where T

    mechanism = getquadruped(Δt=dt, g=g, cf=cf, damper=damper, spring=spring)
    initialize!(mechanism, :quadruped)

    if mode == :min
        nx = minCoordDim(mechanism)
    elseif mode == :max 
        nx = maxCoordDim(mechanism)
    end
    nu = 12
    no = nx

    aspace = BoxSpace(nu, low=(-1.0e-3 * ones(nu)), high=(1.0e-3 * ones(nu)))
    ospace = BoxSpace(no, low=(-Inf * ones(no)), high=(Inf * ones(no)))

    rng = MersenneTwister(s)
    z = getMaxState(mechanism)
    x = mode == :min ? max2min(mechanism, z) : z
    fx = zeros(nx, nx) 
    fu = zeros(nx, nu)

    u_prev = zeros(nu)
    control_mask = [zeros(nu, 6) I(nu)] 

    build_robot(vis, mechanism)

    TYPES = [Quadruped, T, typeof(mechanism), typeof(aspace), typeof(ospace)]
    Environment{TYPES...}(mechanism, mode, aspace, ospace, 
        x, fx, fu,
        u_prev, control_mask,
        nx, nu, no,
        rng, vis)
end
