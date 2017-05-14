clipind{T<:Integer}(ind::T, l::T) = min(max(ind, T(1)), l)
clipind(ind::Integer, l::Integer) = ind_clip(promote(ind, l)...)
