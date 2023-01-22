abstract type SequencingModel<:ProblemModel end

#= required values: 
    objective -> <:ObjectiveFunction
    length -> Int
=#

"""
    order_by_lexigraphic(model::T) where{T<:SequencingModel}

Find a variable ordering for the model based on the order of the jobs in the problem definition
Return the variable ordering ::Vector{Int}

# Arguments
- `model::T`: the sequencing problem to be evaluated
"""
function order_by_lexigraphic(model::T) where{T<:SequencingModel}
    obj_type = valtype(model.objective.f.components)
    return Vector{obj_type}(1:length(model))
end

"""
    order_by_edge_weight(model::T) where{T<:SequencingModel}

Find a variable ordering for the model based on the distances between nodes
Return the variable ordering ::Vector{Int}

# Arguments
- `model::T`: the sequencing problem to be evaluated
"""
function order_by_edge_weight(model::T) where{T<:SequencingModel}
    #get objective values of the arcs
    obj_type = valtype(getobjective(model).f.components)
    objective_values = Dict{obj_type, Vector{obj_type}}()
    @inbounds for (key,value) in getobjective(model).f.components
        for i in 1:2
            if key[i] in keys(objective_values)
                push!(objective_values[key[i]], value)
            else
                objective_values[key[i]] = [value]
            end
        end
    end

    #get (and sort by) averages of objective values for each node
    averages = Dict{obj_type, Float64}()
    @inbounds for (key, value) in objective_values
        averages[key] = mean(value)
    end
    return sort(collect(keys(averages)), by=x->averages[x], rev=true)
end