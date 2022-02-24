# Utils
function module_dir()
    return joinpath(@__DIR__, "..", "..")
end

# Activate package
using Pkg
Pkg.activate(module_dir())

# Load packages
using Plots
using Random
using MeshCat

# Open visualizer
vis = Visualizer()
open(vis)

# Include new files
include(joinpath(module_dir(), "examples", "loader.jl"))

# Build mechanism
include("mechanism_zoo.jl")
mech = getmechanism(:nslider, timestep = 0.01, g = -2.0, Nb = 5)
initialize!(mech, :nslider, z1 = 0.0, Δz = 1.1)

for (i,joint) in enumerate(mech.joints)
    if i ∈ (1:10)
        jt = joint.translational
        jr = joint.rotational
        joint.isdamper = false #false
        joint.isspring = false #false

        jt.spring = 0.0 * 1/1 * 1.5 * 1e-1 .* sones(3)[1]# 1e4
        jt.damper = 0.0 * 1/1 * 3.1 * 1e-1 .* sones(3)[1]# 1e4
        jr.spring = 0.0 * 1/1 * 2.7 * 1e-1 .* sones(3)[1]# 1e4
        jr.damper = 0.0 * 1/1 * 2.2 * 1e-1 .* sones(3)[1]# 1e4
    end
end

storage = simulate!(mech, 1.0, record = true, solver = :mehrotra!)
# visstorage = simulate!(mech, 4.0, record = true, solver = :mehrotra!)
# plot(hcat(Vector.(storage.x[1])...)')
# plot(hcat([[q.w, q.x, q.y, q.z] for q in storage.q[1]]...)')
# plot(hcat(Vector.(storage.v[1])...)')
# plot(hcat(Vector.(storage.ω[1])...)')

visualize(mech, storage, vis = vis)

################################################################################
# Differentiation
################################################################################

# Set data
data = get_data(mech)
set_data!(mech, data)
sol = get_solution(mech)
Nb = length(collect(mech.bodies))
attjac = attitude_jacobian(data, Nb)

# IFT
set_entries!(mech)
datamat = full_data_matrix(deepcopy(mech))
solmat = full_matrix(mech.system)
sensi = - (solmat \ datamat)

# finite diff
fd_datamat = finitediff_data_matrix(deepcopy(mech), data, sol, δ = 1e-5) * attjac
@test norm(fd_datamat + datamat, Inf) < 1e-8
plot(Gray.(abs.(datamat)))
plot(Gray.(abs.(fd_datamat)))

norm((datamat + fd_datamat)[11:16, 25:26], Inf)
norm((datamat + fd_datamat)[17:22, 25:26], Inf)

(datamat)[11:16, 25:26]
(-fd_datamat)[11:16, 25:26]

fd_solmat = finitediff_sol_matrix(mech, data, sol, δ = 1e-5)
@test norm(fd_solmat + solmat, Inf) < 1e-8
plot(Gray.(abs.(solmat)))
plot(Gray.(abs.(fd_solmat)))
norm(fd_solmat + solmat, Inf)


norm((fd_solmat + solmat)[1:10, 1:10], Inf)
norm((fd_solmat + solmat)[1:10, 11:22], Inf)
norm((fd_solmat + solmat)[11:22, 1:10], Inf)
norm((fd_solmat + solmat)[11:22, 11:22], Inf)


norm((fd_solmat + solmat)[11:16, 11:16], Inf)
norm((fd_solmat + solmat)[11:16, 17:22], Inf)
norm((fd_solmat + solmat)[17:22, 11:16], Inf)
norm((fd_solmat + solmat)[17:22, 17:22], Inf)

(fd_solmat + solmat)[11:16, 11:16]
(fd_solmat + solmat)[11:16, 17:22]
(fd_solmat + solmat)[17:22, 11:16]
(fd_solmat + solmat)[17:22, 17:22]

fd_solmat[11:16, 11:16]
fd_solmat[11:16, 17:22]
fd_solmat[17:22, 11:16]
fd_solmat[17:22, 17:22]

solmat[11:16, 11:16]
solmat[11:16, 17:22]
solmat[17:22, 11:16]
solmat[17:22, 17:22]

norm(solmat, Inf)


# solmat[1:5, 1:5]
# solmat[1:5, 6:11]
# solmat[6:11, 1:5]
# solmat[6:11, 6:11]
# solmat[9:11, 9:11]
#
#
#
# fd_solmat[1:5, 1:5]
# fd_solmat[1:5, 6:11]
# fd_solmat[6:11, 1:5]
# fd_solmat[6:11, 6:11]
# fd_solmat[9:11, 9:11]
#
#
#
# (solmat + fd_solmat)[1:5, 1:5]
# (solmat + fd_solmat)[1:5, 6:11]
# (solmat + fd_solmat)[6:11, 1:5]
# (solmat + fd_solmat)[6:11, 6:11]
# (solmat + fd_solmat)[9:11, 9:11]



fd_sensi = finitediff_sensitivity(mech, data, δ = 1e-5, ϵr = 1e-14, ϵb = 1e-14) * attjac
@test norm(fd_sensi - sensi) / norm(fd_sensi) < 3e-3
plot(Gray.(sensi))
plot(Gray.(fd_sensi))

diagonal∂damper∂ʳvel(mech.joints[1],
offdiagonal∂damper∂ʳvel(jt0, x2b0, q2b0, x1b0, v1b0, q1b0, ω1b0, timestep0)
diagonal∂damper∂ʳvel(mech, mech.joints[1], mech.bodies[2])
offdiagonal∂damper∂ʳvel(mech.joints[1].constraints[1], mech.origin, mech.bodies[2], mech.bodies[2].id, mech.timestep)
offdiagonal∂damper∂ʳvel(mech.joints[1].constraints[2], mech.origin, mech.bodies[2], mech.bodies[2].id, mech.timestep)






################################################################################
################################################################################
################################################################################
################################################################################
################################################################################
################################################################################
# Solmat
################################################################################
################################################################################
################################################################################
################################################################################
################################################################################
################################################################################

################################################################################
# Damper Jacobian
################################################################################

include("fd_tools.jl")

j0 = mech.joints[1]
jt0 = j0.constraints[1]
jr0 = j0.constraints[2]
origin0 = mech.origin
pbody0 = mech.bodies[3]
cbody0 = mech.bodies[4]
childida0 = 3
childidb0 = 4
timestep0 = mech.timestep
damper_parent(jt0, pbody0, cbody0, childidb0)
damper_child(jt0, pbody0, cbody0, childidb0)
damper_child(jr0, origin0, pbody0, childida0)

x2a0, q2a0 = next_configuration(pbody0.state, timestep0)
x2b0, q2b0 = next_configuration(cbody0.state, timestep0)
x1a0, v1a0, q1a0, ω1a0 = current_configuration_velocity(pbody0.state)
x1b0, v1b0, q1b0, ω1b0 = current_configuration_velocity(cbody0.state)

Random.seed!(100)
x2a0 = rand(3)
q2a0 = UnitQuaternion(rand(4)...)
x2b0 = rand(3)
q2b0 = UnitQuaternion(rand(4)...)
x1a0 = rand(3)
v1a0 = rand(3)
q1a0 = UnitQuaternion(rand(4)...)
ω1a0 = rand(3)
x1b0 = rand(3)
v1b0 = rand(3)
q1b0 = UnitQuaternion(rand(4)...)
ω1b0 = rand(3)

# function der1(ω1a, q2a, ω1b, q2b)
#     invqbqa = q2b\q2a
#     A = nullspace_mask(jr0)
#     AᵀA = zerodimstaticadjoint(A) * A
#     return 2*VLmat(invqbqa)*RVᵀmat(invqbqa)* AᵀA * Diagonal(jr0.damper) * AᵀA
# end
#
# function der3(ω1a, q2a, ω1b, q2b)
#     A = I(3)
#     Aᵀ = A'
#     C = -2 * Aᵀ * A * Diagonal(jr0.damper) * Aᵀ * A
#     Δq = q2a \ q2b
#     Δqbar = q2b \ q2a
#     dF1 = C * VRᵀmat(Δq) * LVᵀmat(Δq)
#     dF2 = VRᵀmat(Δqbar) * LVᵀmat(Δqbar) * dF1
#     return dF2
# end
#
# function der4(ω1a, q2a, ω1b, q2b)
#     A = I(3)
#     Aᵀ = A'
#     function f(ω1b)
#         q2a_ = UnitQuaternion(q2a.w, q2a.x, q2a.y, q2a.z, false)
#         q2b_ = UnitQuaternion(q2b.w, q2b.x, q2b.y, q2b.z, false)
#         velocity = A * (vrotate(ω1b,q2a_\q2b_) - ω1a) # in pbody's frame
#         force = -2 * Aᵀ * A * Diagonal(jr0.damper) * Aᵀ * velocity
#         force = vrotate(force, q2b_ \ q2a_) # in cbody's frame
#         return force
#     end
#     ForwardDiff.jacobian(f, ω1b)
# end
#
# ω1a = rand(3)
# q2a = UnitQuaternion(rand(4)...)
# ω1b = rand(3)
# q2b = UnitQuaternion(rand(4)...)
# d1 = der1(ω1a, q2a, ω1b, q2b)
# d3 = der3(ω1a, q2a, ω1b, q2b)
# d4 = der4(ω1a, q2a, ω1b, q2b)
# norm(d4 - d3)
# norm(d4 - d1)

################################################################################
# Damper translation
################################################################################
jt0 = FixedOrientation(pbody0, cbody0; spring = 0.0, damper = 0.0)[1][1]
jt0.spring = 1e1 .* rand(3)[1]
jt0.damper = 1e1 .* rand(3)[1]

# jt0 = Planar(pbody0, cbody0, rand(3); spring = zeros(3), damper = zeros(3))[1][1]
# jt0.spring = 1e1 .* rand(3)
# jt0.damper = 1e1 .* rand(3)
#
# jt0 = Prismatic(pbody0, cbody0, rand(3); spring = zeros(3), damper = zeros(3))[1][1]
# jt0.spring = 1e1 .* rand(3)
# jt0.damper = 1e1 .* rand(3)
#
# jt0 = Fixed(pbody0, cbody0)[1][1]
# jt0.spring = 1e1 .* rand(3)
# jt0.damper = 1e1 .* rand(3)

damper_parent(jt0, x1a0, v1a0, q1a0, ω1a0, x1b0, v1b0, q1b0, ω1b0)
damper_child(jt0, x1a0, v1a0, q1a0, ω1a0, x1b0, v1b0, q1b0, ω1b0)
damper_child(jt0, x1b0, v1b0, q1b0, ω1b0)

Dtra1 = diagonal∂damper∂ʳvel(jt0)
Dtra2 = offdiagonal∂damper∂ʳvel(jt0, x1a0, q1a0, x1b0, q1b0)
Dtra3 = offdiagonal∂damper∂ʳvel(jt0, x1b0, q1b0)

fd_Dtra1 = fd_diagonal∂damper∂ʳvel(jt0, x1a0, v1a0, q1a0, ω1a0, x1b0, v1b0, q1b0, ω1b0)
fd_Dtra2 = fd_offdiagonal∂damper∂ʳvel(jt0, x1a0, v1a0, q1a0, ω1a0, x1b0, v1b0, q1b0, ω1b0)
fd_Dtra3 = fd_offdiagonal∂damper∂ʳvel(jt0, x1b0, v1b0, q1b0, ω1b0)

norm(Dtra1 - fd_Dtra1)
norm(Dtra2 - fd_Dtra2)
norm(Dtra3 - fd_Dtra3)

################################################################################
# Damper rotation
################################################################################
jr0 = Spherical(pbody0, cbody0, spring = zeros(3)[1], damper = zeros(3)[1])[2][1]
jr0.spring = 1e1 .* rand(3)[1]
jr0.damper = 1e1 .* rand(3)[1]

# # jr0 = Planar(pbody0, cbody0, rand(3); spring = zeros(3), damper = zeros(3))[1][1]
# # jr0.spring = 1e1 .* rand(3)
# # jr0.damper = 1e1 .* rand(3)
#
# jr0 = Revolute(pbody0, cbody0, rand(3))[2][1]
# jr0.spring = 1e1 .* rand(3)
# jr0.damper = 1e1 .* rand(3)
#
# jr0 = Fixed(pbody0, cbody0)[2][1]
# jr0.spring = 1e1 .* rand(3)
# jr0.damper = 1e1 .* rand(3)

damper_parent(jr0, x1a0, v1a0, q1a0, ω1a0, x1b0, v1b0, q1b0, ω1b0)
damper_child(jr0, x1a0, v1a0, q1a0, ω1a0, x1b0, v1b0, q1b0, ω1b0)
damper_child(jr0, x1b0, v1b0, q1b0, ω1b0)

Drot1 = diagonal∂damper∂ʳvel(jr0)
Drot2 = offdiagonal∂damper∂ʳvel(jr0, x1a0, q1a0, x1b0, q1b0)
Drot3 = offdiagonal∂damper∂ʳvel(jr0, x1b0, q1b0)

fd_Drot1 = fd_diagonal∂damper∂ʳvel(jr0, x1a0, v1a0, q1a0, ω1a0, x1b0, v1b0, q1b0, ω1b0)
fd_Drot2 = fd_offdiagonal∂damper∂ʳvel(jr0, x1a0, v1a0, q1a0, ω1a0, x1b0, v1b0, q1b0, ω1b0)
fd_Drot3 = fd_offdiagonal∂damper∂ʳvel(jr0, x1b0, v1b0, q1b0, ω1b0)

norm(Drot1 - fd_Drot1)
norm(Drot2 - fd_Drot2)
norm(Drot3 - fd_Drot3)

################################################################################
# Spring translation
################################################################################
jt0 = FixedOrientation(pbody0, cbody0; spring = zeros(3)[1], damper = zeros(3)[1])[1][1]
jt0.spring = 1e1 .* rand(3)[1]
jt0.damper = 1e1 .* rand(3)[1]

# jt0 = Planar(pbody0, cbody0, rand(3); spring = zeros(3), damper = zeros(3))[1][1]
# jt0.spring = 1e1 .* rand(3)
# jt0.damper = 1e1 .* rand(3)
#
# jt0 = Prismatic(pbody0, cbody0, rand(3); spring = zeros(3), damper = zeros(3))[1][1]
# jt0.spring = 1e1 .* rand(3)
# jt0.damper = 1e1 .* rand(3)
#
# jt0 = Fixed(pbody0, cbody0)[1][1]
# jt0.spring = 1e1 .* rand(3)
# jt0.damper = 1e1 .* rand(3)

spring_parent(jt0, x1a0, q1a0, x1b0, q1b0)
spring_child(jt0, x1a0, q1a0, x1b0, q1b0)
spring_child(jt0, x1b0, q1b0)

Dspr1 = diagonal∂spring∂ʳvel(jt0, x1a0, q1a0, x1b0, q1b0)
Dspr2 = offdiagonal∂spring∂ʳvel(jt0, x1a0, q1a0, x1b0, q1b0)
Dspr3 = offdiagonal∂spring∂ʳvel(jt0, x1b0, q1b0)

fd_Dspr1 = fd_diagonal∂spring∂ʳvel(jt0, x1a0, v1a0, q1a0, ω1a0, x1b0, v1b0, q1b0, ω1b0)
fd_Dspr2 = fd_offdiagonal∂spring∂ʳvel(jt0, x1a0, v1a0, q1a0, ω1a0, x1b0, v1b0, q1b0, ω1b0)
fd_Dspr3 = fd_offdiagonal∂spring∂ʳvel(jt0, x1b0, v1b0, q1b0, ω1b0)

norm(Dspr1 - fd_Dspr1)
norm(Dspr2 - fd_Dspr2)
norm(Dspr3 - fd_Dspr3)


################################################################################
# Spring Rotation
################################################################################
jr0 = Spherical(pbody0, cbody0, spring = zeros(3)[1], damper = zeros(3)[1])[2][1]
jr0.spring = 1e1 .* rand(3)[1]
jr0.damper = 1e1 .* rand(3)[1]

# jt0 = Planar(pbody0, cbody0, rand(3); spring = zeros(3), damper = zeros(3))[1][1]
# jt0.spring = 1e1 .* rand(3)
# jt0.damper = 1e1 .* rand(3)
#
# jt0 = Prismatic(pbody0, cbody0, rand(3); spring = zeros(3), damper = zeros(3))[1][1]
# jt0.spring = 1e1 .* rand(3)
# jt0.damper = 1e1 .* rand(3)
#
# jt0 = Fixed(pbody0, cbody0)[1][1]
# jt0.spring = 1e1 .* rand(3)
# jt0.damper = 1e1 .* rand(3)

spring_parent(jt0, x1a0, q1a0, x1b0, q1b0)
spring_child(jt0, x1a0, q1a0, x1b0, q1b0)
spring_child(jt0, x1b0, q1b0)

Dspr1 = diagonal∂spring∂ʳvel(jt0, x1a0, q1a0, x1b0, q1b0)
Dspr2 = offdiagonal∂spring∂ʳvel(jt0, x1a0, q1a0, x1b0, q1b0)
Dspr3 = offdiagonal∂spring∂ʳvel(jt0, x1b0, q1b0)

fd_Dspr1 = fd_diagonal∂spring∂ʳvel(jt0, x1a0, v1a0, q1a0, ω1a0, x1b0, v1b0, q1b0, ω1b0)
fd_Dspr2 = fd_offdiagonal∂spring∂ʳvel(jt0, x1a0, v1a0, q1a0, ω1a0, x1b0, v1b0, q1b0, ω1b0)
fd_Dspr3 = fd_offdiagonal∂spring∂ʳvel(jt0, x1b0, v1b0, q1b0, ω1b0)

norm(Dspr1 - fd_Dspr1)
norm(Dspr2 - fd_Dspr2)
norm(Dspr3 - fd_Dspr3)





################################################################################
################################################################################
################################################################################
################################################################################
################################################################################
################################################################################
# Datamat
################################################################################
################################################################################
################################################################################
################################################################################
################################################################################
################################################################################

################################################################################
# Damper translation
################################################################################
jt0 = FixedOrientation(pbody0, cbody0; spring = 0.0, damper = 0.0)[1][1]
jt0.spring = 1e1 .* rand(3)[1]
jt0.damper = 1e1 .* rand(3)[1]

# jt0 = Planar(pbody0, cbody0, rand(3); spring = zeros(3), damper = zeros(3))[1][1]
# jt0.spring = 1e1 .* rand(3)
# jt0.damper = 1e1 .* rand(3)
#
# jt0 = Prismatic(pbody0, cbody0, rand(3); spring = zeros(3), damper = zeros(3))[1][1]
# jt0.spring = 1e1 .* rand(3)
# jt0.damper = 1e1 .* rand(3)
#
# jt0 = Fixed(pbody0, cbody0)[1][1]
# jt0.spring = 1e1 .* rand(3)
# jt0.damper = 1e1 .* rand(3)

damper_parent(jt0, x1a0, v1a0, q1a0, ω1a0, x1b0, v1b0, q1b0, ω1b0)
damper_child(jt0, x1a0, v1a0, q1a0, ω1a0, x1b0, v1b0, q1b0, ω1b0)
damper_child(jt0, x1b0, v1b0, q1b0, ω1b0)

Dtra1 = data_diagonal∂damper∂ʳvel(jt0)
Dtra2 = data_offdiagonal∂damper∂ʳvel(jt0, x1a0, q1a0, x1b0, q1b0)
Dtra3 = data_offdiagonal∂damper∂ʳvel(jt0, x1b0, q1b0)

fd_Dtra1 = fd_diagonal∂damper∂ʳvel(jt0, x1a0, v1a0, q1a0, ω1a0, x1b0, v1b0, q1b0, ω1b0)
fd_Dtra2 = fd_offdiagonal∂damper∂ʳvel(jt0, x1a0, v1a0, q1a0, ω1a0, x1b0, v1b0, q1b0, ω1b0)
fd_Dtra3 = fd_offdiagonal∂damper∂ʳvel(jt0, x1b0, v1b0, q1b0, ω1b0)

norm(Dtra1 - fd_Dtra1)
norm(Dtra2 - fd_Dtra2)
norm(Dtra3 - fd_Dtra3)






@variables qav_[1:4], qbv_[1:4]
qa_ = Vector([qav_...])
qb_ = Vector([qbv_...])
qa = UnitQuaternion(qa_, false)
qb = UnitQuaternion(qb_, false)

Δq = qa \ qb
[Δq.w, Δq.x, Δq.y, Δq.z]


q0v = rand(4)
q0v ./= norm(q0v)
q1v = rand(4)
q1v ./= norm(q1v)
q0 = UnitQuaternion(q0v, false)
q1 = UnitQuaternion(q1v, false)
inv(q0)
invq0 = UnitQuaternion([q0v[1]; -q0v[2:4]], false)


Δq = q0 \ q1
[Δq.w, Δq.x, Δq.y, Δq.z] - Rmat(q1)' * q0v
