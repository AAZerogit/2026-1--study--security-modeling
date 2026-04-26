# # Дополнительное задание 6
#
# Выполняется проверка пуассоновской модели на данных логов.
# События группируются по часам, оценивается интенсивность потока,
# затем эмпирическое распределение сравнивается с распределением Пуассона.
#

using DrWatson

@quickactivate "project"

using CSV
using DataFrames
using Dates
using Statistics
using Distributions
using Plots
using JLD2

log_path = datadir("real_logs", "attacks.csv")

if !isfile(log_path)
    error("Файл с логами не найден: $log_path")
end

df = CSV.read(log_path, DataFrame)

# Преобразуем строку timestamp в DateTime
df.timestamp = DateTime.(df.timestamp, dateformat"yyyy-mm-dd HH:MM:SS")

# Округляем время до часа
df.hour = DateTime.(Dates.year.(df.timestamp),
                    Dates.month.(df.timestamp),
                    Dates.day.(df.timestamp),
                    Dates.hour.(df.timestamp))

# Считаем количество атак по часам
hourly_df = combine(groupby(df, :hour), nrow => :count)

# Оценка интенсивности λ как среднего числа атак за час
λ_hat = mean(hourly_df.count)

println("Количество записей в логах: ", nrow(df))
println("Количество часов наблюдения: ", nrow(hourly_df))
println("Оценка интенсивности λ̂ = ", λ_hat)

mkpath(plotsdir())
mkpath(datadir("real_logs_results"))

# Гистограмма числа атак по часам
p = histogram(
    hourly_df.count;
    bins = 0:maximum(hourly_df.count),
    normalize = :probability,
    label = "Эмпирическое распределение",
    xlabel = "Число атак за час",
    ylabel = "Вероятность",
    title = "Проверка пуассоновской модели на логах"
)

x_vals = 0:maximum(hourly_df.count)
theor_probs = pdf.(Poisson(λ_hat), x_vals)

plot!(
    p,
    x_vals,
    theor_probs;
    line = :stem,
    marker = :circle,
    label = "Poisson(λ̂=$(round(λ_hat, digits=2)))",
    lw = 2
)

plot_path = plotsdir("real_data_check.png")
savefig(p, plot_path)
display(p)

data_path = datadir("real_logs_results", "real_data_check.jld2")
@save data_path df hourly_df λ_hat

println("График сохранён в: ", plot_path)
println("Данные сохранены в: ", data_path)