# Интерактивная визуализация графа атак

using DrWatson

@quickactivate "project"

using Graphs
using JLD2
using Random
using GraphRecipes
using Plots

include(srcdir("attack_graph.jl"))

# Построение графа

Random.seed!(42)

n = 12
edge_prob = 0.25

g = build_attack_graph(n, edge_prob, Dict(), [])

mkpath(datadir("extra"))

html_path = datadir("extra", "interactive_attack_graph.html")

# Статичная визуализация

mkpath(plotsdir())

p = graphplot(
    g;
    names = string.(1:nv(g)),
    method = :spring,
    nodeshape = :circle,
    markersize = 0.25,
    fontsize = 8,
    arrow = true,
    title = "Интерактивный граф атак"
)

png_path = plotsdir("interactive_attack_graph.png")
savefig(p, png_path)
display(p)

# Создание HTML-визуализации

open(html_path, "w") do io
    println(io, """
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>Interactive Attack Graph</title>
    <script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
    <style>
        #network {
            width: 100%;
            height: 700px;
            border: 1px solid lightgray;
        }
    </style>
</head>
<body>
    <h2>Интерактивный граф атак</h2>
    <div id="network"></div>

    <script>
        const nodes = new vis.DataSet([
""")

    for v in vertices(g)
        comma = v == nv(g) ? "" : ","
        println(io, "            { id: $v, label: 'Node $v' }$comma")
    end

    println(io, """
        ]);

        const edges = new vis.DataSet([
""")

    edge_list = collect(edges(g))

    for (i, e) in enumerate(edge_list)
        comma = i == length(edge_list) ? "" : ","
        println(io, "            { from: $(src(e)), to: $(dst(e)), arrows: 'to' }$comma")
    end

    println(io, """
        ]);

        const container = document.getElementById('network');
        const data = {
            nodes: nodes,
            edges: edges
        };

        const options = {
            physics: {
                enabled: true
            },
            edges: {
                smooth: true
            }
        };

        new vis.Network(container, data, options);
    </script>
</body>
</html>
""")
end

println("Интерактивная визуализация сохранена в: ", html_path)
println("Статичная визуализация сохранена в: ", png_path)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
