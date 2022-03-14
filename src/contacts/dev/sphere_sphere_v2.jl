using Symbolics 
using RoboDojo
using LinearAlgebra
using SparseArrays

using MeshCat
using GeometryBasics
using Colors
using CoordinateTransformations

# visualize
function set_background!(vis::Visualizer; top_color=RGBA(1,1,1.0), bottom_color=RGBA(1,1,1.0))
    setprop!(vis["/Background"], "top_color", top_color)
    setprop!(vis["/Background"], "bottom_color", bottom_color)
end
vis = Visualizer()
open(vis)
set_background!(vis)


"""
    variables:
    pa ∈ R^3 # parent body contact point
    pb ∈ R^3 # child  body  contact point 

    sa ∈ R+  # slack for parent body collision set 
    sb ∈ R+  # slack for child  body collision set

    λa ∈ R   # dual  for parent equality constraint 
    λb ∈ R   # dual  for child  equality constraint 

    νa ∈ R+  # dual  for parent slack 
    νb ∈ R+  # dual  for child  slack 
    
    data: 
    xa ∈ R^3 # parent body position 
    qa ∈ H   # parent body orientation 
    xb ∈ R^3 # child  body position 
    qb ∈ H   # child  body orientation 
    ra ∈ R+  # parent body collision radius
    rb ∈ R+  # child  body collision radius

    objective: 
    ||pa - pb||

    -> (pa - pb)' (pa - pb) # squared distance

    constraints: 
    ||pa - xa|| <= ra 
    ||pb - xb|| <= rb

    -> 
        sa - (ra^2 - (pa - xa)' (pa - xa)) = 0 # squared + slack
        sb - (rb^2 - (pb - xb)' (pb - xb)) = 0 # squared + slack
        sa, sb >= 0

    primal: 
    z = (pa, pb, sa, sb) ∈ R^8
    y = (λa, λb, νa, νb) ∈ R^4
    θ = (xa, qa, xb, qb, ra, rb) ∈ R^16
"""

nz = 8 
ny = 4 
nw = nz + ny 
nθ = 16
@variables z[1:nz] y[1:ny] θ[1:nθ] κ[1:1]

function unpack_primals(z) 
    pa = z[0 .+ (1:3)]
    pb = z[3 .+ (1:3)]
    sa = z[6 .+ (1:1)]
    sb = z[7 .+ (1:1)]

    return pa, pb, sa, sb 
end

function unpack_duals(y)
   λa = y[0 .+ (1:1)]
   λb = y[1 .+ (1:1)]
   νa = y[2 .+ (1:1)]
   νb = y[3 .+ (1:1)]

   return λa, λb, νa, νb
end

function unpack_data(θ)
    xa = θ[1:3]
    qa = θ[3 .+ (1:4)]
    xb = θ[7 .+ (1:3)]
    qb = θ[10 .+ (1:4)]
    ra = θ[14 .+ (1:1)]
    rb = θ[15 .+ (1:1)]

    return xa, qa, xb, qb, ra, rb 
end

function objective(z)
    pa, pb, sa, sb = unpack_primals(z)
    d = pa - pb 
    return dot(d, d)
end

function constraints(z, θ) 
    pa, pb, sa, sb = unpack_primals(z)
    xa, qa, xb, qb, ra, rb = unpack_data(θ)
    [
        sa[1] - (ra[1]^2 - (pa - xa)' * (pa - xa));
        sb[1] - (rb[1]^2 - (pb - xb)' * (pb - xb)); 
    ]
end

function lagrangian(z, y, θ)
    # initialize
    L = 0.0

    # primals 
    pa, pb, sa, sb = unpack_primals(z)

    # duals 
    λa, λb, νa, νb = unpack_duals(y)

    # objective 
    J = objective(z) 
    L += J 

    # constraints
    c = constraints(z, θ)
    L += sum([λa[1] λb[1]] * c)

    # inequalities 
    L -= sa[1] * νa[1] 
    L -= sb[1] * νb[1] 

    return L 
end

L = lagrangian(z, y, θ)
Lz = Symbolics.gradient(L, z)
function residual(w, θ, κ)
    # primals 
    z = w[1:8]
    pa, pb, sa, sb = unpack_primals(z)

    # duals 
    y = w[8 .+ (1:4)]
    λa, λb, νa, νb = unpack_duals(y)

    # Lagrangian 
    lag = lagrangian(z, y, θ)
    lagz = Symbolics.gradient(lag, z)
    con = constraints(z, θ) 
    comp = [
            sa[1] * νa[1]; 
            sb[1] * νb[1];
           ]

    res = [
            lagz;
            con;
            comp .- κ;
          ]

    return res 
end

w = [z; y]
r = residual([z; y], θ, κ)
rw = Symbolics.jacobian(r, [z; y])
rθ = Symbolics.jacobian(r, θ)

r_func = eval(Symbolics.build_function(r, w, θ, κ)[2])
rw_func = eval(Symbolics.build_function(rw, w, θ)[2])
rθ_func = eval(Symbolics.build_function(rθ, w, θ)[2])

# pre-allocate
r0 = zeros(nw)
rw0 = zeros(nw, nw)
rθ0 = zeros(nw, nθ)

# random 
w0 = randn(nw) 
θ0 = randn(nθ) 
κ0 = randn(1)

r_func(r0, w0, θ0, κ0)
rw_func(rw0, w0, θ0)
rθ_func(rθ0, w0, θ0)

function rw_func_reg(rw, w, θ) 
    rw_func(rw, w, θ)
    rw .+= Diagonal([1.0e-5 * ones(8); -1.0e-5 * ones(4)])
    return 
end

(rw0 + Diagonal([1.0e-5 * ones(8); -1.0e-5 * ones(4)])) \ rθ0

## setup 
xa = [0.25; 0.5; 1.0]
qa = [1.0; 0.0; 0.0; 0.0]
ra = 0.1

xb = [1.0; 0.0; 0.0]
qb = [1.0; 0.0; 0.0; 0.0]
rb = 0.1

## initialization 
w0 = [xa; xb; 1.0; 1.0; 0.0; 0.0; 1.0; 1.0]
θ0 = [xa; qa; xb; qb; ra; rb]

r_func(r0, w0, θ0, κ0)
rw_func_reg(rw0, w0, θ0)
# rw_func(rw0, w0, θ0)
rθ_func(rθ0, w0, θ0)

rw0 \ rθ0

## solver 
idx = RoboDojo.IndicesOptimization(
    nw, nw,
    [[7, 8], [11, 12]], [[7, 8], [11, 12]],
    Vector{Vector{Vector{Int}}}(), Vector{Vector{Vector{Int}}}(),
    collect(1:10),
    collect(11:12),
    Vector{Int}(),
    Vector{Vector{Int}}(),
    collect(11:12),
)

ip = RoboDojo.interior_point(w0, θ0;
    s = RoboDojo.Euclidean(length(w0)),
    idx = idx,
    r! = r_func, rz! = rw_func_reg, rθ! = rθ_func,
    r  = zeros(idx.nΔ),
    rz = zeros(idx.nΔ, idx.nΔ),
    rθ = zeros(idx.nΔ, length(θ0)),
    opts = RoboDojo.InteriorPointOptions(
            undercut=Inf,
            γ_reg=0.1,
            r_tol=1e-6,
            κ_tol=1e-6,  
            max_ls=25,
            ϵ_min=0.25,
            diff_sol=true,
            verbose=true))

RoboDojo.interior_point_solve!(ip)

pa = ip.z[0 .+ (1:3)]
pb = ip.z[3 .+ (1:3)]

∂pa∂xa = ip.δz[0 .+ (1:3), 0  .+ (1:3)]
∂pa∂qa = ip.δz[0 .+ (1:3), 3  .+ (1:4)]
∂pa∂xb = ip.δz[0 .+ (1:3), 7  .+ (1:3)]
∂pa∂qb = ip.δz[0 .+ (1:3), 10 .+ (1:4)]

∂pb∂xa = ip.δz[3 .+ (1:3), 0  .+ (1:3)]
∂pb∂qa = ip.δz[3 .+ (1:3), 3  .+ (1:4)]
∂pb∂xb = ip.δz[3 .+ (1:3), 7  .+ (1:3)]
∂pb∂qb = ip.δz[3 .+ (1:3), 10 .+ (1:4)]

# sphere a
sa = GeometryBasics.Sphere(Point(0.0, 0.0, 0.0), ra)
color1 = Colors.RGBA(0.7, 0.7, 0.7, 0.5);
setobject!(vis[:spherea], sa, MeshPhongMaterial(color=color1))
settransform!(vis[:spherea], Translation(xa...))

# sphere b
sb = GeometryBasics.Sphere(Point(0.0, 0.0, 0.0), rb)
color2 = Colors.RGBA(0.7, 0.7, 0.7, 0.5);
setobject!(vis[:sb], sb, MeshPhongMaterial(color=color2))
settransform!(vis[:sb], Translation(xb...))

# closest points
color_cp = Colors.RGBA(0.0, 0.0, 0.0, 1.0);
cs1 = GeometryBasics.Sphere(Point(0.0, 0.0, 0.0), 0.025)
cs2 = GeometryBasics.Sphere(Point(0.0, 0.0, 0.0), 0.025)
setobject!(vis[:cs1], cs1, MeshPhongMaterial(color=color_cp))
setobject!(vis[:cs2], cs2, MeshPhongMaterial(color=color_cp))
settransform!(vis[:cs1], Translation(pa...))
settransform!(vis[:cs2], Translation(pb...))



