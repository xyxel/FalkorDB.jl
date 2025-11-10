using Redis: execute_command, flatten


function commit(g::Graph)
    if (length(g.nodes) == 0 && length(g.edges) == 0)
        return
    end

    items = vcat(string.(values(g.nodes)), string.(g.edges))

    query_str = "CREATE " * join(items, ",")
    return query(g, query_str)
end


function query(g::Graph, q::String)
    response = execute_command(g.redis_conn, flatten(["GRAPH.QUERY", g.id, q, "--compact"]))
    return QueryResult(g, response)
end


function ro_query(g::Graph, q::String)
    response = execute_command(g.redis_conn, flatten(["GRAPH.RO_QUERY", g.id, q, "--compact"]))
    return QueryResult(g, response)
end


function profile(g::Graph, q::String)
    return execute_command(g.redis_conn, flatten(["GRAPH.PROFILE", g.id, q, "--compact"]))
end


function slowlog(g::Graph)
    return execute_command(g.redis_conn, flatten(["GRAPH.SLOWLOG", g.id]))
end


function flush!(g::Graph)
    commit(g)
    g.nodes = Dict()
    g.edges = Array{Edge, 1}()
end


function delete(g::Graph)
    execute_command(g.redis_conn, flatten(["GRAPH.DELETE", g.id]))
end


function merge(g::Graph, pattern::String)
    query_str = "MERGE $pattern"
    return query(g, query_str)
end


function explain(g::Graph, q::String)
    return execute_command(g.redis_conn, flatten(["GRAPH.EXPLAIN", g.id, q, "--compact"]))
end


function copygraph(g::Graph, newid::String)
    execute_command(g.redis_conn, flatten(["GRAPH.COPY", g.id, newid]))
    return Graph(newid, g.redis_conn)
end
