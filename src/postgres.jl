const POSTGRES_DATE_FORMAT = dateformat"YYYY-mm-dd HH:MM:SS.sss"
const MICRO_FORMAT = FormatExpr("{1:s}{2:03d}")
const PSQL_DATETIME_REG = r"(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.?\d{0,3})(\d*)"
const PSQL_RANGE_REG = r"([\[\(])\"([^\"]*)\",\s*\"([^\"]*)\"([\)\]])"
const POSTGRES_ARRAY_REG = r"\{([^\}]*)\}"

function postgres_time_str(dt::DateTime, micros::Integer = 0)
    @assert micros < 1000 "Trailing microseconds only"
    datetime_str = Dates.format(dt, POSTGRES_DATE_FORMAT)
    return format(MICRO_FORMAT, datetime_str, micros)
end

function postgres_time_str(pdt::PreciseDateTime)
    micros = cld(pdt.time.instant.value, 10^3)
    (millis, trailing_micros) = divrem(micros, 10^3)
    dt = DateTime(pdt.date) + Dates.Millisecond(millis)
    postgres_time_str(dt, trailing_micros)
end

function PreciseDateTime(datestring::AbstractString)
    m = match(PSQL_DATETIME_REG, datestring)
    m == nothing && return nothing
    dt = DateTime(m[1], POSTGRES_DATE_FORMAT)
    micros = isempty(m[2]) ? 0 : parse(Int, rpad(m[2], 3, '0'))
    PreciseDateTime(dt, micros)
end

function postgres_make_tsrange_str(
    start_dt::DateTime,
    start_micros::Integer,
    stop_dt::DateTime,
    stop_micros::Integer;
    start_bracket::Char = '[',
    stop_bracket::Char = ')'
)
    string(start_bracket, '"', postgres_time_str(start_dt, start_micros), '"',
        ',',
        '"', postgres_time_str(stop_dt, stop_micros), '"', stop_bracket
    )
end

function TSRange(rangestr::AbstractString)
    m = match(PSQL_RANGE_REG, rangestr)
    m == nothing && error("Could not parse ", s, " as TSRange")
    if m[1] == "["
        start_inclusive = true
    elseif m[1] == "("
        start_inclusive = false
    else
        error("Could not parse start bound")
    end
    start_t = PreciseDateTime(m[2])
    stop_t = PreciseDateTime(m[3])
    if m[4] == "]"
        stop_inclusive = true
    elseif m[4] == ")"
        stop_inclusive = false
    else
        error("Could not parse stop bound")
    end
    TSRange(
        RangeBound(start_t, start_inclusive),
        RangeBound(stop_t, stop_inclusive)
    )
end

function parse_postgres_array(s::AbstractString)
    m = match(POSTGRES_ARRAY_REG, s)
    m == nothing && return nothing
    content = m[1]
    strip.(split(content, ',', keepempty = false))
end
