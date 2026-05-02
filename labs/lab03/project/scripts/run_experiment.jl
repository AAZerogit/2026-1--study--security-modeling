using DrWatson

@quickactivate "project"

using Graphs
using JLD2
using Random
using StatsBase

include(srcdir("attack_graph.jl"))

Random.seed!(42)

n = 12
edge_prob = 0.25
source = 1
target = 12

vulnerabilities = Dict(
    2 => "CVE-2026-0001",
    4 => "CVE-2026-0002",
    7 => "CVE-2026-0003",
    10 => "CVE-2026-0004"
)

trust_relations = [
    (1, 2),
    (2, 4),
    (4, 7),
    (7, 10),
    (10, 12)
]

g = build_attack_graph(n, edge_prob, vulnerabilities, trust_relations)

paths = find_all_paths(g, source, target)
metrics = compute_centrality_metrics(g)

cvss_scores = Dict{Tuple{Int, Int}, Float64}()

for e in edges(g)
    cvss_scores[(src(e), dst(e))] = rand(0.1:0.1:0.9)
end

weights = assign_edge_weights(g, cvss_scores)

best_path, best_probability = most_likely_path(g, source, target, weights)

mkpath(datadir("attack_graph"))

filename = datadir("attack_graph", "attack_graph_results.jld2")

@save filename g paths metrics weights best_path best_probability source target vulnerabilities trust_relations

println("Количество узлов: ", nv(g))
println("Количество рёбер: ", ne(g))
println("Источник атаки: ", source)
println("Цель атаки: ", target)
println("Количество путей от источника к цели: ", length(paths))
println("Наиболее вероятный путь: ", best_path)
println("Вероятность наиболее вероятного пути: ", best_probability)
println("Результаты сохранены в: ", filename)