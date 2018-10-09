function randperm_notsame(n::Integer)
    p = randperm(n)
    for i = 1:n
        new_i = p[i]
        if new_i == i
            while new_i == i
                new_i = rand(1:n)
            end
            p[new_i] = i
            p[i] = new_i
        end
    end
    p
end

function mc_twotail_asymm_p(val, nulldist, nnull::Integer = length(nulldist))
    nless = 0
    nmore = 0
    for nullval in nulldist
        nless = ifelse(nullval <= val, nless + 1, nless)
        nmore = ifelse(nullval >= val, nmore + 1, nmore)
    end
    2 * min(nless, nmore) / nnull
end
