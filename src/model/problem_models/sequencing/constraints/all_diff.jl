"""
    check_all_diff_validity(seq::Vector{Int})

Check if a solution satisfies an all different constraint

# Arguments
- `seq::Vector{Int}`: The sequence to check
"""
function check_all_diff_validity(seq::Vector{Int})
    used = falses(length(seq))
    @inbounds for e in seq
        if used[e]
            return false
        else
            used[e] = true
        end
    end
    return true
end