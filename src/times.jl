const FILE_DATEFORMAT = DateFormat("yyyy-mm-ddTHH-MM-SS")
const JULIA_DT_REG = r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}"

struct PreciseDateTime <: Dates.AbstractDateTime
    datetime::ZonedDateTime
    nanos::Nanosecond
end

PreciseDateTime(dt::ZonedDateTime) = PreciseDateTime(dt, Nanosecond(0))
PreciseDateTime(dt::DateTime, tz::TimeZone = localzone(), args...) =
    PreciseDateTime(ZonedDateTime(dt, tz), args...)
PreciseDateTime(dt::DateTime, nanos::Real) =
    PreciseDateTime(dt) + Nanosecond(round(Int, nanos))

function -(x::PreciseDateTime, y::PreciseDateTime)
    Millisecond(x.datetime - y.datetime).value * 1e-3 +
        (x.nanos - y.nanos).value * 1e-9
end

DateTime(pdt::PreciseDateTime) = TimeZones.localtime(pdt.datetime)
ZonedDateTime(pdt::PreciseDateTime) = pdt.datetime

trailing_micros(pdt::PreciseDateTime) = pdt.nanos.value / 10^3

dt_and_micros(pdt::PreciseDateTime) = (ZonedDateTime(pdt), trailing_micros(pdt))

function isless(a::PreciseDateTime, b::PreciseDateTime)
    a.datetime < b.datetime || (a.datetime == b.datetime && a.nanos < b.nanos)
end

function n_trailing_zero(number)
    n_digit = 0
    working_number = number
    while working_number != 0
        working_number, r = divrem(working_number, 10)
        r != 0 && break
        n_digit += 1
    end
    return n_digit
end

function clip_trailing(number)
    n_trail = n_trailing_zero(number)
    div(number, 10 ^ n_trail)
end

const TZ_DATEFMT = DateFormat("zzzz")

function show(io::IO, pdt::PreciseDateTime)
    dt = TimeZones.localtime(pdt.datetime)
    print(io, dt)
    millis = convert(Millisecond, dt)
    trailing_millis = millis - convert(Millisecond, floor(millis, Second))
    raw_millis = trailing_millis.value
    n_trailing_zero_milli = n_trailing_zero(raw_millis)
    raw_nanos = pdt.nanos.value
    nano_str = raw_nanos == 0 ?
        "" :
        repeat('0', n_trailing_zero_milli) * @sprintf("%03d", raw_nanos)
    print(io, nano_str)
    print(io, Dates.format(pdt.datetime, TZ_DATEFMT))
end

show(io::IO, ::MIME"text/plain", pdt::PreciseDateTime) =
    print(io, "PreciseDateTime:\n    ", pdt)

function +(pdt::PreciseDateTime, ns::Nanosecond)
    sum_nanos = ns + pdt.nanos
    sum_millis = floor(sum_nanos, Millisecond)
    trailing_nanos = sum_nanos - convert(Nanosecond, sum_millis)
    new_zdt = pdt.datetime + sum_millis
    PreciseDateTime(new_zdt, trailing_nanos)
end

+(pdt::PreciseDateTime, p::TimePeriod) = pdt + convert(Nanosecond, p)

add_nanos(pdt::PreciseDateTime, ns::Real) = pdt + Nanosecond(round(Int, ns))
add_nanos(dt::Dates.AbstractDateTime, nanos::Real) =
    add_nanos(PreciseDateTime(dt), nanos)
add_seconds(dt::Dates.AbstractDateTime, sec::Real) = add_nanos(dt, sec * 10^9)

function duration(start::PreciseDateTime, stop::PreciseDateTime)
    ns_diff = Dates.Nanosecond(stop.date - start.date) + (stop.time - start.time)
    ns_diff.value / 10^9
end

function duration(
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


function show(io::IO, r::TSRange)
    ioc = IOContext(io, :postgres => true)
    lb = ifelse(r.lower.inclusive, '[', '(')
    rb = ifelse(r.upper.inclusive, ']', ')')
    print(io, lb)
    print(ioc, r.lower.datetime)
    print(io, ',')
    print(ioc, r.upper.datetime)
    print(io, rb)
end

show(io::IO, ::MIME"text/plain", r::TSRange) =
    print(io, "TSRange time stamp range:\n    ", r)

function check_overlap(a::TSRange, b::TSRange)
    check_overlap(
        a.lower.datetime, a.upper.datetime, b.lower.datetime, b.upper.datetime
    )
end

duration(a::TSRange) = a.upper.datetime - a.lower.datetime # seconds
