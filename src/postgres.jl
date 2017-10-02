const POSTGRES_DATE_FORMAT = dateformat"YYYY-mm-dd HH:MM:SS.sss"
const MICRO_FORMAT = FormatExpr("{1:s}{2:03d}")

function postgres_time_str(dt::DateTime, micros::Integer = 0)
    @assert micros < 1000 "Trailing microseconds only"
    datetime_str = Dates.format(dt, POSTGRES_DATE_FORMAT)
    return format(MICRO_FORMAT, datetime_str, micros)
end

