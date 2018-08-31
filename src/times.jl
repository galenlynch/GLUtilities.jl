struct PreciseDateTime
    dt::DateTime
    micros::Int
end
PreciseDateTime(dt::DateTime) = PreciseDateTime(dt, 0)

function isless(a::PreciseDateTime, b::PreciseDateTime)
    a.dt < b.dt || (a.dt == b.dt && a.micros < b.micros)
end

function print(io::IO, pdt::PreciseDateTime)
    if get(io, :postgres, false)
        print(io, postgres_time_str(pdt))
    else
        error("Not yet implemented")
    end
end

function add_seconds(pdt::PreciseDateTime, sec::Real)
    micro_mult = 1000000 # 10^6
    milli_mult = 1000 # 10^3
    dur_micros = round(Int, sec * micro_mult)
    all_micros = pdt.micros + dur_micros
    (all_millis, rem_micros) = divrem(all_micros, milli_mult)
    joined_dt = pdt.dt + Dates.Millisecond(all_millis)
    return PreciseDateTime(joined_dt, rem_micros)
end
add_seconds(dt::DateTime, sec::Real) = add_seconds(PreciseDateTime(dt), sec)

function time_range_to_sec(
    tstart::DateTime, microstart::Integer, tend::DateTime, microend::Integer
)
    dmillis = Dates.Millisecond(tend - tstart).value
    dmicros = dmillis * 1000
    total_micros = dmicros + (microend - microstart)
    return total_micros / 1000000
end

function time_range_to_sec(start::PreciseDateTime, stop::PreciseDateTime)
    time_range_to_sec(start.dt, start.micros, stop.dt, stop.micros)
end

struct RangeBound
    datetime::PreciseDateTime
    inclusive::Bool
end
function RangeBound(dt::DateTime, micros::Integer = 0, inclusive::Bool = true)
    RangeBound(PrecsieDateTime(dt, micros), inclusive)
end

struct TSRange
    lower::RangeBound
    upper::RangeBound
    function TSRange(lower::RangeBound, upper::RangeBound)
        if lower.datetime > upper.datetime
            throw(ArgumentError("Bounds are not well ordered"))
        end
        new(lower, upper)
    end
end

function print(io::IO, r::TSRange)
    ioc = IOContext(io, :postgres => true)
    lb = r.lower.inclusive ? '[' : '('
    rb = r.upper.inclusive ? ']' : ')'
    print(io, lb)
    print(ioc, r.lower.datetime)
    print(io, ',')
    print(ioc, r.upper.datetime)
    print(io, rb)
end

