function randperm_notsame(n::Integer)
    p = randperm(n)
    for i in 1:n
        new_i = p[i]
        if new_i == i
            while new_i == i
                new_i = rand(1:n)
            end
            p[new_i] = i
            p[i] = new_i
        end
    end
    return p
end

function mc_twotail_asymm_p(val, nulldist, nnull::Integer = length(nulldist))
    nless = 0
    nmore = 0
    for nullval in nulldist
        nless = ifelse(nullval <= val, nless + 1, nless)
        nmore = ifelse(nullval >= val, nmore + 1, nmore)
    end
    return 2 * min(nless, nmore) / nnull
end

function binomial_p_ci(n_success, n_trial, alpha)
    half_alpha = alpha / 2
    if n_success == 0
        lb = 0
        ub = 1 - half_alpha^(1 / n_trial)
    elseif n_success == n_trial
        lb = half_alpha^(1 / n_trial)
        ub = 1
    else
        lb = quantile(Beta(n_success, n_trial - n_success + 1), half_alpha)
        ub = quantile(Beta(n_success + 1, n_trial - n_success), 1 - half_alpha)
    end
    return lb, ub
end
