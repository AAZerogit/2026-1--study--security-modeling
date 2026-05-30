using DrWatson
@quickactivate "project"
include(srcdir("simulation_extended.jl"))

println("Запуск расширенной модели...")
results = main_extended_simulations()
println("Готово! Сохранено строк: ", nrow(results))