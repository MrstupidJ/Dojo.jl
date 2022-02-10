abstract type Contact{T,N} end

getT(model::Contact{T}) where T = T
Base.length(model::Contact{T,N}) where {T,N} = N

constraint(model::Contact, body::Body, λ, timestep) = constraint(model, next_configuration(body.state, timestep)..., λ)

constraint_jacobian_velocity(model::Contact, body::Body, id, λ, timestep) = constraint_jacobian_velocity(model, next_configuration(body.state, timestep)..., current_configuration_velocity(body.state)..., λ, timestep)
constraint_jacobian_configuration(model::Contact, body::Body, id, λ, timestep) = constraint_jacobian_configuration(model, next_configuration(body.state, timestep)..., current_configuration_velocity(body.state)..., λ, timestep)

impulse_map(model::Contact, body::Body, id, λ, timestep) = impulse_map(model, next_configuration(body.state, timestep)..., λ)

complementarity(mechanism, contact::ContactConstraint; scaling=false) = contact.impulses_dual[2] .* contact.impulses[2]
complementarityμ(mechanism, contact::ContactConstraint; scaling=false) = complementarity(mechanism, contact, scaling=scaling) - mechanism.μ * neutral_vector(contact.model)

neutral_vector(model::Contact{T,N}) where {T,N} = sones(T, Int(N/2))

cone_degree(model::Contact{T,N}) where {T,N} = Int(N/2)
