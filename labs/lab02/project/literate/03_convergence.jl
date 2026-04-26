# # Исследование сходимости оценки вероятности
#
# Здесь исследуется, как эмпирическая оценка вероятности события
# `N > 10` сходится к теоретическому значению при увеличении размера выборки.
#

using DrWatson

@quickactivate "project"

using Distributions
using JLD2
using Plots

include(scriptsdir("params.jl"))

params = default_params

λ = params[:λ]

# Теоретическая вероятность события: больше 10 атак за час
theor_prob = 1 - cdf(Poisson(λ), 10)

# Размеры выборки: от 10 до 100000 часов
sample_sizes = [10, 30, 100, 300, 1000, 3000, 10000, 30000, 100000]

# Сюда будем сохранять эмпирические оценки
estimates = Float64[]

for n in sample_sizes
    sample = rand(Poisson(λ), n)
    estimate = count(sample .> 10) / n
    push!(estimates, estimate)

    println("n = $n, оценка = $estimate")
end

mkpath(plotsdir())

p = plot(
    sample_sizes,
    estimates;
    xscale = :log10,
    marker = :circle,
    label = "Эмпирическая оценка",
    xlabel = "Размер выборки, часов",
    ylabel = "P(N > 10)",
    title = "Сходимость оценки вероятности"
)

hline!(
    p,
    [theor_prob];
    label = "Теоретическое значение",
    linestyle = :dash
)

plot_filename = plotsdir("convergence.png")
savefig(p, plot_filename)
display(p)

println("Теоретическая вероятность P(N > 10) = ", theor_prob)
println("График сохранён в: ", plot_filename)

# Дополнительно сохраняем данные сходимости
mkpath(datadir("convergence"))

data = Dict(
    :λ => λ,
    :sample_sizes => sample_sizes,
    :estimates => estimates,
    :theor_prob => theor_prob
)

data_filename = datadir("convergence", "convergence.jld2")

@save data_filename data

println("Данные сходимости сохранены в: ", data_filename)