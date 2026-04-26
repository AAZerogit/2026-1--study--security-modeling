#!/usr/bin/env julia
# add_packages.jl

using Pkg
Pkg.activate(".")  # Активируем текущий проект (ИСПРАВЛЕНО: activate, а не active)

## ОСНОВНЫЕ ПАКЕТЫ ДЛЯ РАБОТЫ
packages = [
    "DrWatson",              # Организация проекта
    "DifferentialEquations", # Решение ОДУ
    "Plots",                 # Визуализация
    "DataFrames",            # Таблицы данных
    "CSV",                   # Работа с CSV
    "JLD2",                  # Сохранение данных (добавил из методички)
    "Literate",              # Литературное программирование (добавил)
    "IJulia",                # Jupyter notebook (добавил)
    "BenchmarkTools",        # Бенчмаркинг (добавил)
    "Quarto"                 # Создание отчетов (добавил)
]

println("Установка базовых пакетов...")
Pkg.add(packages)
println("\n✅ Все пакеты установлены!")
println("Для проверки: using DrWatson, DifferentialEquations, Plots")