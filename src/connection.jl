
using Redis: RedisConnection, RedisConnectionBase

function getdatabase(;host::AbstractString="127.0.0.1", port::Integer=6379, password::AbstractString="", db::Integer=0)
    db_conn = RedisConnection(host=host, port=port, password=password, db=db)
    return db_conn
end


function listgraphs(db_conn::RedisConnectionBase)
    return execute_command(db_conn, ["GRAPH.LIST"])
end


function setconfig(db_conn::RedisConnectionBase, param_name::String, value)
    return execute_command(db_conn, flatten(["GRAPH.CONFIG", "SET", param_name, value]))
end


function getconfig(db_conn::RedisConnectionBase, param_name::String)
    return execute_command(db_conn, flatten(["GRAPH.CONFIG", "GET", param_name]))
end
