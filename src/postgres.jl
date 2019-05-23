const POSTGRES_DATE_FORMAT = dateformat"YYYY-mm-dd HH:MM:SS.ssszzzz"
const MICRO_FORMAT = FormatExpr("{1:s}{2:03d}")
const PSQL_DATETIME_REG = r"(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.?\d{0,3})(\d*)"
const PSQL_RANGE_REG = r"([\[\(])\"([^\"]*)\",\s*\"([^\"]*)\"([\)\]])"
const POSTGRES_ARRAY_REG = r"\{([^\}]*)\}"

function postgres_time_str(dt::ZonedDateTime, micros::Integer = 0)
    add_seconds(dt, micros * 10^-6)
end

function postgres_time_str(pdt::PreciseDateTime)
    micros = cld(pdt.nanos.value, 10^3)
    (millis, trailing_micros) = divrem(micros, 10^3)
    dt = pdt.datetime + Dates.Millisecond(millis)
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

function postgres_make_tsrange_str(tsr::TSRange)
    postgres_make_tsrange_str(
        dt_and_micros(tsr.lower.datetime)...,
        dt_and_micros(tsr.upper.datetime)...;
        start_bracket = ifelse(tsr.lower.inclusive, '[', '('),
        stop_bracket = ifelse(tsr.upper.inclusive, ']', ')')
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

function postgres_tsrange_to_datetime_micros(timerange_str::AbstractString)
    tr = TSRange(timerange_str)
    (
        dt_and_micros(tr.lower.datetime)...,
        dt_and_micros(tr.lower.datetime)...
    )
end

function parse_postgres_array(s::AbstractString)
    m = match(POSTGRES_ARRAY_REG, s)
    m == nothing && return nothing
    content = m[1]
    strip.(split(content, ',', keepempty = false))
end

postgres_tuple_list(itr) = '(' * join(imap(string, itr), ',') * ')'
function postgres_tuple_rows(itr)
    join(imap(el -> '(' * join(imap(string, el), ',') * ')', itr), ", ")
end
