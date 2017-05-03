function add_time_and_micros(base_datetime::DateTime, dur_sec::Real, base_micros::Integer = 0)
    micro_mult = 1000000
    milli_mult = 1000
    dur_micros = round(Int, dur_sec * micro_mult)
    all_micros = base_micros + dur_micros
    (all_millis, rem_micros) = divrem(all_micros, milli_mult)
    joined_dt = base_datetime + Dates.Millisecond(all_millis)
    return (joined_dt, rem_micros)
end
