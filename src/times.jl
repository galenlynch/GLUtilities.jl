const FILE_DATEFORMAT = DateFormat("yyyy-mm-ddTHH-MM-SS")

struct PreciseDateTime
    date::Date
    time::Time
end
PreciseDateTime(dt::DateTime) = PreciseDateTime(Date(dt), Time(dt))
function PreciseDateTime(dt::DateTime, micros::Real)
    add_seconds(PreciseDateTime(dt), micros / 10^6)
end

DateTime(pdt::PreciseDateTime) = DateTime(pdt.date) + pdt.time.instant

micros(pdt::PreciseDateTime) = Dates.microsecond(pdt.time)

function isless(a::PreciseDateTime, b::PreciseDateTime)
    a.date < b.date || (a.date == b.date && a.time < b.time)
end

function print(io::IO, pdt::PreciseDateTime)
    if get(io, :postgres, false)
        print(io, postgres_time_str(pdt))
    else
        error("Not yet implemented")
    end
end

function add_seconds(pdt::PreciseDateTime, sec::Real)
    ns_in = ceil(Int, sec * 10^9)
    (d, ns_comb) = divrem(pdt.time.instant.value + ns_in, 86400000000000)
    new_d = pdt.date + Dates.Day(d)
    new_t = Time(Dates.Nanosecond(ns_comb))
    PreciseDateTime(new_d, new_t)
end
add_seconds(dt::DateTime, sec::Real) = add_seconds(PreciseDateTime(dt), sec)

function time_range_to_sec(start::PreciseDateTime, stop::PreciseDateTime)
    ns_diff = Dates.Nanosecond(stop.date - start.date) + (stop.time - start.time)
    ns_diff.value / 10^9
end

function time_range_to_sec(
    tstart::DateTime, microstart::Real, tend::DateTime, microend::Real
)
    micro_diff = Dates.Microsecond(tend - tstart).value + (microend - microstart)
    micro_diff / 10^6
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
