using Test
using FalkorDB


function test_command_basic()
    @testset "Basic check commands" begin
        db_conn = getdatabase()
        g = Graph("TestGraph", db_conn)
        try
            @test query(g, "RETURN null").results[1][1] === nothing

            @test ro_query(g, "RETURN [1, null, 'test', 3.0, false]").results[1][1] == [1, nothing, "test", 3.0, false]

            @test occursin("Records produced: 1", profile(g, "RETURN null")[1])

            commands_in_log =  [log_entry[2] for log_entry in slowlog(g)]
            @test "GRAPH.QUERY" in commands_in_log
            @test "GRAPH.RO_QUERY" in commands_in_log
            @test "GRAPH.PROFILE" in commands_in_log
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

            @test "FirstTestGraph" in listgraphs(db_conn)
            @test ~("SecondTestGraph" in listgraphs(db_conn))

            node2 = Node("SecondSimpleNode", ["Label2", "Label3"])
            edge = Edge("SimpleEdge", node1, node2, Dict("IntProp" => 1, "StringProp" => "node prop", "BoolProp" => false))
            addnode!(g2, node1)
            addnode!(g2, node2)
            addedge!(g2, edge)
            commit(g2)

            @test "FirstTestGraph" in listgraphs(db_conn)
            @test "SecondTestGraph" in listgraphs(db_conn)

            delete(g1)
            @test ~("FirstTestGraph" in listgraphs(db_conn))
            @test "SecondTestGraph" in listgraphs(db_conn)

            delete(g2)
            @test ~("FirstTestGraph" in listgraphs(db_conn))
            @test ~("SecondTestGraph" in listgraphs(db_conn))
        finally
            if g1.id in listgraphs(db_conn)
                delete(g1)
            end
            if g2.id in listgraphs(db_conn)
                delete(g2)
            end
        end
    end
end


function test_copy_command()
    @testset "Check copy command" begin
        db_conn = getdatabase()
        g1 = Graph("TestGraph", db_conn)
        g2 = Graph("CopiedTestGraph", db_conn)
        try
            nodealias = "FirstSimpleNode"
            node1 = Node(nodealias, ["Label1"])
            addnode!(g1, node1)
            commit(g1)
            
            g2 = copygraph(g1, "CopiedTestGraph")

            @test "CopiedTestGraph" in listgraphs(db_conn)
            @test query(g2, "MATCH (n) RETURN n").results[1][1].labels == ["Label1"]
        finally
            if g1.id in listgraphs(db_conn)
                delete(g1)
            end
            if g2.id in listgraphs(db_conn)
                delete(g2)
            end
        end
    end
end


function test_mandatory_constraint()
    @testset "Check mandatory constraint" begin
        db_conn = getdatabase()
        g = Graph("TestGraph", db_conn)
        try
            node = Node("FirstSimpleNode", ["Label1"])
            addnode!(g, node)
            commit(g)

            @test create_constraint(g, CONSTRAINT_TYPE_MANDATORY, ENTITY_TYPE_NODE, "label1", ["a", "b"]) == "PENDING"
            @test list_constraints(g)[1]["type"] == "MANDATORY"
            @test list_constraints(g)[1]["properties"] == ["a", "b"]
            @test drop_constraint(g, CONSTRAINT_TYPE_MANDATORY, ENTITY_TYPE_NODE, "label1", ["a", "b"]) == "OK"

        finally
            delete(g)
        end
    end
end


@testset "Check FalkorDB commands" begin
    test_command_basic()
    test_listgraphs_command()
    test_copy_command()
    test_mandatory_constraint()
end
