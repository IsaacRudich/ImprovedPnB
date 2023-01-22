abstract type ProblemModel end

#= required values: 
    objective -> <:ObjectiveFunction
    length -> Int
=#

Base.length(model::T) where {T<:ProblemModel} = model.length
getobjective(model::T) where {T<:ProblemModel} = model.objective
getobjectivetype(model::T) where {T<:ProblemModel} = gettype(getobjective(model))
evaluate_decision(model::T,num1::Int, num2::Int) where {T<:ProblemModel} = evaluate_decision(getobjective(model), num1, num2)
function acquire_heuristic_packet(model::T)where{T<:ProblemModel} return nothing end

"""
    is_better_solution_value(model::T, new_value::U, best_known_value::U)where{T<:ProblemModel, U<:Real}

Check if a solution value is better than the best known value

# Arguments
- `model::T`: The problem model
- `new_value::U`: the value that might be better
- `best_known_value::V`: the the value being compared against
"""
function is_better_solution_value(model::T, new_value::U, best_known_value::V)where{T<:ProblemModel, U<:Real,V<:Real}
    if getobjectivetype(model) == minimization
        return new_value<best_known_value
    elseif getobjectivetype(model) == maximization
        return new_value>best_known_value
    end
end

"""
    is_better_solution_value(model::T, new_value::U, best_known_value::Nothing)where{T<:ProblemModel, U<:Real}

Check if a solution value is better than the best known value

# Arguments
- `model::T`: The problem model
- `new_value::U`: the value that might be better
- `best_known_value::Nothing`: the the value being compared against
"""
function is_better_solution_value(model::T, new_value::U, best_known_value::Nothing)where{T<:ProblemModel, U<:Real}
    return true
end

"""
    is_better_solution_value(model::T, new_value::Nothing, best_known_value::V)where{T<:ProblemModel,V<:Real}

Catch function that may be called if the solver has not yet found a solution by the time peel and bound starts

# Arguments
- `model::T`: The problem model
- `new_value::Nothing`: the value that might be better
- `best_known_value::V`: the the value being compared against
"""
function is_better_solution_value(model::T, new_value::Nothing, best_known_value::V)where{T<:ProblemModel,V<:Real}
    return false
end

"""
    is_better_solution_value(model::T, new_value::Nothing, best_known_value::Nothing)where{T<:ProblemModel, U<:Real}

Catch function that may be called if the solver has not yet found a solution by the time peel and bound starts

# Arguments
- `model::T`: The problem model
- `new_value::Nothing`: the value that might be better
- `best_known_value::Nothing`: the the value being compared against
"""
function is_better_solution_value(model::T, new_value::Nothing, best_known_value::Nothing)where{T<:ProblemModel}
    return false
end

