## Анализ влияния вероятности ребра
#
# Скрипт исследует, как плотность графа влияет на число путей,
# входящую степень узлов и среднюю длину маршрута атаки.

using DrWatson

@quickactivate "project"

using Graphs
using DataFrames
using CSV
using Plots
using Random
using Statistics

include(srcdir("attack_graph.jl"))

## Настройка параметров

Random.seed!(42)

n = 12
source = 1
target = 12

edge_probs = 0.1:0.1:0.7

results = DataFrame(
    edge_prob = Float64[],
    num_edges = Int[],
    num_paths = Int[],
    max_in_degree = Int[],
    mean_path_length = Float64[]
)

## Проведение эксперимента

for edge_prob in edge_probs
    println("edge_prob = $edge_prob")

    g = build_attack_graph(n, edge_prob, Dict(), [])

    paths = find_all_paths(g, source, target)

    path_lengths = length.(paths)
    mean_path_length = isempty(path_lengths) ? 0.0 : mean(path_lengths)

    push!(
        results,
        (
            edge_prob,
            ne(g),
            length(paths),
            maximum(indegree(g)),
            mean_path_length
        )
    )
end

## Сохранение таблицы

mkpath(datadir("parameter_sweep"))

csv_path = datadir("parameter_sweep", "parameter_sweep.csv")
CSV.write(csv_path, results)

## Построение графиков

mkpath(plotsdir())

p1 = plot(
    results.edge_prob,
    results.num_paths;
    marker = :circle,
    xlabel = "Вероятность ребра",
    ylabel = "Количество путей",
    title = "Количество путей атаки",
    label = "paths"
)

p2 = plot(
    results.edge_prob,
    results.max_in_degree;
    marker = :circle,
    xlabel = "Вероятность ребра",
    ylabel = "Макс. входящая степень",
    title = "Максимальная входящая степень",
    label = "max in-degree"
)

p3 = plot(
    results.edge_prob,
    results.mean_path_length;
    marker = :circle,
    xlabel = "Вероятность ребра",
    ylabel = "Средняя длина пути",
    title = "Средняя длина пути",
    label = "mean path length"
)

combined = plot(
    p1,
    p2,
    p3;
    layout = (3, 1),
    size = (800, 900)
)

plot_path = plotsdir("parameter_sweep.png")
savefig(combined, plot_path)
display(combined)

println("Таблица сохранена в: ", csv_path)
println("График сохранён в: ", plot_path)