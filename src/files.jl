function dir_find_files(reg::Regex, dir::AbstractString = pwd())
    files = readdir(dir)
    return filter((x) -> occursin(reg, x), files)
end

function dir_match_files(reg::Regex, dir::AbstractString = pwd())
    files = readdir(dir)
    return only_matches(reg, files)
end
