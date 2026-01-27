div_type(::Type{N}) where {N<:AbstractFloat} = N
div_type(::Type{N}) where {N<:Integer} = Float64
div_type(::Type{A}) where {T<:AbstractFloat,N,A<:AbstractArray{T,N}} = Array{T,N}
div_type(::Type{A}) where {T<:Integer,N,A<:AbstractArray{T,N}} = Array{Float64,N}
function div_type(::Type{N}, ::Type{D}) where {N<:Number,D<:Number}
    div_type(promote_type(N, D))
end
div_type(num::N, den::D) where {N<:Number,D<:Number} = div_type(N, D)
div_type(num::N) where {N<:Number} = div_type(N)
