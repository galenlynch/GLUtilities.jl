check_overlap(start1, stop1, start2, stop2) = start1 <= stop2 && start2 <= stop1

function reduce_extrema(s1::T, s2::T, t1::T, t2::T) where T<:Number
    return (min(s1, t1), max(s2, t2))
end
function reduce_extrema(s::NTuple{2, T}, t::NTuple{2, T}) where T<:Number
    return reduce_extrema(s..., t...)
end
