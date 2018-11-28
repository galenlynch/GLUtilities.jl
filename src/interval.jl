check_overlap(start1, stop1, start2, stop2) = (start1 <= stop2) & (start2 <= stop1)

function check_overlap(tupa::NTuple{2, <:Number}, tupb::NTuple{2, <:Number})
    check_overlap(tupa[1], tupa[2], tupb[1], tupb[2])
end

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
        res = (max(start1, start2), min(stop1, stop2))
    else
        res = nothing
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

"""
    join_intervals!(ints::Vector{NTuple{2, <:Number}}, max_gap)

Join a list of sorted intervals, `ints`, if the gap between successive intervals
is less than `max_gap`. Mutates input in-place

Assumes ints are sorted by their first index.
"""
function join_intervals!(
    ints::AbstractVector{<:NTuple{2, <:Number}}, max_gap::Number,
)
    nint = length(ints)
    if nint == 0
        resize!(ints, 0)
        return ints
    end
    outno = 0
    joined_start = ints[1][1]
    last_end = ints[1][2]
    for intno in 2:nint
        int = ints[intno]
        if int[1] - last_end > max_gap
            # End last stretch
            outno += 1
            ints[outno] = (joined_start, last_end)
            joined_start = int[1]
        end
        last_end = int[2]
    end
    outno += 1
    ints[outno] = (joined_start, last_end)
    resize!(ints, outno)
    ints
end

"""
    join_intervals(ints::Vector{NTuple{2, <:Number}}, max_gap)

Like [`join_intervals!`](@ref), but does not mutate input.
"""
function join_intervals(ints::AbstractVector{<:NTuple{2, <:Number}}, max_gap)
    join_intervals!(copy(ints), max_gap)
end

function interval_complements(
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
    complement = Vector{NTuple{2, T}}(undef, nint + 1)
    gapno = 0
    if intervals[1][1] - start > contraction
        gapno += 1
        complement[gapno] = (
            start + contraction,
            intervals[1][1] - contraction
        )
    end
    for i in 1:(nint - 1)
        if intervals[i + 1][1] - intervals[i][2] > 2 * contraction
            gapno += 1
            complement[gapno] = (
                intervals[i][2] + contraction,
                intervals[i + 1][1] - contraction
            )
        end
    end
    if stop - intervals[end][2] > contraction
        gapno += 1
        complement[gapno] = (
            intervals[end][2] + contraction,
            stop - contraction
        )
    end
    resize!(complement, gapno)
    complement
end

function interval_complements(
    start, stop, intervals::AbstractVector{<:NTuple{2, T}}, args...
) where T
    interval_complements(convert(T, start), convert(T, stop), intervals, args...)
end

function mask_events(event_times::AbstractVector{<:Number}, start, stop)
    i_b, i_e = interval_indices(event_times, start, stop)
    view(event_times, i_b:i_e)
end

"""
    interval_indices(
        basis::Union{<:AbstractVector, AbstractRange}, start::Number, stop::Number
    ) -> i_b, i_e

Find the indices in `basis` that correspond to the interval specified by `start`
 and `stop`.
"""
function interval_indices(
    basis::Union{<:AbstractVector, AbstractRange}, start::Number, stop::Number
)
    i_b = searchsortedfirst(basis, start)
    i_e = searchsortedlast(basis, stop)
    i_b, i_e
end

function throttle(xs::AbstractVector{T}, min_gap::Number) where T<:Number
    nx = length(xs)
    out = Vector{NTuple{2, T}}(undef, nx)
    nx == 0 && return out
    @inbounds joined_start = xs[1]
    last_x = joined_start
    nout = 0
    @inbounds for i in 2:nx
        x = xs[i]
        if x - last_x > min_gap
            nout += 1
            out[nout] = (joined_start, last_x)
            joined_start = x
        end
        last_x = x
    end
    nout += 1
    @inbounds out[nout] = (joined_start, last_x)
    resize!(out, nout)
    out
end

in(reg::NTuple{2, <:Number}, x::Number) = (x >= reg[1]) & (x <= reg[2])
