using DrWatson

@quickactivate "project"

using Graphs
using GraphRecipes
using Plots
using JLD2
using Random

include(srcdir("attack_graph.jl"))

Random.seed!(42)

n = 12
edge_prob = 0.25
source = 1
target = 12

trust_relations = [
    (1, 2),
    (2, 4),
    (4, 7),
    (7, 10),
    (10, 12)
]

g_before = build_attack_graph(n, edge_prob, Dict(), trust_relations)

paths_before = find_all_paths(g_before, source, target)
metrics_before = compute_centrality_metrics(g_before)

protected_node = 7

g_after = copy(g_before)

for e in collect(edges(g_after))
    if src(e) == protected_node || dst(e) == protected_node
        rem_edge!(g_after, src(e), dst(e))
    end
end

paths_after = find_all_paths(g_after, source, target)
metrics_after = compute_centrality_metrics(g_after)

mkpath(datadir("extra"))
mkpath(plotsdir())

data_path = datadir("extra", "defense_measures.jld2")

@save data_path g_before g_after paths_before paths_after metrics_before metrics_after protected_node source target

p1 = graphplot(
    g_before;
    names = string.(1:nv(g_before)),
    method = :spring,
    nodeshape = :circle,
    markersize = 0.25,
    fontsize = 8,
    arrow = true,
    title = "До защитной меры"
)

p2 = graphplot(
    g_after;
    names = string.(1:nv(g_after)),
    method = :spring,
    nodeshape = :circle,
    markersize = 0.25,
    fontsize = 8,
    arrow = true,
    title = "После защитной меры"
)

combined = plot(
    p1,
    p2;
    layout = (1, 2),
    size = (1000, 500)
)

plot_path = plotsdir("defense_measures.png")
savefig(combined, plot_path)
display(combined)

println("Защищаемый узел: ", protected_node)
println("Путей до защиты: ", length(paths_before))
println("Путей после защиты: ", length(paths_after))
println("Рёбер до защиты: ", ne(g_before))
println("Рёбер после защиты: ", ne(g_after))
println("График сохранён в: ", plot_path)
println("Данные сохранены в: ", data_path)