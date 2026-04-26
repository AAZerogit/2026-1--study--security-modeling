using Distributions
using Statistics

"""
    simulate_attacks(λ::Float64, T::Float64)

Моделирует поток атак за время наблюдения `T`.

Параметры:
- `λ` — интенсивность атак, среднее число атак в час;
- `T` — длительность наблюдения в часах.

Возвращает:
- `hourly_counts` — число атак по часам;
- `intervals` — интервалы между атаками;
- `attack_times` — моменты времени атак.
"""
function simulate_attacks(λ::Float64, T::Float64)
    # Моделирование числа атак по часам.
    # Каждый час число атак имеет распределение Пуассона с параметром λ.
    hourly_counts = rand(Poisson(λ), floor(Int, T))

    # Моделирование точных моментов атак через интервалы между событиями.
    # Для пуассоновского потока интервалы имеют экспоненциальное распределение.
    intervals = Float64[]
    total_time = 0.0

    while total_time < T
        τ = rand(Exponential(1 / λ))
        push!(intervals, τ)
        total_time += τ
    end

    # Если последний интервал вывел нас за пределы времени наблюдения,
    # убираем его.
    if total_time > T
        pop!(intervals)
    end

    attack_times = cumsum(intervals)

    return (
        hourly_counts = hourly_counts,
        intervals = intervals,
        attack_times = attack_times
    )
end

"""
    simulate_attacks(p::Dict)

Обёртка для запуска симуляции из словаря параметров.
"""
function simulate_attacks(p::Dict)
    return simulate_attacks(p[:λ], p[:T])
end