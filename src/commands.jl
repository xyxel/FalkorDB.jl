using Redis: execute_command, flatten


const CONSTRAINT_TYPE_MANDATORY = "MANDATORY"
const CONSTRAINT_TYPE_UNIQUE = "UNIQUE"

const ENTITY_TYPE_NODE = "NODE"
const ENTITY_TYPE_RELATIONSHIP = "RELATIONSHIP"


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


function handle_constraint(g::Graph,
                           constraint_action::String,
                           constraint_type::String,
                           entity_type::String,
                           label::String,
                           props::Vector)
    cmd = vcat(["GRAPH.CONSTRAINT",
                constraint_action,
                g.id,
                constraint_type,
                entity_type,
                label,
                "PROPERTIES",
                length(props)],
                props)
    return execute_command(g.redis_conn, flatten(cmd))
end


function create_constraint(g::Graph,
                           constraint_type::String,
                           entity_type::String,
                           label::String,
                           props::Vector)
    return handle_constraint(g, "CREATE", constraint_type, entity_type, label, props)
end


function drop_constraint(g::Graph,
                         constraint_type::String,
                         entity_type::String,
                         label::String,
                         props::Vector)
    return handle_constraint(g, "DROP", constraint_type, entity_type, label, props)
end


function list_constraints(g::Graph)
    result = call_procedure(g, "DB.CONSTRAINTS").results
    constraints = Vector{Dict{String, Any}}()
    for row in result
        push!(constraints, Dict("type" => row[1],
                                "label" => row[2],
                                "properties" => row[3],
                                "entitytype" => row[4],
                                "status" => row[5]))
    end
    return constraints
end
