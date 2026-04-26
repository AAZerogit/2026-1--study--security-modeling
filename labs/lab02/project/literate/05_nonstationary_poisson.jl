# # Дополнительное задание 2
#
# Моделируется нестационарный пуассоновский поток с интенсивностью,
# зависящей от времени суток: `λ(t) = 2 + 5 sin(πt/12)`.
# Для генерации используется метод прореживания.
#

using DrWatson

@quickactivate "project"

using Distributions
using Random
using Statistics
using Plots
using JLD2

Random.seed!(42)

# Интенсивность атак зависит от времени суток.
# t измеряется в часах.
function λ_t(t)
    return max(0.0, 2 + 5 * sin(pi * t / 12))
end

# Симуляция нестационарного пуассоновского потока методом прореживания.
function simulate_nonstationary_attacks(T::Float64)
    λ_max = 7.0

    attack_times = Float64[]
    current_time = 0.0

    while current_time < T
        τ = rand(Exponential(1 / λ_max))
        current_time += τ

        if current_time > T
            break
        end

        accept_probability = λ_t(current_time) / λ_max

        if rand() <= accept_probability
            push!(attack_times, current_time)
        end
    end

    return attack_times
end

T = 24.0
attack_times = simulate_nonstationary_attacks(T)

time_grid = range(0, T, length = 500)
λ_values = λ_t.(time_grid)

mkpath(plotsdir())
mkpath(datadir("nonstationary"))

# График интенсивности
p1 = plot(
    time_grid,
    λ_values;
    label = "λ(t)",
    xlabel = "Время, ч",
    ylabel = "Интенсивность атак",
    title = "Нестационарная интенсивность атак"
)

# Накопленное число атак
p2 = plot(
    attack_times,
    1:length(attack_times);
    label = "Накопленное число атак",
    xlabel = "Время, ч",
    ylabel = "N(t)",
    title = "Нестационарный пуассоновский поток"
)

combined = plot(
    p1,
    p2;
    layout = (2, 1),
    size = (900, 700)
)

plot_path = plotsdir("nonstationary_poisson.png")
savefig(combined, plot_path)
display(combined)

data_path = datadir("nonstationary", "nonstationary_poisson.jld2")
@save data_path T attack_times time_grid λ_values

println("Количество атак за 24 часа: ", length(attack_times))
println("Средняя интенсивность на сетке: ", mean(λ_values))
println("График сохранён в: ", plot_path)
println("Данные сохранены в: ", data_path)