module AgentBasedModels

using Interact, Reactive

export Simulation, create_signal

FPS_RATE = 3 # TODO fix fps_slider input

# TODO new simulation type that does not store history (and does not allow slide back)

# The initialize function outputs an instance of type T. Simulation takes an instance of
# type T and outputs an instance of type T, basically one simulation step.
# This Simulation type keeps all previous steps (history) in memory.
type Simulation{T}
    state::T
    initialize::Function
    init_kwargs::Dict{Symbol, Any}
    simulate::Function
    history::Vector{T}
    history_kwargs::Vector{Dict{Symbol, Any}}
end
# TOOD is it possible to create a Simulation instance without having to run initialize?
function Simulation(initialize::Function, simulate::Function)
    state = initialize()
    T = typeof(state)
    Simulation{T}(state, initialize, Dict{Symbol, Any}(), simulate, T[], Dict{Symbol, Any}[])
end
Base.eltype{T}(s::Simulation{T}) = T
Base.length(s::Simulation) = length(s.history)
Base.getindex(s::Simulation, i::Int) = s.history[i]

# Base.setindex{T}(s::Simulation{T}, v::T, i::Int) = throw(MethodError())
# Base.size(s::Simulation) = (length(s.history), )
# define showarray method, otherwise default AbstractArray method
# Base.ndims(Simulation) = 1
# Base.showarray(io::IO, s::Simulation) = show(io, s)
Base.show(io::IO, s::Simulation) = print(io, "Simuation with $(length(s)) steps.")

# plot(s::Simulation; kwargs...) = plot(s.history; kwargs...)
# plot(s::Simulation, kind::Symbol; kwargs...) = plot(s.history, kind; kwargs...)

# TODO find better way to collect keyword arguments (kwargs)
function init!(s::Simulation; kw=Dict{Symbol,Any}())
    empty!(s.history)
    empty!(s.history_kwargs)
    s.init_kwargs = kw
    state::eltype(s) = s.initialize(; kw...)
    push!(s.history, deepcopy(state))
    return nothing
end
init(s::Simulation; kwargs...) = (init!(s; kwargs...); s)

function simulate!(s::Simulation; kw=Dict{Symbol,Any}())
    push!(s.history_kwargs, kw)
    state::eltype(s) = s.simulate(s.state; kw...)
    push!(s.history, deepcopy(state))
    return nothing
end
simulate(s::Simulation, kwargs...) = (simulate!(s, kwargs...); s)

# Stepping Widgets
# ----------------

# TODO put these in a type (or smth) instead of global namespace
# The run signal increases the step signal through the step button (1 per click) or the run
# button (continuously). The step signal can be reset through the run signal with :reset
# value.
run_button  = togglebutton("▶ Run")
reset_button= button("initialize", value = :reset)
step_button = button("step")
# fps_slider  = slider(1:10.0, label = "steps per second")
# fps_sig     = lift(fps, fps_slider)
# step_fps    = lift(sig->keepwhen(signal(run_button), 0.0, sig), fps_sig)
just_fps    = fps(FPS_RATE)
step_fps    = keepwhen(signal(run_button), 0, just_fps)
run_sig     = merge(step_fps, signal(step_button), signal(reset_button))

# A slider based on the accumulator signal keeps track of the simulation steps for maximum
# value and automatic updating. The slider signal can be used later to slide back to
# a previous step in history.
step_sig    = foldl((acc, val) -> val == :reset ? 1 : acc + 1, 1, run_sig)
step_slider = @lift slider(1:step_sig, value = signal(step_sig), label = "simulation step")

# To slide back to a previous simulation step, this accumulation function tracks a tuple of
# both the total simulation steps in step_sig (`acc`) as well as the signal from the slider
# bar (`sig`).
function acc_hist(sig_acc, val)
    sig, acc = sig_acc
    # TODO make slider detection more robust by using designated type (or smth)
    if isa(val, Int) #manual slider case
        return (val, acc)
    elseif val == :reset
        return (1, 1)
    end
    return (acc + 1, acc + 1)
end
hist_acc = foldl(acc_hist, (1,1), merge(run_sig, step_slider.value.signal))
hist_sig = @lift hist_acc[1]


# Simulation signals
# ------------------
# TODO find solution for init_kwargs and sim_kwargs in global (module) scope
init_kwargs = Dict{Symbol, Any}()
sim_kwargs  = Dict{Symbol, Any}()

# create_signal(s::Simulation) = foldl((sim, val) -> begin
#         val == :reset && return(init(s; kw=init_kwargs))
#         simulate(sim; kw=sim_kwargs)
#     end, init(s; kw=init_kwargs), run_sig)
create_signal(s::Simulation) = foldl((sim, val) -> begin
        val == :reset && return(init(s))
        simulate(sim)
    end, init(s), run_sig)

end # module
