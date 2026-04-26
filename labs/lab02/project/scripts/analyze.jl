using DrWatson

@quickactivate "project"

using Distributions
using JLD2
using Plots
using StatsPlots

include("params.jl")

params = default_params

filename = datadir("attack_sim", savename(params, "jld2"))

if !isfile(filename)
    error("Файл с результатами не найден: $filename. Сначала запусти scripts/run_experiment.jl")
end

@load filename data params

hourly_counts = data[:hourly_counts]
intervals = data[:intervals]
attack_times = data[:attack_times]

λ = params[:λ]
T = params[:T]

emp_prob = data[:emp_prob]
theor_prob = data[:theor_prob]

println("Эмпирическая вероятность P(N₁ > 10) = ", emp_prob)
println("Теоретическая вероятность P(N₁ > 10) = ", theor_prob)

mkpath(plotsdir())

# 1. Гистограмма числа атак за час
p1 = histogram(
    hourly_counts;
    bins = 0:maximum(hourly_counts),
    normalize = :probability,
    label = "Эмпирическая частота",
    xlabel = "Число атак за час",
    ylabel = "Вероятность",
)

x_vals = 0:maximum(hourly_counts)
theor_probs = pdf.(Poisson(λ), x_vals)

plot!(
    p1,
    x_vals,
    theor_probs;
    line = :stem,
    marker = :circle,
    label = "Теоретическое Пуассона(λ=$λ)",
    lw = 2,
)

title!(p1, "Распределение числа атак за час")

# 2. Накопленное число атак
p2 = plot(
    attack_times,
    1:length(attack_times);
    label = "Реализация",
    xlabel = "Время, ч",
    ylabel = "Накопленное число атак",
)

time_grid = 0:0.1:T

plot!(
    p2,
    time_grid,
    λ .* time_grid;
    label = "Среднее λ·t",
    ls = :dash,
)

title!(p2, "Накопленное число атак за $(T) ч")

# 3. Гистограмма интервалов между атаками
p3 = histogram(
    intervals;
    bins = 30,
    normalize = :pdf,
    label = "Эмпирическая плотность",
    xlabel = "Интервал между атаками, ч",
    ylabel = "Плотность",
)

x_dens = range(0, maximum(intervals), length = 100)
theor_dens = pdf.(Exponential(1 / λ), x_dens)

plot!(
    p3,
    x_dens,
    theor_dens;
    label = "Экспоненциальная плотность",
    lw = 2,
)

title!(p3, "Распределение интервалов между атаками")

# 4. QQ-plot интервалов против экспоненциального распределения
p4 = qqplot(
    Exponential(1 / λ),
    intervals;
    qqline = :identity,
    xlabel = "Теоретические квантили",
    ylabel = "Эмпирические квантили",
    title = "QQ-plot интервалов",
)

combined = plot(
    p1,
    p2,
    p3,
    p4;
    layout = (2, 2),
    size = (1000, 800),
)

plot_filename = plotsdir("attack_sim_analysis.png")
savefig(combined, plot_filename)

println("Графики сохранены в: ", plot_filename)