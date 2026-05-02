## Агентное моделирование распространения атаки
#
# Скрипт моделирует пошаговое распространение атаки по графу
# и сохраняет динамику заражённых узлов.

using DrWatson

@quickactivate "project"

using Graphs
using Random
using Plots
using JLD2

include(srcdir("attack_graph.jl"))

## Настройка модели

Random.seed!(42)

n = 20
edge_prob = 0.15
source = 1
steps = 15
p_spread = 0.4

g = build_attack_graph(n, edge_prob, Dict(), [])

## Моделирование распространения

infected = Set([source])
infected_counts = Int[]

for step in 1:steps
    new_infected = Set{Int}()

    for node in infected
        for neighbor in outneighbors(g, node)
            if !(neighbor in infected) && rand() < p_spread
                push!(new_infected, neighbor)
            end
        end
    end

    union!(infected, new_infected)
    push!(infected_counts, length(infected))

    println("Шаг $step: заражено узлов = ", length(infected))
end

## Визуализация и сохранение

mkpath(plotsdir())

p = plot(
    1:steps,
    infected_counts;
    marker = :circle,
    xlabel = "Шаг моделирования",
    ylabel = "Количество заражённых узлов",
    title = "Агентное распространение атаки",
    label = "infected nodes"
)

plot_path = plotsdir("agent_spread.png")
savefig(p, plot_path)
display(p)

mkpath(datadir("extra"))

data_path = datadir("extra", "agent_spread.jld2")

@save data_path g infected infected_counts source steps p_spread

println("График сохранён в: ", plot_path)
println("Данные сохранены в: ", data_path)