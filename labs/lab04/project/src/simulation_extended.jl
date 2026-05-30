using LinearAlgebra
using DataFrames, CSV
using DrWatson
using Statistics

function build_extended_payoff_matrices(V::Vector{Float64}, c_a::Float64, c_d::Float64)
    A = zeros(3, 3)
    D = zeros(3, 3)

    for i = 1:3, j = 1:3
        if i == 3
            A[i, j] = 0.0
            D[i, j] = j == 3 ? 0.0 : -c_d
        elseif j == 3
            A[i, j] = V[i] - c_a
            D[i, j] = -V[i]
        elseif i == j
            A[i, j] = -c_a
            D[i, j] = -c_d
        else
            A[i, j] = V[i] - c_a
            D[i, j] = -V[i] - c_d
        end
    end

    return A, D
end

function pure_nash_equilibria(A::Matrix{Float64}, D::Matrix{Float64})
    equilibria = []

    for i = 1:size(A, 1), j = 1:size(A, 2)
        attacker_best = A[i, j] == maximum(A[:, j])
        defender_best = D[i, j] == maximum(D[i, :])

        if attacker_best && defender_best
            push!(equilibria, (i, j))
        end
    end

    return equilibria
end

function strategy_name(player::String, index::Int)
    if player == "attacker"
        return ["attack_1", "attack_2", "no_attack"][index]
    else
        return ["defend_1", "defend_2", "no_defense"][index]
    end
end

function fallback_strategy(A::Matrix{Float64}, D::Matrix{Float64})
    attacker_scores = vec(mean(A, dims = 2))
    attacker_index = argmax(attacker_scores)

    defender_scores = vec(mean(D, dims = 1))
    defender_index = argmax(defender_scores)

    return attacker_index, defender_index
end

function run_extended_simulation(params::Dict)
    V = params["V"]
    c_a = params["c_a"]
    c_d = params["c_d"]

    A, D = build_extended_payoff_matrices(V, c_a, c_d)
    equilibria = pure_nash_equilibria(A, D)

    if length(equilibria) > 0
        i, j = equilibria[1]
        solution_type = "pure_nash"
    else
        i, j = fallback_strategy(A, D)
        solution_type = "fallback_best_average"
    end

    attacker_strategy = strategy_name("attacker", i)
    defender_strategy = strategy_name("defender", j)

    UA = A[i, j]
    UD = D[i, j]

    return Dict(
        "V1" => V[1],
        "V2" => V[2],
        "c_a" => c_a,
        "c_d" => c_d,
        "solution_type" => solution_type,
        "equilibrium_count" => length(equilibria),
        "attacker_strategy" => attacker_strategy,
        "defender_strategy" => defender_strategy,
        "UA" => UA,
        "UD" => UD,
    )
end

function generate_extended_params()
    dicts = []

    for v1 in [5.0, 10.0, 15.0], v2 in [5.0, 10.0, 15.0]
        for c_a in [0.0, 1.0, 3.0, 6.0, 10.0, 15.0, 20.0]
            for c_d in [0.0, 1.0, 3.0, 6.0, 10.0, 15.0, 20.0]
                push!(dicts, Dict("V" => [v1, v2], "c_a" => c_a, "c_d" => c_d))
            end
        end
    end

    return dicts
end

function main_extended_simulations()
    params_list = generate_extended_params()
    rows = []

    for p in params_list
        res = run_extended_simulation(p)
        push!(rows, res)
    end

    results = DataFrame(rows)

    mkpath(datadir("sims"))
    CSV.write(datadir("sims", "extended_results.csv"), results)

    return results
end

function load_extended_results()
    path = datadir("sims", "extended_results.csv")

    if isfile(path)
        return CSV.read(path, DataFrame)
    else
        error("Файл с результатами не найден. Сначала выполните main_extended_simulations().")
    end
end