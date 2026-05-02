using Graphs
using LinearAlgebra

"""
    build_attack_graph(n, edge_prob, vulnerabilities, trust_relations)

Создаёт ориентированный граф атак с заданными параметрами.
"""
function build_attack_graph(n, edge_prob, vulnerabilities, trust_relations)
    g = SimpleDiGraph(n)

    for i in 1:n, j in 1:n
        if i != j && rand() < edge_prob
            add_edge!(g, i, j)
        end
    end

    for (u, v) in trust_relations
        add_edge!(g, u, v)
    end

    return g
end

"""
    find_all_paths(g, source, target)

Рекурсивный поиск всех простых путей от source до target.
"""
function find_all_paths(g, source, target)
    paths = Vector{Vector{Int}}()

    function dfs(current, path)
        if current == target
            push!(paths, copy(path))
            return
        end

        for neighbor in outneighbors(g, current)
            if !(neighbor in path)
                push!(path, neighbor)
                dfs(neighbor, path)
                pop!(path)
            end
        end
    end

    dfs(source, [source])
    return paths
end

"""
    compute_centrality_metrics(g)

Вычисляет основные метрики центральности.
"""
function compute_centrality_metrics(g)
    indeg = indegree(g)
    outdeg = outdegree(g)
    betweenness = betweenness_centrality(g)
    closeness = closeness_centrality(g)
    pagerank = simple_pagerank(g)

    return Dict(
        :in_degree => indeg,
        :out_degree => outdeg,
        :betweenness => betweenness,
        :closeness => closeness,
        :pagerank => pagerank,
    )
end

"""
    assign_edge_weights(g, cvss_scores)

Присваивает каждому ребру вес на основе CVSS-оценок.
Если для ребра нет оценки, используется вес 0.5.
"""
function assign_edge_weights(g, cvss_scores)
    weights = Dict{Edge{Int}, Float64}()

    for e in edges(g)
        u, v = src(e), dst(e)
        key = (u, v)
        weight = get(cvss_scores, key, 0.5)
        weights[e] = weight
    end

    return weights
end

"""
    most_likely_path(g, source, target, weights)

Находит путь с максимальным произведением вероятностей.
"""
function most_likely_path(g, source, target, weights)
    n = nv(g)
    distmx = fill(Inf, n, n)

    for e in edges(g)
        u, v = src(e), dst(e)
        weight = get(weights, e, 0.5)
        weight = clamp(weight, eps(Float64), 1.0)
        distmx[u, v] = -log(weight)
    end

    state = dijkstra_shortest_paths(g, source, distmx)
    path = enumerate_paths(state, target)

    if isempty(path)
        return Int[], 0.0
    end

    probability = 1.0

    for i in 1:(length(path) - 1)
        e = Edge(path[i], path[i + 1])
        probability *= get(weights, e, 0.5)
    end

    return path, probability
end

"""
    simple_pagerank(g; α=0.85, max_iter=100, tol=1e-6)

Итеративная реализация PageRank для ориентированного графа.
"""
function simple_pagerank(g; α=0.85, max_iter=100, tol=1e-6)
    n = nv(g)
    pr = fill(1.0 / n, n)

    for _ in 1:max_iter
        new_pr = fill((1.0 - α) / n, n)

        sink_rank = sum(pr[v] for v in 1:n if outdegree(g, v) == 0)
        new_pr .+= α * sink_rank / n

        for v in 1:n
            for u in inneighbors(g, v)
                if outdegree(g, u) > 0
                    new_pr[v] += α * pr[u] / outdegree(g, u)
                end
            end
        end

        if norm(new_pr - pr, 1) < tol
            return new_pr
        end

        pr = new_pr
    end

    return pr
end