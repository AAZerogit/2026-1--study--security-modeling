# # Основной эксперимент
#
# В этом скрипте выполняется базовая симуляция пуассоновского потока атак.
# Используются параметры из файла `scripts/params.jl`, функция моделирования
# из `src/simulation.jl`, после чего результаты сохраняются в формате JLD2.
#

using DrWatson

@quickactivate "project"

using Distributions
using Statistics
using JLD2

include(scriptsdir("params.jl"))
include(srcdir("simulation.jl"))

params = default_params

function run_simulation(p)
    @unpack λ, T, num_hours_for_est = p

    res = simulate_attacks(λ, T)

    hourly_sample = rand(Poisson(λ), num_hours_for_est)

    emp_prob = count(hourly_sample .> 10) / num_hours_for_est
    theor_prob = 1 - cdf(Poisson(λ), 10)

    return Dict(
        :hourly_counts => res.hourly_counts,
        :intervals => res.intervals,
        :attack_times => res.attack_times,
        :emp_prob => emp_prob,
        :theor_prob => theor_prob
    )
end

mkpath(datadir("attack_sim"))

filename = datadir("attack_sim", savename(params, "jld2"))

data = run_simulation(params)

@save filename data params

println("Результаты сохранены в: ", filename)
println("Эмпирическая вероятность P(N₁ > 10): ", data[:emp_prob])
println("Теоретическая вероятность P(N₁ > 10): ", data[:theor_prob])