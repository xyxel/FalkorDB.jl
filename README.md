# FalkorDB Julia client

## Usage example

```julia
using FalkorDB

db_conn = getdatabase()
g = Graph("TestGraph", db_conn)

node1 = Node("FirstSimpleNode", ["Label1"], Dict("IntProp" => 1, "StringProp" => "node prop", "BoolProp" => true))
node2 = Node("SecondSimpleNode", ["Label2", "Label3"])
edge = Edge("SimpleEdge", node1, node2, Dict("IntProp" => 1, "StringProp" => "node prop", "BoolProp" => false))

addnode!(g, node1)
addnode!(g, node2)
addedge!(g, edge)
res = commit(g)

res = query(g, "MATCH (n1)-[e]->(n2) RETURN n1, e, n2")
println(res.results[1])

delete(g)
```

## Prerequisites

julia >= 1.6.0  
FalkorDB >= 4.0.0  

## Setup

1. FalkorDB needs to be running.

You can use [docker container](https://docs.falkordb.com/getting-started/configuration.html) for this. For example:

```
docker run -p 6379:6379 -p 3000:3000 -it --rm falkordb/falkordb:latest
```

2. add FalkorDB from the github repo

```julia
pkg> add https://github.com/xyxel/FalkorDB.jl
```

More information about package management: https://pkgdocs.julialang.org/v1/
