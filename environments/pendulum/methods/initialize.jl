function get_pendulum(; 
    timestep=0.01, 
    gravity=-9.81, 
    masseed=1.0, 
    len=1.0,
    spring=0.0, 
    damper=0.0, 
    spring_offset=szeros(1), 
    axis_offset=one(UnitQuaternion),
    T=Float64)

    # Parameters
    joint_axis = [1.0; 0.0; 0.0]
    width, depth = 0.1, 0.1
    child_vertex = [0.0; 0.0; len / 2.0] # joint connection point

    # Links
    origin = Origin{T}()
    pbody = Box(width, depth, len, mass)

    # Constraints
    joint_between_origin_and_pbody = JointConstraint(Revolute(origin, pbody, joint_axis; 
        child_vertex=child_vertex, 
        spring=spring, 
        damper=damper, 
        rot_spring_offset=spring_offset,
        axis_offset=axis_offset))

    bodies = [pbody]
    joints = [joint_between_origin_and_pbody]

    mech = Mechanism(origin, bodies, joints, 
        gravity=gravity, 
        timestep=timestep, 
        spring=spring, 
        damper=damper)

    return mech
end

function initialize_pendulum!(mechanism::Mechanism; 
    ϕ1=0.7, 
    ω1=0.0) where T
    joint = mechanism.joints[1]
    set_minimal_coordinates_velocities!(mechanism, joint; 
        xmin=[ϕ1, ω1])
end

function get_npendulum(; 
    timestep=0.01, 
    gravity=-9.81, 
    masseed=1.0, 
    len=1.0,
    spring=0.0, 
    damper=0.0, 
    Nb=5,
    basetype=:Revolute, 
    joint_type=:Revolute,
    T=Float64) 

    # Parameters
    ex = [1.0; 0.0; 0.0]
    r = 0.05
    vert11 = [0.0; 0.0; len / 2.0]
    vert12 = -vert11

    # Links
    origin = Origin{T}()
    bodies = [Box(r, r, len, mass, color=RGBA(1.0, 0.0, 0.0)) for i = 1:Nb]

    # Constraints
    jointb1 = JointConstraint(Prototype(basetype, origin, bodies[1], ex; 
        child_vertex=vert11, 
        spring=spring, 
        damper=damper))
    if Nb > 1
        joints = [JointConstraint(Prototype(joint_type, bodies[i - 1], bodies[i], ex; 
            parent_vertex=vert12, 
            child_vertex=vert11, 
            spring=spring, 
            damper=damper)) for i = 2:Nb]
        joints = [jointb1; joints]
    else
        joints = [jointb1]
    end

    mech = Mechanism(origin, bodies, joints, 
        gravity=gravity, 
        timestep=timestep)
    return mech
end

function initialize_npendulum!(mechanism::Mechanism{T}; 
    ϕ1=π / 4.0, 
    ω=[0.0, 0.0, 0.0],
    Δv=[0.0, 0.0, 0.0], 
    Δω=[0.0, 0.0, 0.0]) where T

    pbody = mechanism.bodies[1]
    joint = mechanism.joints[1]
    vert11 = joint.translational.vertices[2]
    vert12 = -vert11

    # set position and velocities
    set_maximal_coordinates!(mechanism.origin, pbody, 
        child_vertex=vert11, 
        Δq=UnitQuaternion(RotX(ϕ1)))
    set_maximal_velocities!(pbody, 
        ω=ω)

    previd = pbody.id
    for (i,body) in enumerate(Iterators.drop(mechanism.bodies, 1))
        set_maximal_coordinates!(get_body(mechanism, previd), body, 
            parent_vertex=vert12, 
            child_vertex=vert11)
        set_maximal_velocities!(get_body(mechanism, previd), body, 
            parent_vertex=vert12, 
            child_vertex=vert11,
            Δv=Δv, Δω=1 / i * Δω)
        previd = body.id
    end
end
