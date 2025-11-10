using Test

using FalkorDB: Graph, getdatabase, setconfig, getconfig, query, ro_query, profile, slowlog, listgraphs


function test_command_basic()
    @testset "Basic check commands" begin
        db_conn = getdatabase()
        g = Graph("TestGraph", db_conn)
        try
            @test query(g, "RETURN null").results[1] === nothing

            @test ro_query(g, "RETURN [1, null, 'test', 3.0, false]").results[1] == [1, nothing, "test", 3.0, false]

            @test occursin("Records produced: 1", profile(g, "RETURN null")[1])

            commands_in_log =  [log_entry[2] for log_entry in slowlog(g)]
            @test "GRAPH.QUERY" in commands_in_log
            @test "GRAPH.RO_QUERY" in commands_in_log
            @test "GRAPH.PROFILE" in commands_in_log

            setconfig(g, "MAX_QUEUED_QUERIES", 500)
            @test getconfig(g, "MAX_QUEUED_QUERIES") == ["MAX_QUEUED_QUERIES", 500]
            setconfig(g, "MAX_QUEUED_QUERIES", 600)
            @test getconfig(g, "MAX_QUEUED_QUERIES") == ["MAX_QUEUED_QUERIES", 600]
            @test length(getconfig(g, "*")) > 2
        finally
            delete(g)
        end
    end
end


function test_listgraphs_command()
    @testset "Check listgraphs command" begin
        db_conn = getdatabase()

        g1 = Graph("FirstTestGraph", db_conn)
        g2 = Graph("SecondTestGraph", db_conn)

        try
            node1 = Node("FirstSimpleNode", ["Label1"], Dict("IntProp" => 1, "StringProp" => "node prop", "BoolProp" => true))
            addnode!(g1, node1)
            commit(g1)

            @test listgraphs(db_conn) == ["FirstTestGraph"]

            node2 = Node("SecondSimpleNode", ["Label2", "Label3"])
            edge = Edge("SimpleEdge", node1, node2, Dict("IntProp" => 1, "StringProp" => "node prop", "BoolProp" => false))
            addnode!(g2, node1)
            addnode!(g2, node2)
            addedge!(g2, edge)
            commit(g2)

            @test listgraphs(db_conn) == ["FirstTestGraph", "SecondTestGraph"]

            delete(g1)
            @test listgraphs(db_conn) == ["SecondTestGraph"]

            delete(g2)
            @test listgraphs(db_conn) == []
        finally
            for g in listgraphs(db_conn)
                delete(g)
            end
        end
    end
end


@testset "Check FalkorDB commands" begin
    test_command_basic()
    test_listgraphs_command()
end
