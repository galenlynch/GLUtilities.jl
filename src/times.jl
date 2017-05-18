function add_time_and_micros(base_datetime::DateTime, dur_sec::Real, base_micros::Integer = 0)
    micro_mult = 1000000 # 10^6
    milli_mult = 1000 # 10^3
    dur_micros = round(Int, dur_sec * micro_mult)
    all_micros = base_micros + dur_micros
    (all_millis, rem_micros) = divrem(all_micros, milli_mult)
    joined_dt = base_datetime + Dates.Millisecond(all_millis)
    return (joined_dt, rem_micros)
end

function time_range_to_sec(tstart::DateTime, microstart::Integer, tend::DateTime, microend::Integer)
    dmillis = Dates.Millisecond(tend - tstart).value
    dmicros = dmillis * 1000
    total_micros = dmicros + (microend - microstart)
    return total_micros / 1000000
end

function matlab_datevec_to_datetime{T<:Real}(datevec::Array{T})
    secs = datevec[6]
    rounded_secs = floor(secs)
    millis = round(mod(1000 * secs, 1000))
    return DateTime(datevec[1:5]..., rounded_secs, millis)::DateTime
end
