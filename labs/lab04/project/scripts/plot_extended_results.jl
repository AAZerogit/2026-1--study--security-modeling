using DrWatson
@quickactivate "project"
using Plots, DataFrames, CSV, Statistics

include(srcdir("simulation_extended.jl"))

results = load_extended_results()

# 1. Распределение стратегий Нападающего
strategy_counts = combine(
    groupby(results, :attacker_strategy),
    nrow => :count
)

bar(
    strategy_counts.attacker_strategy,
    strategy_counts.count,
    xlabel = "Стратегия Нападающего",
    ylabel = "Количество случаев",
    title = "Распределение стратегий Нападающего",
    legend = false,
)

savefig(plotsdir("extended_strategy_counts.png"))
display(current())

# 2. Как меняется выбор стратегии Нападающего при росте стоимости атаки
strategy_by_cost = combine(
    groupby(results, [:c_a, :attacker_strategy]),
    nrow => :count
)

plot(
    xlabel = "Стоимость атаки c_a",
    ylabel = "Количество случаев",
    title = "Выбор стратегии Нападающего при изменении c_a",
    legend = :topright,
)

for strategy in unique(strategy_by_cost.attacker_strategy)
    subset = strategy_by_cost[strategy_by_cost.attacker_strategy .== strategy, :]

    plot!(
        subset.c_a,
        subset.count,
        marker = :circle,
        label = strategy,
    )
end

savefig(plotsdir("extended_strategy_by_attack_cost.png"))
display(current())

# 3. Средний выигрыш Нападающего при росте стоимости атаки
ua_by_cost = combine(
    groupby(results, :c_a),
    :UA => mean => :UA_mean
)

plot(
    ua_by_cost.c_a,
    ua_by_cost.UA_mean,
    marker = :circle,
    xlabel = "Стоимость атаки c_a",
    ylabel = "Средний выигрыш Нападающего",
    title = "Средний выигрыш Нападающего при изменении c_a",
    legend = false,
)

savefig(plotsdir("extended_UA_by_attack_cost.png"))
display(current())

# 4. Тепловая карта: доля отказа от атаки
results.no_attack_selected = results.attacker_strategy .== "no_attack"

no_attack_heatmap = combine(
    groupby(results, [:c_a, :c_d]),
    :no_attack_selected => mean => :no_attack_share
)

heatmap(
    sort(unique(no_attack_heatmap.c_a)),
    sort(unique(no_attack_heatmap.c_d)),
    (x, y) -> no_attack_heatmap[
        (no_attack_heatmap.c_a .== x) .& (no_attack_heatmap.c_d .== y),
        :no_attack_share
    ][1],
    xlabel = "Стоимость атаки c_a",
    ylabel = "Стоимость защиты c_d",
    title = "Доля отказа Нападающего от атаки",
)

savefig(plotsdir("extended_no_attack_heatmap.png"))
display(current())