getstart(model::T) where {T<:SequencingModel} = model.sequence_start
getend(model::T) where {T<:SequencingModel} = model.sequence_end

"""
    has_start(model::T)where{T<:SequencingModel}

Check if the sequence has a predefined start

# Arguments
- `model::T`: The problem model
"""
function has_start(model::T)where{T<:SequencingModel}
    return !isnothing(getstart(model))
end

"""
    has_end(model::T)where{T<:SequencingModel}

Check if the sequence has a predefined end

# Arguments
- `model::T`: The problem model
"""
function has_end(model::T)where{T<:SequencingModel}
    return !isnothing(getend(model))
end

"""
    imposestart!(domain::BitVector, visited::BitVector, model::T)where{T<:SequencingModel}

Removes start from domain and adds it to visited

# Arguments
- `domain::BitVector`: the domain to impose precedence on
- `model::T`: the model with precedence constraints
- `visited::BitVector`: the labels that have been visited
"""
function imposestart!(domain::BitVector, visited::BitVector, model::T)where{T<:SequencingModel}
    if has_start(model)
        visited[getstart(model)] = true
        domain[getstart(model)] = false
    end
end