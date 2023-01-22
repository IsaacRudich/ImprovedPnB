"""
    filter_out_arc_precedence_check(parent::T,child::T,model::U)where{T<:AllDiffFrameworkNode,U<:SequencingModel}
Check if an arc is removable using precedence

# Arguments
- `parent::T`: the parent node
- `child::T`: the child node
- `model::U`: the sequencing problem being evaluated
"""
function filter_out_arc_precedence_check(parent::T,child::T,model::U)where{T<:AllDiffFrameworkNode,U<:SequencingModel}
    if Base.haskey(getf2p(model),getstate(child))
        @inbounds for val in getf2p(model)[getstate(child)]
            if !getsomedown(parent)[val]
                return true
            end
        end
    end
    if Base.haskey(getp2f(model),getstate(child))
        @inbounds for val in getp2f(model)[getstate(child)]
            if !getsomeup(child)[val]
                return true
            end
        end
    end

    return false
end