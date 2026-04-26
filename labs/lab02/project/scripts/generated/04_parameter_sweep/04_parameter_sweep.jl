using DrWatson

@quickactivate "project"

using Distributions
using Statistics
using Plots
using StatsPlots
using JLD2
using Random
using CSV
using DataFrames

include(srcdir("simulation.jl"))

base_params = Dict(
    :T => 24.0,
    :num_hours_for_est => 10000
)

λ_values = [2.0, 5.0, 8.0, 12.0, 15.0]

Random.seed!(42)

mkpath(datadir("attack_sim"))
mkpath(datadir("parameter_sweep"))

parametric_plots_dir = plotsdir("parameter_sweep")
mkpath(parametric_plots_dir)

summary_rows = DataFrame(
    λ = Float64[],
    emp_prob = Float64[],
    theor_prob = Float64[],
    mean_hourly_count = Float64[],
    mean_interval = Float64[],
    total_attacks = Int[]
)

println("Запуск параметрического исследования...")

for λ in λ_values
    println("\nλ = $λ")

    params = merge(base_params, Dict(:λ => λ))

    filename = datadir("attack_sim", savename(params, "jld2"))

    if isfile(filename)
        println("Загрузка существующих данных из: $filename")
        @load filename data params
    else
        println("Выполнение симуляции для λ = $λ")

        res = simulate_attacks(λ, params[:T])

        hourly_sample = rand(Poisson(λ), params[:num_hours_for_est])
        emp_prob = count(hourly_sample .> 10) / params[:num_hours_for_est]
        theor_prob = 1 - cdf(Poisson(λ), 10)

        data = Dict(
            :hourly_counts => res.hourly_counts,
            :intervals => res.intervals,
            :attack_times => res.attack_times,
            :emp_prob => emp_prob,
            :theor_prob => theor_prob
        )

        @save filename data params
        println("Результаты сохранены в: $filename")
    end

    hourly_counts = data[:hourly_counts]
    intervals = data[:intervals]
    attack_times = data[:attack_times]

    emp_prob = data[:emp_prob]
    theor_prob = data[:theor_prob]

    push!(
        summary_rows,
        (
            λ,
            emp_prob,
            theor_prob,
            mean(hourly_counts),
            isempty(intervals) ? NaN : mean(intervals),
            length(attack_times)
        )
    )

    # Распределение числа атак за час
    p1 = histogram(
        hourly_counts;
        bins = 0:maximum(hourly_counts),
        normalize = :probability,
        label = "Эмпирическая частота",
        xlabel = "Число атак за час",
        ylabel = "Вероятность",
        title = "Распределение атак, λ = $λ"
    )

    x_vals = 0:maximum(hourly_counts)
    theor_probs = pdf.(Poisson(λ), x_vals)

    plot!(
        p1,
        x_vals,
        theor_probs;
        line = :stem,
        marker = :circle,
        label = "Пуассон(λ=$λ)",
        lw = 2
    )

    # Накопленное число атак
    p2 = plot(
        attack_times,
        1:length(attack_times);
        label = "Реализация",
        xlabel = "Время, ч",
        ylabel = "Накопленное число атак",
        title = "Накопленное число атак"
    )

    time_grid = 0:0.1:params[:T]

    plot!(
        p2,
        time_grid,
        λ .* time_grid;
        label = "Среднее λ⋅t",
        ls = :dash
    )

    # Распределение интервалов между атаками
    p3 = histogram(
        intervals;
        bins = 30,
        normalize = :pdf,
        label = "Эмпирическая плотность",
        xlabel = "Интервал между атаками, ч",
        ylabel = "Плотность",
        title = "Интервалы между атаками"
    )

    x_dens = range(0, maximum(intervals), length = 100)
    theor_dens = pdf.(Exponential(1 / λ), x_dens)

    plot!(
        p3,
        x_dens,
        theor_dens;
        label = "Экспоненциальная плотность",
        lw = 2
    )

    # QQ-график интервалов
    p4 = qqplot(
        Exponential(1 / λ),
        intervals;
        qqline = :identity,
        xlabel = "Теоретические квантили",
        ylabel = "Эмпирические квантили",
        title = "QQ-plot интервалов"
    )

    combined = plot(
        p1,
        p2,
        p3,
        p4;
        layout = (2, 2),
        size = (1000, 800)
    )

    detailed_plot_path = joinpath(parametric_plots_dir, "details_λ=$(λ).png")
    savefig(combined, detailed_plot_path)
    display(combined)

    println("Детальный график сохранён в: $detailed_plot_path")
end

csv_path = datadir("parameter_sweep", "summary.csv")
CSV.write(csv_path, summary_rows)

jld2_path = datadir("parameter_sweep", "summary.jld2")
@save jld2_path summary_rows λ_values base_params

println("\nСводная таблица сохранена в: $csv_path")
println("Сводные данные сохранены в: $jld2_path")

p_summary = plot(
    summary_rows.λ,
    summary_rows.emp_prob;
    marker = :circle,
    label = "Эмпирическая вероятность",
    xlabel = "Интенсивность атак λ",
    ylabel = "P(N > 10)",
    title = "Зависимость вероятности P(N > 10) от λ"
)

plot!(
    p_summary,
    summary_rows.λ,
    summary_rows.theor_prob;
    marker = :square,
    label = "Теоретическая вероятность",
    lw = 2
)

summary_plot_path = plotsdir("parameter_sweep.png")
savefig(p_summary, summary_plot_path)
display(p_summary)

println("Обобщающий график сохранён в: $summary_plot_path")
println("\nГотово.")

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
