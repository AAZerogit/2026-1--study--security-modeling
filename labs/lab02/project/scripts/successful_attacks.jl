using DrWatson

@quickactivate "project"

using Distributions
using Statistics
using Plots
using JLD2
using Random

include("params.jl")

Random.seed!(42)

params = default_params

λ = params[:λ]
T = params[:T]

# Вероятность того, что отдельная атака окажется успешной
p_success = 0.2

# Моделируем общее число атак по часам
hourly_attacks = rand(Poisson(λ), Int(T))

# Для каждого часа моделируем число успешных атак
successful_attacks = [
    rand(Binomial(n, p_success)) for n in hourly_attacks
]

total_attacks = sum(hourly_attacks)
total_successful = sum(successful_attacks)

emp_success_rate = total_successful / total_attacks
expected_successful = λ * T * p_success

println("λ = ", λ)
println("T = ", T)
println("p_success = ", p_success)
println("Всего атак: ", total_attacks)
println("Успешных атак: ", total_successful)
println("Эмпирическая доля успешных атак: ", emp_success_rate)
println("Теоретическое ожидаемое число успешных атак: ", expected_successful)

mkpath(plotsdir())
mkpath(datadir("successful_attacks"))

hours = 1:Int(T)

p = plot(
    hours,
    hourly_attacks;
    label = "Все атаки",
    marker = :circle,
    xlabel = "Час",
    ylabel = "Число атак",
    title = "Все атаки и успешные атаки по часам"
)

plot!(
    p,
    hours,
    successful_attacks;
    label = "Успешные атаки",
    marker = :square
)

plot_path = plotsdir("successful_attacks.png")
savefig(p, plot_path)

data_path = datadir("successful_attacks", "successful_attacks.jld2")

@save data_path params p_success hourly_attacks successful_attacks total_attacks total_successful emp_success_rate expected_successful

println("График сохранён в: ", plot_path)
println("Данные сохранены в: ", data_path)