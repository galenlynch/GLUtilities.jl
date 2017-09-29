clipind{T<:Integer}(ind::T, l::T) = min(max(ind, T(1)), l)
clipind(ind::Integer, l::Integer) = clipind(promote(ind, l)...)

ndx_to_x(i::Real, fs::Real, offset::Real = 0) = (i - 1) / fs + offset
ndx_to_x(r::Range, fs::Real, offset::Real = 0) = (r - 1) / fs + offset
ndx_to_x(A::AbstractArray, args...) = ndx_to_x.(A, args...)

x_to_ndx(x::Real, fs::Real, offset::Real = 0) = convert(Int, floor((x - offset) * fs) + 1)
x_to_ndx(A::AbstractArray, args...) = x_to_ndx.(A, args...)

n_ndx(start_idx::Integer, stop_idx::Integer) = stop_idx - start_idx + 1

n_points_duration(npoints::Integer, fs::Real) = (npoints - 1) / fs

function duration(npoints::Integer, fs::T, offset::T) where T<:AbstractFloat
    return (offset, offset + n_points_duration(npoints, fs))
end
function duration(n::Integer, fs::Real, offset::Real = 0)
    return duration(n, convert(Float64, fs), convert(Float64, offset))
end
duration(a::AbstractVector, args...) = duration(length(a), args...)

"""
    index_offset(start_idx, offset)

Finds the stop_idx that will select offset number of elements.

If offset is negative, then start_idx is treated like the stop_idx,
and the start_idx required to return offset number of elements is returned.
"""
function index_offset(start_idx::Integer, offset::Integer)
    # Negative input treats start_idx like stop_idx and finds corresponding start
    adjust = offset < 0 ? 1 : -1
    return start_idx + offset + adjust;
end

# Intended to work with binno as an integer or ranges
# though I can't figure out how to express that
function bin_bounds(binno, binsize::Integer)
    idx_start = (binno - 1) * binsize + 1
    idx_stop = idx_start + binsize - 1
    return (idx_start, idx_stop)
end
function bin_bounds(binno::Integer, binsize::Integer, maxind::Integer)
    bounds = bin_bounds(binno, binsize)
    clipped_bounds = min.(bounds, maxind)
    return clipped_bounds
end

bin_center(i::Integer, args...) = mean(bin_bounds(i, args...))
bin_center(rs::NTuple{2, R}) where R<:Range = (rs[1] + rs[2]) / 2
bin_center(r::Range, binsize::Integer) = bin_center(bin_bounds(r, binsize))
bin_center(a::A) where {S<:Integer, T<: NTuple{2, S}, A<:AbstractArray{T}} = mean.(a)
