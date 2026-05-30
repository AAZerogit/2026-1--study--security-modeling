# Нападающий выбирает один из двух активов для атаки, а Защитник выбирает один
# из двух активов для защиты. Для каждой пары стратегий строятся платёжные
# матрицы, после чего определяется равновесие и выполняется серия симуляций.

using DrWatson
@quickactivate "project"

using LinearAlgebra
using DataFrames, CSV
using Plots
using Statistics

# ## Построение платёжных матриц
#
# Функция строит две матрицы: `A` для Нападающего и `D` для Защитника.
# Если Нападающий атакует незащищённый актив, он получает выигрыш `V[i] - c_a`.
# Если Защитник защищает атакуемый актив, атака не приносит выгоды, а Нападающий
# несёт только затраты `c_a`.

function build_payoff_matrices(V::Vector{Float64}, c_a::Float64, c_d::Float64)
    n = length(V)
    A = zeros(n, n) # Attacker
    D = zeros(n, n) # Defender
    for i = 1:n, j = 1:n
        if i != j
             A[i, j] = V[i] - c_a
             D[i, j] = -V[i] - c_d
        else
             A[i, j] = -c_a
             D[i, j] = -c_d
        end
    end
    return A, D
end

# ## Поиск равновесия для игры 2×2
#
# Сначала проверяется наличие равновесия в чистых стратегиях. Если оно есть,
# игроки выбирают конкретные стратегии с вероятностью 1. Если чистого равновесия
# нет, вычисляется смешанное равновесие через условие безразличия игроков.

function mixed_nash_2x2(A::Matrix{Float64}, D::Matrix{Float64})
    for i = 1:2, j = 1:2
        if A[i, j] >= A[3-i, j] && D[i, j] >= D[i, 3-j]
            p = zeros(2);
            p[i] = 1.0
            q = zeros(2);
            q[j] = 1.0
            return (p = p, q = q, type = "pure")
        end
    end

    denomA = (A[1, 1] - A[2, 1]) - (A[1, 2] - A[2, 2])
    if abs(denomA) > 1e-10
         q1 = (A[2, 2] - A[1, 2]) / denomA
         q1 = clamp(q1, 0.0, 1.0)
    else
         q1 = 0.5
    end
    q = [q1, 1 - q1]

    denomD = (D[1, 1] - D[1, 2]) - (D[2, 1] - D[2, 2])
    if abs(denomD) > 1e-10
         p1 = (D[2, 2] - D[2, 1]) / denomD
         p1 = clamp(p1, 0.0, 1.0)
    else
         p1 = 0.5
    end
    p = [p1, 1 - p1]

    return (p = p, q = q, type = "mixed")
end

# ## Одна симуляция
#
# Для одного набора параметров строятся платёжные матрицы, находится равновесие
# и рассчитываются выигрыши Нападающего и Защитника.

function run_simulation(params::Dict)
    V = params["V"]
    c_a = params["c_a"]
    c_d = params["c_d"]
    A, D = build_payoff_matrices(V, c_a, c_d)
    eq = mixed_nash_2x2(A, D)

    if eq.type == "pure"
        i = argmax(eq.p)
        j = argmax(eq.q)
        UA = A[i, j]
        UD = D[i, j]
    else
        UA = eq.p' * A * eq.q
        UD = eq.p' * D * eq.q
    end

    return Dict(
        "p_1" => eq.p[1],
        "p_2" => eq.p[2],
        "q_1" => eq.q[1],
        "q_2" => eq.q[2],
        "type" => eq.type,
        "UA" => UA,
        "UD" => UD,
        "V1" => V[1],
        "V2" => V[2],
        "c_a" => c_a,
        "c_d" => c_d,
    )
end

# ## Генерация набора параметров
#
# Для исследования модели перебираются разные значения ценностей активов,
# стоимости атаки и стоимости защиты.

function generate_params()
    dicts = []
    for v1 in [5.0, 10.0, 15.0], v2 in [5.0, 10.0, 15.0]
        for c_a in [0.0, 1.0, 3.0], c_d in [0.0, 1.0, 3.0]
            push!(dicts, Dict("V" => [v1, v2], "c_a" => c_a, "c_d" => c_d))
        end
    end
    return dicts
end

# ## Основная функция симуляций
#
# Все варианты параметров рассчитываются и сохраняются в CSV-файл.

function main_simulations()
    params_list = generate_params()
    rows = []

    for p in params_list
        res = run_simulation(p)    # теперь всегда вычисляем
        push!(rows, res)
    end

    results = DataFrame(rows)

    mkpath(datadir("sims")) # убедимся, что папка существует
    CSV.write(datadir("sims", "results.csv"), results)
    return results
end

# ## Загрузка результатов
#
# Если результаты уже были сохранены, их можно загрузить из файла.

function load_results()
    path = datadir("sims", "results.csv")
    if isfile(path)
         return CSV.read(path, DataFrame)
    else
         error("Файл с результатами не найден. Сначала выполните main_simulations().")
    end
end

# ## Запуск базовой модели
#
# Выполним симуляции и сохраним таблицу результатов.

println("Запуск симуляций базовой модели...")
results = main_simulations()
println("Готово! Сохранено строк: ", nrow(results))

# ## График вероятности атаки на первый актив
#
# На графике показано, как вероятность атаки на первый актив зависит от отношения
# ценностей активов `V1 / V2` при фиксированных затратах `c_a = 1` и `c_d = 1`.

filtered = results[(results.c_a .== 1.0) .& (results.c_d .== 1.0), :]
ratio = filtered.V1 ./ filtered.V2

scatter(
    ratio,
    filtered.p_1,
    group = filtered.type,
    xlabel = "V1 / V2",
    ylabel = "p1 (вероятность атаки на актив 1)",
    title = "Стратегия Нападающего (c_a=1, c_d=1)",
    legend = :topright,
)

savefig(plotsdir("p1_vs_ratio.png"))
display(current())

# ## Тепловая карта выигрыша Нападающего
#
# Тепловая карта показывает средний выигрыш Нападающего при разных значениях
# ценностей первого и второго активов.

grp = groupby(filtered, [:V1, :V2])
summ = combine(grp, :UA => mean => :UA_mean)

heatmap(
    sort(unique(summ.V1)),
    sort(unique(summ.V2)),
    (x, y) -> summ[(summ.V1 .== x) .& (summ.V2 .== y), :UA_mean][1],
    xlabel = "V1",
    ylabel = "V2",
    title = "Средний выигрыш Нападающего",
)

savefig(plotsdir("heatmap_UA.png"))
display(current())
