"Converts an index to its time in a regularly sampled time series"
function ndx_to_t end
function ndx_to_t(
    i::AbstractUnitRange, fs::R, start_t::R = zero(fs)
) where {R<:Real}
    (i - 1) / fs + start_t
end
function ndx_to_t(
    i::AbstractUnitRange, fs::R, start_t::R = zero(fs)
) where R<:Integer
    (i - 1) / fs + start_t
end
function ndx_to_t(i::Real, fs::R, start_t::R = zero(fs)) where {R<:Real}
    (i - 1) / fs + start_t
end
function ndx_to_t!(
    dest::AbstractArray,
    A::AbstractArray,
    fs,
    args...
)
    dest .= ndx_to_t.(A, fs, args...)
end
function ndx_to_t(
    A::AbstractArray,
    fs::R,
    start_t::R = zero(fs)
) where {R<:Integer}
    ts = Vector{Float64}(length(A))
    ndx_to_t!(ts, A, fs, start_t)
end
function ndx_to_t(
    A::AbstractArray{R, <:Any}, fs::R, start_t::R = zero(fs)
) where {R<:AbstractFloat}
    ts = Vector{R}(length(A))
    ndx_to_t!(ts, A, fs, start_t)
end
function ndx_to_t(
    a::AbstractArray{T, <:Any}, fs::R, start_t::S
) where {T, R<:Real, S<:Real}
    P = promote_type(T,R,S)
    promoted = convert.(P, (fs, start_t))
    return ndx_to_t(a, promoted...)
end
function ndx_to_t(i::Real, fs::Real, start_t::Real)
    return ndx_to_t(promote(i, fs, start_t)...)
end


"Converts a time in a regularly sampled time series to its index"
function t_to_ndx end
function t_to_ndx(x::Real, fs::Real, start_t::Real = zero(fs), T::DataType = Int)
    convert(T, floor((x - start_t) * fs) + one(T))
end
function t_to_ndx!(dest::AbstractArray, A::AbstractArray, args...)
    dest .= t_to_ndx.(A, args...)
end
function t_to_ndx(a::AbstractArray, fs, start_t = zero(fs), T::DataType = Int)
    dest = similar(a, T)
    t_to_ndx!(dest, a, fs, start_t)
end

"Clips an index to be within the valid range for an array of length l"
function clip_ndx end
clip_ndx(ind::T, l::T) where T<:Integer = min(max(ind, one(T)), l)
clip_ndx(ind::Integer, l::Integer) = clip_ndx(promote(ind, l)...)

n_ndx(start_idx::T, stop_idx::T) where {T<:Integer} = stop_idx - start_idx + one(T)

"""
    ndx_offset(start_ndx, npt)

Finds the index that will select npt number of elements starting at start_ndx.

If npt is negative, then start_ndx is treated like the end of a range of elements,
and the index required to return npt number of elements is returned.
"""
function ndx_offset(start_ndx::T, npt::T) where {T<:Integer}
    adjust = npt < zero(T) ? one(T) : -one(T)
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
function bin_bounds(binno::Union{AbstractUnitRange{T}, T}, binsize::S) where
    {T<:Integer, S<:Integer}
    R = promote_type(T,S)
    idx_start = (binno - one(R)) * binsize + one(R)
    idx_stop = idx_start + binsize - one(R)
    return (idx_start, idx_stop)
end
function bin_bounds(binno::Real, binsize::Real, max_ndx::Real)
    bounds = bin_bounds(binno, binsize)
    clipped_bounds = min.(bounds, max_ndx)
    return clipped_bounds
end

"Find the center index of a bin"
function bin_center end
bin_center(idxs::NTuple{2, <:Real}) = mean(idxs)
bin_center(i::Real, args...) = bin_center(bin_bounds(i, args...))
bin_center(rs::NTuple{2, R}) where R<:Range = (rs[1] + rs[2]) / 2
bin_center(r::Range, binsize::Real) = bin_center(bin_bounds(r, binsize))
function bin_center!(
    dest::AbstractArray{<:AbstractFloat, <:Any},
    a::AbstractArray{<:NTuple{2, <:Real}}
)
    dest .= bin_center.(a)
end
function bin_center(a::AbstractArray{<:NTuple{2, F}, <:Any}) where {F<:AbstractFloat}
    dest = similar(a, F)
    bin_center!(dest, a)
end
function bin_center(a::AbstractArray{<:NTuple{2, <:Integer}, <:Any})
    dest = similar(a, Float64)
    bin_center!(dest, a)
end
