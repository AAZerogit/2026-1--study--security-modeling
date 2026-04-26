using DrWatson

@quickactivate "project"

using Distributions

include(scriptsdir("params.jl"))

params = default_params
λ = params[:λ]

T_shift = 8.0
prob_no_attacks_8h = pdf(Poisson(λ * T_shift), 0)

T_half_hour = 0.5
prob_at_least_3_30min = 1 - cdf(Poisson(λ * T_half_hour), 2)

println("λ = ", λ)
println("P(ни одной атаки за 8 часов) = ", prob_no_attacks_8h)
println("P(не менее 3 атак за 30 минут) = ", prob_at_least_3_30min)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
