"Converts an index to its time in a regularly sampled time series"
function ndx_to_t end
ndx_to_t(i::Real, fs::Real, start_t::Real = zero(fs)) = (i - 1) / fs + start_t
# Can't figure out how to express either an integer or rage, so duplicating the function
ndx_to_t(r::Range, fs::Real, start_t::Real = zero(fs)) = (r - 1) / fs + start_t
ndx_to_t(A::AbstractArray, args...) = ndx_to_t.(A, args...)

"Converts a time in a regularly sampled time series to its index"
function t_to_ndx end
t_to_ndx(x::Real, fs::Real, start_t::Real = zero(fs)) = convert(Int, floor((x - start_t) * fs) + 1)
t_to_ndx(A::AbstractArray, args...) = t_to_ndx.(A, args...)

"Clips an index to be within the valid range for an array of length l"
function clip_ndx end
clip_ndx(ind::T, l::T) where T<:Integer = min(max(ind, T(1)), l)
clip_ndx(ind::Integer, l::Integer) = clip_ndx(promote(ind, l)...)

n_ndx(start_idx::Integer, stop_idx::Integer) = stop_idx - start_idx + 1

"""
    ndx_offset(start_ndx, npt)

Finds the index that will select npt number of elements starting at start_ndx.

If npt is negative, then start_ndx is treated like the end of a range of elements,
and the index required to return npt number of elements is returned.
"""
function ndx_offset(start_ndx::Integer, npt::Integer)
    adjust = npt < 0 ? 1 : -1
    return start_ndx + npt + adjust;
end

n_points_duration(npoints::Integer, fs::Real) = (npoints - 1) / fs

"Find the duration of a regularly sampled time series"
function duration end
function duration(npoints::Integer, fs::T, start_t::T) where T<:AbstractFloat
    return (start_t, start_t + n_points_duration(npoints, fs))
end
function duration(n::Integer, fs::Real, start_t::Real = zero(fs))
    return duration(n, convert(Float64, fs), convert(Float64, start_t))
end
duration(a::AbstractVector, args...) = duration(length(a), args...)

"Find the indices to select all points in a bin"
function bin_bounds end
# Intended to work with binno as an integer or ranges
# though I can't figure out how to express that
function bin_bounds(binno, binsize::Integer)
    idx_start = (binno - 1) * binsize + 1
    idx_stop = idx_start + binsize - 1
    return (idx_start, idx_stop)
end
function bin_bounds(binno::Integer, binsize::Integer, max_ndx::Integer)
    bounds = bin_bounds(binno, binsize)
    clipped_bounds = min.(bounds, max_ndx)
    return clipped_bounds
end

"Find the center index of a bin"
function bin_center end
bin_center(i::Integer, args...) = mean(bin_bounds(i, args...))
bin_center(rs::NTuple{2, R}) where R<:Range = (rs[1] + rs[2]) / 2
bin_center(r::Range, binsize::Integer) = bin_center(bin_bounds(r, binsize))
bin_center(a::A) where {S<:Integer, T<: NTuple{2, S}, A<:AbstractArray{T}} = mean.(a)
