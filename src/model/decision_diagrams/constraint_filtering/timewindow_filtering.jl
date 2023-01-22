#requires nodes to have latest_start_time

"""
    filter_out_arc_timewindow_check(parent::T,child::T,model::U)where{T<:AllDiffFrameworkNode,U<:SequencingModel}
Check if an arc is removable using timewindows

# Arguments
- `parent::T`: the parent node
- `child::T`: the child node
- `model::U`: the sequencing problem being evaluated
"""
function filter_out_arc_timewindow_check(parent::T,child::V,model::U)where{T<:AllDiffFrameworkNode,V<:AllDiffFrameworkNode,U<:SequencingModel}
    if max(
        getreleasetimes(model)[getstate(child)],
        getlengthtoroot(parent) + evaluate_decision(model,getstate(parent), getstate(child))
    ) > (get_lst(child))
        return true
    end
    
    return false
end