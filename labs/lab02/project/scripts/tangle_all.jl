using DrWatson

@quickactivate "project"

using Literate

input_dir = projectdir("literate")

files = sort(filter(f -> endswith(f, ".jl"), readdir(input_dir)))

for file in files
    input_file = joinpath(input_dir, file)
    name = splitext(file)[1]

    script_output = scriptsdir("generated", name)
    markdown_output = projectdir("markdown", name)
    notebook_output = projectdir("notebooks", name)

    mkpath(script_output)
    mkpath(markdown_output)
    mkpath(notebook_output)

    Literate.script(input_file, script_output)
    Literate.markdown(input_file, markdown_output; flavor = Literate.QuartoFlavor())
    Literate.notebook(input_file, notebook_output)

    println("Сгенерировано для: ", name)
end