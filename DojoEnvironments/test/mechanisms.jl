mechanisms = [
    :ant, 
    :atlas,
    :block, 
    :block2d,
    :cartpole,
    :dzhanibekov,
    :fourbar, 
    :halfcheetah,
    :hopper, 
    :humanoid,
    :npendulum,
    :nslider,
    :panda,
    :pendulum,
    :quadruped,
    :raiberthopper,
    :slider,
    :snake,
    :sphere,
    :tippetop,
    :twister, 
    :walker,
    :youbot,
]

for name in mechanisms 
    mech = get_mechanism(name) 
    initialize!(mech, name)
    simulate!(mech, 0.5; record=true)
    @test true
end
