# # Дополнительное задание 3
#
# Вычисляются вероятности двух событий:
# отсутствие атак за смену длительностью 8 часов и не менее трёх атак
# за интервал длительностью 30 минут.
#

using DrWatson

@quickactivate "project"

using Distributions

include(scriptsdir("params.jl"))

params = default_params
λ = params[:λ]

# Для пуассоновского потока:
# N(t) ~ Poisson(λ * t)

# 1. Вероятность отсутствия атак за 8 часов
T_shift = 8.0
prob_no_attacks_8h = pdf(Poisson(λ * T_shift), 0)

# 2. Вероятность не менее 3 атак за 30 минут
T_half_hour = 0.5
prob_at_least_3_30min = 1 - cdf(Poisson(λ * T_half_hour), 2)

println("λ = ", λ)
println("P(ни одной атаки за 8 часов) = ", prob_no_attacks_8h)
println("P(не менее 3 атак за 30 минут) = ", prob_at_least_3_30min)