using GLUtilities
using Base.Test

# write your own tests here
@test clipind(-1, 2) == 1
@test clipind(3, 2) == 2
@test clipind(1, 2) == 1
@test clipind(2, 2) == 2

@test add_time_and_micros(DateTime(2013, 7, 1), 1) == (DateTime(2013, 7, 1, 0, 0, 1), 0)

@test time_range_to_sec(DateTime(2013, 7, 1, 0, 0, 0), 0, DateTime(2013, 7, 1, 0, 0, 1), 0) == 1

@test check_overlap(1, 3, 2, 3)
@test !check_overlap(1, 3, 4, 5)

