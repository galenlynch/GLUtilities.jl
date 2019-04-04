const MATLAB_DATE_FORMAT = dateformat"d-u-y H:M:S"
const ISO_8601_FINE_DATE_FORMAT = dateformat"YYYY-mm-ddTHH:MM:SS.sss"

function matlab_datestring(datestr::AbstractString)
    DateTime(datestr, MATLAB_DATE_FORMAT)
end

function iso_fine_datestring(datestr::AbstractString)
    DateTime(datestr, ISO_8601_FINE_DATE_FORMAT)
end

function matlab_datevec_to_datetime(datevec::Array{T}) where {T<:Real}
    float_secs = datevec[6]
    millis = round(Int, 1000 * float_secs)
    full_secs, trailing_millis = divrem(millis, 1000)
    DateTime(
        datevec[1],
        datevec[2],
        datevec[3],
        datevec[4],
        datevec[5],
        full_secs,
        trailing_millis
    )
end
