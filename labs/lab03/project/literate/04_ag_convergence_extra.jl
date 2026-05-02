## Дополнительный анализ сходимости
#
# Скрипт проверяет время поиска всех путей атаки
# на более крупных графах с меньшей плотностью связей.

using DrWatson

@quickactivate "project"

using Graphs
using Plots
using JLD2
using Random

include(srcdir("attack_graph.jl"))

## Настройка эксперимента

sizes = [10, 20, 30]

time_vals = Float64[]
path_counts = Int[]

Random.seed!(123)

## Запуск экспериментов

for n in sizes
    println("Размер сети: $n")

    g = build_attack_graph(n, 0.1, Dict(), [])

    t = @elapsed paths = find_all_paths(g, 1, n)

    push!(time_vals, t)
    push!(path_counts, length(paths))

    println("  Время: $(round(t, digits=3)) с, путей: $(length(paths))")
end

## Построение графиков

p1 = plot(
    sizes,
    time_vals;
    marker = :circle,
    xlabel = "Число узлов",
    ylabel = "Время (с)",
    title = "Время поиска всех путей",
    legend = false
)

p2 = plot(
    sizes,
    path_counts;
    marker = :circle,
    xlabel = "Число узлов",
    ylabel = "Количество путей",
    title = "Количество путей атаки",
    legend = false
)

combined = plot(
    p1,
    p2;
    layout = (2, 1),
    size = (800, 600)
)

mkpath(plotsdir())
savefig(combined, plotsdir("convergence_extra.png"))
display(combined)

## Сохранение результатов

mkpath(datadir("convergence"))

data = Dict(
    :sizes => sizes,
    :times => time_vals,
    :path_counts => path_counts
)

@save datadir("convergence", "convergence_extra_data.jld2") data

println("График сохранён в ", plotsdir("convergence_extra.png"))
println("Данные сохранены в ", datadir("convergence", "convergence_extra_data.jld2"))