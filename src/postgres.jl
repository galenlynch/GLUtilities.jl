const POSTGRES_DATE_FORMAT = dateformat"YYYY-mm-dd HH:MM:SS.sss"
const MICRO_FORMAT = FormatExpr("{1:s}{2:03d}")
const PSQL_REG = r"(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.?\d{0,3})(\d*)"

function postgres_time_str(dt::DateTime, micros::Integer = 0)
    @assert micros < 1000 "Trailing microseconds only"
    datetime_str = Dates.format(dt, POSTGRES_DATE_FORMAT)
    return format(MICRO_FORMAT, datetime_str, micros)
end

function postgres_datetime_micros(datestring::AbstractString)
    m = match(PSQL_REG, datestring)
    m == nothing && return (nothing, nothing)
    dt = DateTime(m[1], POSTGRES_DATE_FORMAT)
    micros = isempty(m[2]) ? 0 : parse(Int, rpad(m[2], 3, '0'))
    dt, micros
end
