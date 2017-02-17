using AgentBasedModels
using Base.Test


# Mock simulation model
type Foo
    bar::Int
end
init(; start=1, kwargs...) = Foo(start)
step!(s::Foo; kwargs...) = (s.bar += 2; nothing)


model = AgentBasedModel(init, step!)
AgentBasedModels.init!(model)
AgentBasedModels.step!(model)
@test isa(state(model), Foo)
@test state(model).bar == 3

init_kwargs = [:start=>2]
simulate(model, steps=200, init_kwargs = init_kwargs)
@test state(model).bar == 402

init_output(f::Foo) = [:start => f.bar, :bar => Int[f.bar]]
output!(r::Result{Foo}) = push!(r.output[:bar], r.abm.state.bar)
res = simulate(model; steps=10, init_kwargs=init_kwargs, init_output=init_output, output! = output!)
@test res.output[:bar] == [2:2:22;]
