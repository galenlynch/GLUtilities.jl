const MATLAB_DATE_FORMAT = dateformat"d-u-y H:M:S"
const ISO_8601_FINE_DATE_FORMAT = dateformat"YYYY-mm-ddTHH:MM:SS.sss"

function matlab_datestring(datestr::AbstractString)
    DateTime(datestr, MATLAB_DATE_FORMAT)
end

function iso_fine_datestring(datestr::AbstractString)
    DateTime(datestr, ISO_8601_FINE_DATE_FORMAT)
end

function matlab_datevec_to_datetime(datevec::Array{T}) where {T<:Real}
    secs = datevec[6]
    rounded_secs = floor(secs)
    millis = round(mod(1000 * secs, 1000))
    return DateTime(datevec[1:5]..., rounded_secs, millis)::DateTime
end
