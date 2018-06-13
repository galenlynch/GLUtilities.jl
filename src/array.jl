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
