check_overlap(start1, stop1, start2, stop2) = start1 <= stop2 && start2 <= stop1

function interval_intersect(start1::T, stop1::T, start2::T, stop2::T) where T
    if check_overlap(start1, stop1, start2, stop2)
        res = T[max(start1, start2), min(stop1, stop2)]
    else
        res = T[]
    end
    res
end

function reduce_extrema(s1::T, s2::T, t1::T, t2::T) where T<:Number
    return (min(s1, t1), max(s2, t2))
end
function reduce_extrema(s::NTuple{2, T}, t::NTuple{2, T}) where T<:Number
    return reduce_extrema(s..., t...)
end

extrema_red(a::AbstractVector{<:Number}) = extrema(a)

function extrema_red(a::AbstractArray{<:Number, 2})
    na = size(a, 2)
    na > 0 || throw(ArgumentError("Collection must not be empty"))
    size(a, 1) == 2 || throw(ArgumentError("First dimension must be size 2"))
    cmin = a[1, 1]
    cmax = a[2, 1]
    for i in 2:na
        cmin = min(cmin, a[1, i])
        cmax = max(cmax, a[2, i])
    end
    return (cmin, cmax)
end

function extrema_red(a::A) where {T<:NTuple{2, Number}, A<:AbstractVector{T}}
    na = length(a)
    na > 0 || throw(ArgumentError("Collection must not be empty"))
    cmin = a[1][1]
    cmax = a[1][2]
    for i in 2:na
        cmin = min(cmin, a[i][1])
        cmax = max(cmax, a[i][2])
    end
    return (cmin, cmax)
end
