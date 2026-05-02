using DrWatson

@quickactivate "project"

using Graphs
using DataFrames
using CSV
using JLD2
using Random

include(srcdir("attack_graph.jl"))

Random.seed!(42)

n = 15
edge_prob = 0.25

g = build_attack_graph(n, edge_prob, Dict(), [])

metrics = compute_centrality_metrics(g)

centrality_df = DataFrame(
    node = 1:nv(g),
    in_degree = metrics[:in_degree],
    out_degree = metrics[:out_degree],
    betweenness = metrics[:betweenness],
    closeness = metrics[:closeness],
    pagerank = metrics[:pagerank]
)

mkpath(datadir("extra"))

csv_path = datadir("extra", "centrality_compare.csv")
CSV.write(csv_path, centrality_df)

data_path = datadir("extra", "centrality_compare.jld2")
@save data_path g metrics centrality_df

println("Топ-5 по входящей степени:")
println(first(sort(centrality_df, :in_degree, rev = true), 5))

println("\nТоп-5 по PageRank:")
println(first(sort(centrality_df, :pagerank, rev = true), 5))

println("\nТаблица сохранена в: ", csv_path)
println("Данные сохранены в: ", data_path)