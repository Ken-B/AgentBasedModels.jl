module AgentBasedModels

using Interact, Reactive

FPS_RATE = 60 # TODO fix fps_slider input

export Simulation, create_signal, run_button, reset_button

# The initialize function outputs an instance of type T. Simulation! takes an instance of
# type T and performs one simulation step.
# A dictionary holds dynamic output and/or display values.
type Simulation{T}
    state::T
    initialize::Function
    simulate!::Function
    kwargs::Dict{Symbol, Any}
    history::Dict{Symbol, Any}
    steps::Int
end



# TOOD is it possible to create a Simulation instance without having to run initialize?
function Simulation(initialize::Function, simulate::Function)
    state = initialize()
    T = typeof(state)
    Simulation{T}(state, initialize, simulate, Dict{Symbol, Any}(), Dict{Symbol, Any}(), 0)
end
Base.eltype{T}(s::Simulation{T}) = T
Base.length(s::Simulation) = s.steps
Base.getindex(s::Simulation, key::Symbol) = s.history[key]

Base.show(io::IO, s::Simulation) = print(io, "Simuation with $(length(s)) steps.")

plot(s::Simulation; kwargs...) = plot(s.state; kwargs...)

# TODO find better way to collect keyword arguments (kwargs)
init_output!(s::Simulation; kwargs...) = nothing

function init!(s::Simulation; kw=Dict{Symbol,Any}())
    empty!(s.history)
    empty!(s.kwargs)
    haskey(kw, :seed) || setindex!(kw, 123, :seed)
    srand(kw[:seed])
    s.kwargs = kw
    s.state::eltype(s) = s.initialize(; kw...)
    init_output!(s; kw...)
    s.steps = 1
    return nothing
end
#init(s::Simulation; kwargs...) = (init!(s; kwargs...); s)

output!{T}(s::Simulation{T}; kwargs...) = nothing
function simulate!(s::Simulation)
    s.simulate!(s.state; s.kwargs...)::Nothing
    output!(s; s.kwargs...)
    s.steps += 1
    return nothing
end
#simulate(s::Simulation, kwargs...) = (simulate!(s, kwargs...); s)

# Stepping Widgets
# ----------------

# TODO put these in a type (or smth) instead of global namespace
run_button = togglebutton("▶ Run")
run_sig = keepwhen(signal(run_button), 0, fps(FPS_RATE))
reset_button = button("initialize", value = :reset)
step_sig = merge(run_sig, signal(reset_button))

# max_steps_slider = slider(10:10:200, value = 150, label = "maximum simulation steps")
# max_steps = signal(max_steps_slider)

# Simulation signals
# ------------------

# TODO find solution for init_kwargs and sim_kwargs in global (module) scope
sim_kwargs  = Dict{Symbol, Any}()

function create_signal(s::Simulation)
    sig = foldl((sim, val) -> begin
        if val == :reset
            init!(sim)
            return(sim)
        end
        # s.steps < max_steps && simulate!(sim)
        simulate!(sim)
        output!(sim)::Nothing
        sim
    end, s, step_sig)
end

end #module
