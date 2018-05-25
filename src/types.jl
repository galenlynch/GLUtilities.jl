div_type(::Type{N}) where {N<:AbstractFloat} = N
div_type(::Type{N}) where {N<:Integer} = Float64
function div_type(::Type{N}, ::Type{D}) where {N<:Number, D<:Number}
    div_type(promote_type(N, D))
end
div_type(num::N, den::D) where {N<:Number, D<:Number} = div_type(N, D)
div_type(num::N) where {N<:Number} = div_type(N)
