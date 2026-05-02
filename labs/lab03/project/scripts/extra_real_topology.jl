using DrWatson

@quickactivate "project"

using Graphs
using GraphRecipes
using Plots
using DataFrames
using CSV
using JLD2

# Учебный пример топологии сети.
# Узлы: рабочая станция, веб-сервер, БД, админский узел и внутренняя сеть.

edges_df = DataFrame(
    source = [1, 1, 2, 2, 3, 4, 5],
    target = [2, 3, 4, 5, 5, 6, 6]
)

n = maximum(vcat(edges_df.source, edges_df.target))
g = SimpleDiGraph(n)

for row in eachrow(edges_df)
    add_edge!(g, row.source, row.target)
end

node_names = [
    "Workstation",
    "Web server",
    "Database",
    "Admin host",
    "Internal app",
    "Domain controller"
]

mkpath(datadir("extra"))
csv_path = datadir("extra", "real_topology_edges.csv")
CSV.write(csv_path, edges_df)

data_path = datadir("extra", "real_topology.jld2")
@save data_path g edges_df node_names

mkpath(plotsdir())

p = graphplot(
    g;
    names = node_names,
    method = :spring,
    nodeshape = :circle,
    markersize = 0.25,
    fontsize = 7,
    arrow = true,
    title = "Топология сети как граф атак"
)

plot_path = plotsdir("real_topology.png")
savefig(p, plot_path)

println("Количество узлов: ", nv(g))
println("Количество рёбер: ", ne(g))
println("Таблица рёбер сохранена в: ", csv_path)
println("Данные сохранены в: ", data_path)
println("График сохранён в: ", plot_path)