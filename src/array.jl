function weighted_mean_dim(
    summand::AbstractArray{E, N},
    weights::AbstractVector{T},
    dim::Integer = N,
    total_weight::T = sum(weights)
) where {E<:Number, N, T<:Number}
    F = promote_type(E, T)

    dims = collect(size(summand))
    dims[dim] = 1

    slice_idx = collect(make_slice_idx(N, dim, 1))
    reduced = zeros(F, (dims...))
    for i in 1:size(summand, dim)
        slice_idx[dim] = i
        reduced .+= summand[slice_idx...] .* weights[i]
    end
    reduced .= reduced ./ total_weight
    return reduced
end

function weighted_mean(
    summand::AbstractArray{E, N},
    weights::AbstractArray{T, N},
    total_weight::T = sum(weights)
) where {E<:Number, N, T<:Number}
    if size(summand) != size(weights)
        throw(ArgumentError("Sizes are not the same"))
    end
    F = promote_type(E, T)
    reduced = zero(F)
    for i in eachindex(summand)
        reduced += summand[i] * weights[i]
    end
    return reduced / total_weight
end

function weighted_mean(
    summand::AbstractArray{E,N},
    weights::AbstractArray{T,N},
    total_weight::T = sum(weights)
) where {G<:Number, E<:AbstractArray{G, <:Any}, N, T<:Number}
    # assumes elements of summand have the same size
    if size(summand) != size(weights)
        throw(ArgumentError("Sizes are not the same"))
    end
    if isempty(summand)
        throw(ArgumentError("summand is empty"))
    end
    F = promote_type(G, T)
    reduced = zeros(F, size(summand[1]))
    for i in eachindex(summand)
        reduced += summand[i] * weights[i]
    end
    return reduced / total_weight
end

function local_extrema(s::AbstractVector, comp::Function = >)
    ns = length(s)
    idxes = Vector{Int}(div(ns, 2))
    out_i = 0
    if ns > 2
        @inbounds last_comp = comp(s[1], s[2])
        for i in 2:(ns - 1)
            @inbounds this_comp = comp(s[i], s[i + 1])
            if this_comp && ! last_comp
                out_i += 1
                @inbounds idxes[out_i] = i
            end
            last_comp = this_comp
        end
    end
    resize!(idxes, out_i)
    idxes
end

function cov(as::AbstractVector{<:AbstractVector{T}}) where T<:Real
    allsame(length, as) || throw(ArgumentError("Lengths must be the same"))
    na = length(as)
    S = div_type(T)
    cov = zeros(S, na, na)
    if na > 0
        means = Vector{S}(na)
        scratch = Vector{S}(na)
        @inbounds for (i, a) in enumerate(as)
            means[i] = mean(a)
        end

        nx = length(as[1])
        for xno = 1:nx
            @simd for arrno = 1:na
                @inbounds scratch[arrno] = as[arrno][xno] - means[arrno]
            end
            for i = 1:na
                @simd for j = i:na
                    @inbounds cov[i, j] += scratch[i] * scratch[j]
                end
            end
        end
        cov ./= nx - 1
    end
    UpperTriangular(cov)
end
