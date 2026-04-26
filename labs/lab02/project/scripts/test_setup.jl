using DrWatson

@quickactivate "project"

println("Проект активирован: ", projectdir())

packages = [
    "DrWatson",
    "Distributions",
    "StatsBase",
    "Plots",
    "DataFrames",
    "CSV",
    "JLD2",
    "Literate",
    "IJulia",
    "BenchmarkTools",
    "Quarto"
]

println("\nПроверка пакетов:")

for pkg in packages
    try
        eval(Meta.parse("using $pkg"))
        println("✓ $pkg")
    catch e
        println("✗ $pkg: ошибка загрузки")
        println(e)
    end
end

println("\nСтруктура проекта:")
println("Корень: ", projectdir())
println("Данные: ", datadir())
println("Код: ", srcdir())
println("Скрипты: ", scriptsdir())
println("Графики: ", plotsdir())