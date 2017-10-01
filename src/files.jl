function dir_find_files(reg::Regex, dir::AbstractString = ".")
    files = readdir(dir)
    return filter((x) -> ismatch(reg, x), files)
end

function dir_match_files(reg::Regex, dir::AbstractString = ".")
    files = readdir(dir)
    return only_matches(reg, files)
end
