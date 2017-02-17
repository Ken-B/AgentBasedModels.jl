module AgentBasedModels

export AgentBasedModel, simulate, state, Result, output

const DEFAULT_STEPS = 100 # default steps to run a model
#const DEFAULT_SEED  = 123


# Simulation Type
# ---------------

# The initialize function outputs an instance of type T. simulate! takes an instance of
# type T and performs one simulation step.
type AgentBasedModel{T}
    state::T
    initialize::Function
    simulate!::Function
    steps::Int
end
# TOOD is it possible to create a Simulation instance without having to run initialize?
function AgentBasedModel(initialize::Function, simulate::Function)
    state = initialize()
    T = typeof(state)
    AgentBasedModel{T}(state, initialize, simulate, 0)
end
Base.eltype{T}(abm::AgentBasedModel{T}) = T
Base.length(abm::AgentBasedModel) = abm.steps
Base.show(io::IO, abm::AgentBasedModel) = print(io, "Simulation with $(length(abm)) steps.")
state(abm::AgentBasedModel) = abm.state
plot(abm::AgentBasedModel; kwargs...) = plot(abm.state; kwargs...)

function init!(abm::AgentBasedModel; kwargs...)#seed = DEFAULT_SEED, kwargs...)
    #srand(seed)
    abm.state::eltype(abm) = abm.initialize(; kwargs...)
    abm.steps = 1
    return nothing
end

function step!(abm::AgentBasedModel; kwargs...)
    abm.simulate!(abm.state; kwargs...)::Nothing
    abm.steps += 1
    return nothing
end


# Result Type
# -----------

# The Result type holds the model, its parameters and output. It's basically a single run of
# a simulation. The init_output functio is run after the initializing the model. It outputs
# the initial output dictionary and takes the inital state T of the model as input.
# The output! function is run after each simulate! and takes in a Result{T} object.
# TODO: remove ugly U, V, W parameters
type Result{T, U<:Any, V<:Any, W<:Any}
    abm::AgentBasedModel{T}
    init_kwargs::Dict{Symbol, U}
    sim_kwargs::Dict{Symbol, V}
    output!::Function # saved for reproducability
    init_output::Function # saved for reproducability
    output::Dict{Symbol, W}
end
Base.getindex(r::Result, key::Symbol) = r.output[key]
Base.show(io::IO, r::Result) = print(io, "Results of a simuation with $(length(r.abm)) steps.")
Base.length(r::Result) = length(r.abm)
output(r::Result) = r.output
state(r::Result)  = state(r.abm)

# Function to run one single simulation
function simulate{T}(abm::AgentBasedModel{T};
                     init = true,
                     steps = DEFAULT_STEPS,
                     init_kwargs = Dict{Symbol, Any}(),
                     sim_kwargs = Dict{Symbol, Any}(),
                     output! = (r::Result{T}) -> nothing,
                     init_output = (t::T) -> Dict{Symbol, Any}())

    init && init!(abm; init_kwargs...)
    output::Dict{Symbol, Any} = init_output(abm.state)
    result = Result(abm, init_kwargs, sim_kwargs, output!, init_output, output)
    for step = 1:steps
        step!(abm; sim_kwargs...)
        output!(result)
    end
    return result
end




end #module
