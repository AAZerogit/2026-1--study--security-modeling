## Визуализация и анализ графа атак
#
# Скрипт загружает результаты эксперимента, выводит основные метрики,
# строит граф атак и сохраняет сводную таблицу.

using DrWatson

@quickactivate "project"

using Graphs
using GraphRecipes
using Plots
using JLD2
using DataFrames

## Загрузка данных

filename = datadir("attack_graph", "attack_graph_results.jld2")

if !isfile(filename)
    error("Файл с результатами не найден: $filename. Сначала запусти scripts/run_experiment.jl")
end

@load filename g paths metrics weights best_path best_probability source target vulnerabilities trust_relations

## Общие характеристики графа

println("Количество узлов: ", nv(g))
println("Количество рёбер: ", ne(g))
println("Количество путей от источника к цели: ", length(paths))
println("Наиболее вероятный путь: ", best_path)
println("Вероятность наиболее вероятного пути: ", best_probability)

## Анализ центральных узлов

println("\nТоп-5 узлов по входящей степени:")
in_degree = metrics[:in_degree]
top_indegree = sortperm(in_degree, rev = true)[1:min(5, length(in_degree))]

for v in top_indegree
    println("Узел $v: ", in_degree[v])
end

println("\nТоп-5 узлов по PageRank:")
pagerank = metrics[:pagerank]
top_pagerank = sortperm(pagerank, rev = true)[1:min(5, length(pagerank))]

for v in top_pagerank
    println("Узел $v: ", pagerank[v])
end

## Визуализация графа

mkpath(plotsdir())

node_labels = string.(1:nv(g))

p = graphplot(
    g;
    names = node_labels,
    method = :spring,
    nodeshape = :circle,
    markersize = 0.25,
    fontsize = 8,
    arrow = true,
    title = "Граф атак"
)

plot_path = plotsdir("attack_graph.png")
savefig(p, plot_path)
display(p)

println("\nГраф атак сохранён в: ", plot_path)

## Анализ длин путей

path_lengths = length.(paths)

if !isempty(path_lengths)
    println("\nМинимальная длина пути: ", minimum(path_lengths))
    println("Максимальная длина пути: ", maximum(path_lengths))
    println("Средняя длина пути: ", sum(path_lengths) / length(path_lengths))
else
    println("\nПути от источника к цели не найдены.")
end

## Сохранение сводных метрик

summary = DataFrame(
    metric = [
        "nodes",
        "edges",
        "paths",
        "best_path_probability",
        "min_path_length",
        "max_path_length",
        "mean_path_length"
    ],
    value = [
        nv(g),
        ne(g),
        length(paths),
        best_probability,
        isempty(path_lengths) ? 0 : minimum(path_lengths),
        isempty(path_lengths) ? 0 : maximum(path_lengths),
        isempty(path_lengths) ? 0.0 : sum(path_lengths) / length(path_lengths)
    ]
)

mkpath(datadir("attack_graph"))
summary_path = datadir("attack_graph", "summary.csv")

using CSV
CSV.write(summary_path, summary)

println("Сводная таблица сохранена в: ", summary_path)