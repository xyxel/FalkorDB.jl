using Test


@testset "Check db commands" begin
    db_conn = getdatabase()

    setconfig(db_conn, "MAX_QUEUED_QUERIES", 500)
    @test getconfig(db_conn, "MAX_QUEUED_QUERIES") == ["MAX_QUEUED_QUERIES", 500]
    setconfig(db_conn, "MAX_QUEUED_QUERIES", 600)
    @test getconfig(db_conn, "MAX_QUEUED_QUERIES") == ["MAX_QUEUED_QUERIES", 600]
    @test length(getconfig(db_conn, "*")) > 2
end
