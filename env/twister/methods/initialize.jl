function get_twister(; timestep::T=0.01, gravity=[0.0; 0.0; -9.81], friction_coefficient::T=0.8, contact::Bool=true,
    contact_type=:nonlinear, spring=0.0, damper=0.0, Nb::Int=5,
    jointtype::Symbol=:Prismatic, h::T=1.0, r::T=0.05) where T
    # Parameters
    ex = [1.;0.;0.]
    ey = [0.;1.;0.]
    ez = [0.;0.;1.]
    axes = [ex, ey, ez]

    vert11 = [0.;0.;h / 2]
    vert12 = -vert11
    vert = h/2

    # Links
    origin = Origin{T}()
    bodies = [Box(3r, 2r, h, h, color = RGBA(1., 0., 0.)) for i = 1:Nb]

    # Constraints
    jointb1 = JointConstraint(Floating(origin, bodies[1], spring = 0.0, damper = 0.0)) # TODO remove the spring and damper from floating base
    if Nb > 1
        joints = [JointConstraint(Prototype(jointtype, bodies[i - 1], bodies[i], axes[i%3+1]; parent_vertex = vert12, child_vertex = vert11, spring=spring, damper=damper)) for i = 2:Nb]
        # joints = [JointConstraint(Prototype(jointtype, bodies[i - 1], bodies[i], axes[1]; parent_vertex = vert12, child_vertex = vert11, spring=spring, damper=damper)) for i = 2:Nb]
        # joints = [JointConstraint(Prototype(jointtype, bodies[i - 1], bodies[i], axes[3]; parent_vertex = vert12, child_vertex = vert11, spring=spring, damper=damper)) for i = 2:Nb]
        joints = [jointb1; joints]
    else
        joints = [jointb1]
    end

    if contact
        n = Nb
        normal = [[0;0;1.0] for i = 1:n]
        friction_coefficient = friction_coefficient * ones(n)
        contacts1 = contact_constraint(bodies[1], normal[1], friction_coefficient=friction_coefficient[1], contact_point=vert11, contact_type=contact_type) # to avoid duplicating the contact points
        contacts2 = contact_constraint(bodies, normal, friction_coefficient=friction_coefficient, contact_points=fill(vert12, n), contact_type=contact_type)
        mech = Mechanism(origin, bodies, joints, [contacts1; contacts2], gravity=gravity, timestep=timestep)
    else
        mech = Mechanism(origin, bodies, joints, gravity=gravity, timestep=timestep, spring=spring, damper=damper)
    end
    return mech
end

function initialize_twister!(mechanism::Mechanism{T,Nn,Ne,Nb}; x::AbstractVector{T}=[0,-1.,0],
    v::AbstractVector{T}=zeros(3), ω::AbstractVector{T}=zeros(3),
    Δω::AbstractVector{T}=zeros(3), Δv::AbstractVector{T}=zeros(3),
    q1::UnitQuaternion{T}=UnitQuaternion(RotX(0.6 * π))) where {T,Nn,Ne,Nb}

    bodies = collect(mechanism.bodies)
    pbody = bodies[1]
    h = 1.0
    vert11 = [0.;0.; h/2]
    vert12 = -vert11
    # set position and velocities
    set_maximal_configuration!(mechanism.origin, pbody, child_vertex = x, Δq = q1)
    set_maximal_velocity!(pbody, v = v, ω = ω)

    previd = pbody.id
    for (i,body) in enumerate(Iterators.drop(mechanism.bodies, 1))
        set_maximal_configuration!(get_body(mechanism, previd), body, parent_vertex = vert12, child_vertex = vert11)
        set_maximal_velocity!(get_body(mechanism, previd), body, parent_vertex = vert12, child_vertex = vert11,
                Δv = Δv, Δω = Δω)
        previd = body.id
    end
end
