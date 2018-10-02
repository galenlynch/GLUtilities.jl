check_overlap(start1, stop1, start2, stop2) = (start1 <= stop2) & (start2 <= stop1)

function is_subinterval(startchild, stopchild, startparent, stopparent)
    (startchild >= startparent) & (stopchild <= stopparent)
end

function check_overlap(a::AbstractVector{<:NTuple{2, <:Any}})
    na = length(a)
    for i = 1:na, j = (i + 1):na
        if check_overlap(a[i][1], a[i][2], a[j][1], a[j][2])
            return true
        end
    end
    false
end

# Assumes sorted
function find_overlaps(a::AbstractVector{<:Tuple{<:Any, <:Any}})
    na = length(a)
    overlap_idx = Vector{Vector{Int}}(undef, na)
    @inbounds @simd for i = 1:na
        overlap_idx[i] = Vector{Int}()
    end
    @inbounds for i = 1:na
        thisstop = a[i][2]
        for j = (i + 1):na
            a[j][1] > thisstop && break
            push!(overlap_idx[i], j)
            push!(overlap_idx[j], i)
        end
    end
    overlap_idx
end

function interval_intersect(start1::T, stop1::T, start2::T, stop2::T) where T
    if check_overlap(start1, stop1, start2, stop2)
        res = T[max(start1, start2), min(stop1, stop2)]
    else
        res = T[]
    end
    res
end

measure(a::NTuple{2, <:Number}) = a[2] - a[1]

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

function clip_int(
    int_begin::Number, int_end::Number, bound_begin::Number, bound_end::Number
)
    (max(int_begin, bound_begin), min(int_end, bound_end))
end
function clip_int(input::NTuple{2, <:Number}, bounds::NTuple{2, <:Number})
    clip_int(input..., bounds...)
end

function join_intervals(
    ints::AbstractVector{<:NTuple{2, T}}, max_gap::Number,
) where T<:Number
    nint = length(ints)
    if nint == 0
        return Vector{NTuple{2, T}}()
    end
    ints_merged = Vector{NTuple{2, T}}(undef, nint)
    intno = 0
    joined_start = ints[1][1]
    last_end = ints[1][2]
    for int in ints
        if int[2] - last_end > max_gap
            intno += 1
            ints_merged[intno] = (joined_start, last_end)
            joined_start = int[1]
        end
        last_end = int[2]
    end
    resize!(ints_merged, intno)
    ints_merged
end

function interval_compliments(
    start::T,
    stop::T,
    intervals::AbstractVector{<:NTuple{2, T}},
    contraction::Number = 0
) where T
    nint = length(intervals)
    if nint == 0
        if stop - start > 2 * contraction
            return NTuple{2, T}[(start + contraction, stop - contraction)]
        else
            return Vector{NTuple{2, T}}()
        end
    end
    compliment = Vector{NTuple{2, T}}(undef, nint + 1)
    gapno = 0
    if intervals[1][1] - start > contraction
        gapno += 1
        compliment[gapno] = (
            start + contraction,
            intervals[1][1] - contraction
        )
    end
    for i in 1:(nint - 1)
        if intervals[i + 1][1] - intervals[i][2] > 2 * contraction
            gapno += 1
            compliment[gapno] = (
                intervals[i][2] + contraction,
                intervals[i + 1][1] - contraction
            )
        end
    end
    if stop - intervals[end][2] > contraction
        gapno += 1
        compliment[gapno] = (
            intervals[end][2] + contraction,
            stop - contraction
        )
    end
    resize!(compliment, gapno)
    compliment
end

function interval_compliments(
    start, stop, intervals::AbstractVector{<:NTuple{2, T}}, args...
) where T
    interval_compliments(convert(T, start), convert(T, stop), intervals, args...)
end

function mask_events(event_times::AbstractVector{<:Number}, start, stop)
    i_b, i_e = interval_indices(event_times, start, stop)
    view(event_times, i_b:i_e)
end

function interval_indices(
    basis::Union{<:AbstractVector, AbstractRange}, start, stop
)
    i_b = searchsortedfirst(basis, start)
    i_e = searchsortedlast(basis, stop)
    i_b, i_e
end
