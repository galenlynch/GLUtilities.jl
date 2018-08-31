function matlab_datestring(datestr::AbstractString)
    DateTime(datestr, dateformat"d-u-y H:M:S")
end

function matlab_datevec_to_datetime(datevec::Array{T}) where {T<:Real}
    secs = datevec[6]
    rounded_secs = floor(secs)
    millis = round(mod(1000 * secs, 1000))
    return DateTime(datevec[1:5]..., rounded_secs, millis)::DateTime
end
