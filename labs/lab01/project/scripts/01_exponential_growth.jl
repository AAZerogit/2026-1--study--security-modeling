# # Экспоненциальный рост
# 
# **Цель:** Исследовать решение уравнения du/dt = αu.
# 
# ## Инициализация проекта и загрузка пакетов

using DrWatson
@quickactivate "project"

using DifferentialEquations
using Plots
using DataFrames
using JLD2

# Создаём папки для результатов
script_name = splitdir(basename(@__FILE__))[2]
script_name = splitext(script_name)[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

# ## Определение модели
# 
# Уравнение экспоненциального роста:
# 
# $$ \frac{du}{dt} = \alpha u, \quad u(0) = u_0 $$
# 
# где:
# - $u$ — текущее значение растущей величины
# - $\alpha$ — константа роста (мальтузианский параметр)

function exponential_growth!(du, u, p, t)
    \alpha = p
    du[1] = \alpha * u[1]
end

# ## Первый запуск с параметрами по умолчанию
# 
# Зададим начальные параметры:
# - $u_0 = 1.0$ — начальная популяция
# - $\alpha = 0.3$ — скорость роста
# - $t \in [0, 10]$ — временной интервал

u0 = [1.0]
\alpha = 0.3
tspan = (0.0, 10.0)

# Создаём и решаем задачу
prob = ODEProblem(exponential_growth!, u0, tspan, \alpha)
sol = solve(prob, Tsit5(), saveat=0.1)

# ## Визуализация результатов
# 
# Построим график решения $u(t)$:

plot(sol, 
     label="u(t)", 
     xlabel="Время t", 
     ylabel="Популяция u", 
     title="Экспоненциальный рост (α = $α)", 
     lw=2, 
     legend=:topleft)

# Сохраним график в папку plots
savefig(plotsdir(script_name, "exponential_growth_α=$α.png"))

# ## Анализ результатов
# 
# Создадим таблицу с данными:

df = DataFrame(t=sol.t, u=first.(sol.u))
println("Первые 5 строк результатов:")
println(first(df, 5))

# Вычислим время удвоения популяции:
# 
# $$ T_2 = \frac{\ln 2}{\alpha} $$

u_final = last(sol.u)[1]
doubling_time = log(2) / \alpha
println("\nАналитическое время удвоения: ", round(doubling_time, digits=2))

# ## Сохранение всех результатов
# 
# Сохраним данные в JLD2-формате для последующего анализа:

@save datadir(script_name, "all_results.jld2") df
println("\nРезультаты сохранены в: ", datadir(script_name, "all_results.jld2"))