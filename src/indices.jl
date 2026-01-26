"""
    ndx_to_t(i, fs, start_t)

Converts an index to its time in a regularly sampled time series.
"""
function ndx_to_t end
function ndx_to_t(
        i::AbstractUnitRange, fs::R, start_t::R = zero(fs)
    ) where {R <: Real}
    return @static if VERSION < v"0.7.0-DEV.2005"
        (i - 1) / fs + start_t
    else
        (i .- 1) ./ fs .+ start_t
    end
end
function ndx_to_t(
        i::AbstractUnitRange, fs::R, start_t::R = zero(fs)
    ) where {R <: Integer}
    return @static if VERSION < v"0.7.0-DEV.2005"
        (i - 1) / fs + start_t
    else
        (i .- 1) ./ fs .+ start_t
    end
end
function ndx_to_t(i::Real, fs::R, start_t::R = zero(fs)) where {R <: Real}
    return (i - 1) / fs + start_t
end
function ndx_to_t!(
        dest::AbstractArray,
        A::AbstractArray,
        fs,
        args...
    )
    return dest .= ndx_to_t.(A, fs, args...)
end
function ndx_to_t(
        A::AbstractArray,
        fs::R,
        start_t::R = zero(fs)
    ) where {R <: Integer}
    @compat ts = Vector{Float64}(undef, length(A))
    return ndx_to_t!(ts, A, fs, start_t)
end
function ndx_to_t(
        A::AbstractArray{R, <:Any}, fs::R, start_t::R = zero(fs)
    ) where {R <: AbstractFloat}
    @compat ts = Vector{R}(undef, length(A))
    return ndx_to_t!(ts, A, fs, start_t)
end
function ndx_to_t(
        a::AbstractArray{T, <:Any}, fs::R, start_t::S
    ) where {T, R <: Real, S <: Real}
    P = promote_type(T, R, S)
    promoted = convert.(P, (fs, start_t))
    return ndx_to_t(a, promoted...)
end
function ndx_to_t(i::Real, fs::Real, start_t::Real)
    return ndx_to_t(promote(i, fs, start_t)...)
end


"""
    t_to_ndx()

Converts a time in a regularly sampled time series to its index. Returns the
index of the first sample at or after the time specified

"""
function t_to_ndx end
function t_to_ndx(
        x::Real, fs::Real, start_t::Real = zero(fs), T::DataType = Int
    )
    return ceil(T, (x - start_t) * fs) + one(T)
end
function t_to_ndx!(dest::AbstractArray, A::AbstractArray, args...)
    return dest .= t_to_ndx.(A, args...)
end
function t_to_ndx(a::AbstractArray, fs, start_t = zero(fs), T::DataType = Int)
    dest = similar(a, T)
    return t_to_ndx!(dest, a, fs, start_t)
end

"Like t_to_ndx, but returns sample at or before time"
function t_to_last_ndx(
        x::Real, fs::Real, start_t::Real = zero(fs), T::DataType = Int
    )
    return floor(T, (x - start_t) * fs) + one(T)
end
function t_to_last_ndx!(dest::AbstractArray, A::AbstractArray, args...)
    return dest .= t_to_last_ndx.(A, args...)
end
function t_to_last_ndx(a::AbstractArray, fs, start_t = zero(fs), T::DataType = Int)
    dest = similar(a, T)
    return t_to_last_ndx!(dest, a, fs, start_t)
end

"""
    t_sup_to_ndx()

Converts a time in a regularly sampled time series to the index of the last
sample before the specified time.
"""
function t_sup_to_ndx(args...)
    ndx = t_to_ndx(args...)
    return ndx - one(ndx)
end

"Clips an index to be within the valid range for an array of length l"
function clip_ndx end
clip_ndx(ndx::T, l::T) where {T <: Integer} = clamp(ndx, one(T), l)
clip_ndx(ndx::Integer, l::Integer) = clip_ndx(promote(ndx, l)...)

"clip_ndx but also return deviance"
function clip_ndx_deviance(ndx, l)
    ndxout = clip_ndx(ndx, l)
    return ndxout, ndxout - ndx
end

"""
    n_ndx(start_idx::T, stop_idx::T) where {T<:Integer}

Find the number of indices between `start_idx` and `stop_idx`.
"""
n_ndx(start_idx::T, stop_idx::T) where {T <: Integer} = stop_idx - start_idx + one(T)

function expand_selection(ib::T, ie::T, imax::T, expansion::T) where {T <: Integer}
    ib_exp = max(one(T), ib - expansion)
    ie_exp = min(ie + expansion, imax)
    return (ib_exp, ie_exp)
end

function expand_selection(
        ib::Integer, ie::Integer, imax::Integer, expansion::Integer
    )
    return expand_selection(promote(ib, ie, imax, expansion)...)
end

"""
    ndx_offset(start_ndx, npt)

Finds the index that will select npt number of elements starting at start_ndx.

If npt is negative, then start_ndx is treated like the end of a range of elements,
and the index required to return npt number of elements is returned.
"""
function ndx_offset(start_ndx::T, npt::T) where {T <: Integer}
    adjust = ifelse(npt < zero(T), one(T), -one(T))
    return start_ndx + npt + adjust
end

duration(npoints::Integer, fs::Real) = (npoints - 1) / fs

"Find the time_interval of a regularly sampled time series"
function time_interval end
function time_interval(npoints::Integer, fs::T, start_t::T) where {T <: AbstractFloat}
    return (start_t, start_t + duration(npoints, fs))
end
function time_interval(n::Integer, fs::Real, start_t::Real = zero(fs))
    return time_interval(n, convert(Float64, fs), convert(Float64, start_t))
end
time_interval(a::AbstractVector, args...) = time_interval(length(a), args...)

"Find the indices to select all points in a bin"
function bin_bounds end
# Intended to work with binno as an integer or ranges
# though I can't figure out how to express that
function bin_bounds(binno::Union{AbstractUnitRange{T}, T}, binsize::S) where
    {T <: Integer, S <: Integer}
    R = promote_type(T, S)
    @static if VERSION < v"0.7.0-DEV.2005"
        idx_start = (binno - one(R)) * binsize + one(R)
        idx_stop = idx_start + binsize - one(R)
    else
        idx_start = (binno .- one(R)) .* binsize .+ one(R)
        idx_stop = idx_start .+ binsize .- one(R)
    end
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
bin_center(rs::NTuple{2, R}) where {R <: Compat.AbstractRange} = (rs[1] + rs[2]) / 2
bin_center(r::Compat.AbstractRange, binsize::Real) = bin_center(bin_bounds(r, binsize))
function bin_center!(
        dest::AbstractArray{<:AbstractFloat, <:Any},
        a::AbstractArray{<:NTuple{2, <:Real}}
    )
    return dest .= bin_center.(a)
end
function bin_center(a::AbstractArray{<:NTuple{2, F}, <:Any}) where {F <: AbstractFloat}
    dest = similar(a, F)
    return bin_center!(dest, a)
end
function bin_center(a::AbstractArray{<:NTuple{2, <:Integer}, <:Any})
    dest = similar(a, Float64)
    return bin_center!(dest, a)
end

@generated function view_trailing_slice(
        a::AbstractArray{<:Any, N}, idx::T
    ) where {N, T <: Union{Integer, OrdinalRange{<:Integer, <:Any}}}
    return view_trailing_slice_impl(a)
end

function view_trailing_slice_impl(
        a::Type{<:AbstractArray{<:Any, N}}
    ) where {N}
    @compat exprargs = Vector{Any}(undef, N + 2)
    exprargs[1] = :view
    exprargs[2] = :a
    exprargs[3:(end - 1)] .= Ref(:(Colon()))
    exprargs[end] = :idx
    return Expr(:call, exprargs...)
end

function make_slice_idx(
        ndims::Integer, dimno::Integer, idx::T
    ) where {T <: Union{Integer, OrdinalRange{<:Integer, <:Any}}}
    @compat idxes = Array{Union{Colon, T}}(undef, ndims)
    idxes .= Colon()
    idxes[dimno] = idx
    return (idxes...,)
end

function make_expand_idx(ndims::Integer, dimno::Integer)
    @compat idxes = Array{Union{Colon, Int}}(undef, ndims)
    idxes[:] .= 1
    idxes[dimno] = Colon()
    return (idxes...,)
end

"copy_length_check returns true if dest can accept all data from source"
function copy_length_check end

function copy_length_dest_check(
        n_dest::Integer,
        d_off::Integer,
        n::Integer
    )
    return n_dest >= d_off && n_ndx(d_off, n_dest) >= n
end
function copy_length_check(
        n_dest::Integer,
        n_source::Integer,
        d_off::Integer = 1,
        s_off::Integer = 1,
        n::Integer = n_ndx(s_off, n_source)
    )
    source_ok = n_source >= s_off && n_ndx(s_off, n_source) >= n
    return source_ok && copy_length_dest_check(n_dest, d_off, n)
end

function copy_length_check(dest::AbstractArray, source::AbstractArray, args...)
    return copy_length_check(length(dest), length(source), args...)
end

function copy_length_check(dest::AbstractArray, d_off::Integer, source::AbstractArray, s_off::Integer, args...)
    return copy_length_check(dest, source, d_off, s_off, args...)
end

function ndx_wrap(i::T, max_ndx::Integer) where {T <: Integer}
    return mod(i - one(T), T(max_ndx)) + one(T)
end

function invert_perm(p)
    ip = similar(p)
    for i in 1:length(p)
        ip[p[i]] = i
    end
    return ip
end
