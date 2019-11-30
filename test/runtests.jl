using PolygonClipping
pc = PolygonClipping
using Test

@testset "iterators" begin
    poly = Polygon()
    vert1 = Vertex(1,2)
    push!(poly, vert1)
    for i = 1:10
        push!(poly, Vertex(rand(2)))
    end

    i = 0
    for vert in poly
        i += 1
    end
    i

    @test i == 11
    @test length(poly) == 11

    vert1 = poly.start
    vert2 = vert1.next
    for i = 1:10
        @test vert1 === vert2.prev
        vert1 = vert1.next
        vert2 = vert2.next
    end
end

@testset "vertex constructors" begin
    vert1 = Vertex(0,0)
    vert2 = Vertex(2,1)
    poly = Polygon()
    push!(poly, vert1)
    push!(poly, vert2)
    a = Vertex(poly.start, poly.start.next, 0.25)
    @test a.location == [0.5,0.25]
    @test poly.start === vert1
    @test a.prev === vert1
    @test a.next === vert2
    @test vert1.next === a
    @test vert2.prev === a
end

@testset "point in polygon" begin
    poly1 = Polygon()
    push!(poly1, Vertex(0,0))
    push!(poly1, Vertex(1,0))
    push!(poly1, Vertex(1,1))
    push!(poly1, Vertex(0,1))
    @test isinside(Vertex(0.5,0.5), poly1) == true
    @test isinside(Vertex(-0.5,0.5), poly1) == false
    @test_throws VertexException isinside(Vertex(0,0), poly1)
    @test_throws VertexException isinside(Vertex(1,0), poly1)
    @test_throws EdgeException isinside(Vertex(0.5,0.0), poly1)
    for i = 1:100
        @test isinside(Vertex(rand(2)), poly1) == true
    end

    # add non-convexity
    push!(poly1, Vertex(0.9,0.5))
    @test isinside(Vertex(0.9,0.9), poly1) == true
    @test isinside(Vertex(0.9,0.9), poly1) == true
    @test isinside(Vertex(0.99,0.1), poly1) == true
    @test isinside(Vertex(0.99,0.5), poly1) == true
    @test isinside(Vertex(0.9,0.1), poly1) == true

    # add self-intersection
    push!(poly1, Vertex(1.1, 0.25))
    @test isinside(Vertex(1.09,0.25), poly1) == true
    @test isinside(Vertex(1.09,0.26), poly1) == true
    @test isinside(Vertex(0.9,0.25), poly1) == false
    @test isinside(Vertex(0.9,0.05), poly1) == true
    @test isinside(Vertex(0.9,0.9), poly1) == true
end

@testset "line intersection method" begin
    @test (intersection(Vertex(0,0), Vertex(1,1), Vertex(1,0), Vertex(0,1))
            == (true, 0.5, 0.5))
    @test (intersection(Vertex(0,0), Vertex(1,1), Vertex(1/2,0), Vertex(0,1/2))
            == (true, 0.25, 0.5))
    @test (intersection(Vertex(0,0), Vertex(2,2), Vertex(1/2,0), Vertex(0,1/2))
            == (true, 0.125, 0.5))
    @test (intersection(Vertex(0,0), Vertex(0,1), Vertex(1,0), Vertex(1,1))
            == (false, 0, 0))
    @test (intersection(Vertex(0.5,0), Vertex(0.5,1), Vertex(0,0.5), Vertex(1,0.5))
            == (true, 0.5, 0.5))
    @test (intersection(Vertex(0,0), Vertex(1,1), Vertex(0,0), Vertex(-1,-1))
            == (false, 0, 0))
    @test (intersection(Vertex(0,0), Vertex(0,0), Vertex(1,1), Vertex(1,1))
            == (false, 0, 0))
    @test (intersection(Vertex(0,0), Vertex(1,0), Vertex(0.25,0.5), Vertex(0.25,-0.5))
            == (true, 0.25, 0.5))
    @test (intersection(Vertex(1,0), Vertex(0,0), Vertex(0.25,0.5), Vertex(0.25,-0.5))
            == (true, 0.75, 0.5))
    @test (intersection(Vertex(0,0), Vertex(1,0), Vertex(0.25,-0.5), Vertex(0.25,0.25))
            == (true, 0.25, 2/3))
    @test (intersection(Vertex(0,0), Vertex(1,0), Vertex(0.25,0.25), Vertex(0.25,-0.5))
            == (true, 0.25, 1/3))
    @test (intersection(Vertex(0,0), Vertex(1,0), Vertex(1.5,0.5), Vertex(1.5,-0.5))
            == (false, 0, 0))
    @test_throws DegeneracyException intersection(Vertex(0,0), Vertex(1,0), Vertex(0.5,0), Vertex(0.5,1.0))
end

@testset "Vertex insertion" begin
    vert1 = Vertex(0,0)
    vert2 = Vertex(1,1)
    vert3 = Vertex(vert1, vert2, 0.25)
    @test vert3.next === vert2
    @test vert3.prev === vert1
    @test vert3.location == [0.25,0.25]
    vert3 = Vertex(vert2, vert1, 0.25)
    @test vert3.next === vert1
    @test vert3.prev === vert2
    @test vert3.location == [0.75,0.75]
end

@testset "unprocessed" begin
    poly1 = Polygon()
    push!(poly1, Vertex(0,0))
    push!(poly1, Vertex(1,0))
    push!(poly1, Vertex(1,1))
    push!(poly1, Vertex(0,1))
    @test unprocessed(poly1) == false
    poly1.start.next.intersect = true
    @test unprocessed(poly1) == true
    poly1.start.next.visited = true
    @test unprocessed(poly1) == false
end

@testset "remove vertices" begin
    poly1 = Polygon()
    vert1 = Vertex(0,1)
    push!(poly1, vert1)
    @test length(poly1) == 1
    @test poly1.start === vert1
    remove(vert1, poly1)
    @test length(poly1) == 0
    @test poly1.start === nothing
    @test vert1.next === nothing
    @test vert1.prev === nothing
    push!(poly1, vert1)
    vert2 = Vertex(1,1)
    push!(poly1, vert2)
    push!(poly1, Vertex(1,0))
    push!(poly1, Vertex(0,0))
    @test length(poly1) == 4
    remove(vert1, poly1)
    @test length(poly1) == 3
    @test poly1.start === vert2
end


@testset "clipping" begin
    poly1 = Polygon()
    push!(poly1, Vertex(0,1))
    push!(poly1, Vertex(1,1))
    push!(poly1, Vertex(1,0))
    push!(poly1, Vertex(0,0))
    poly3 = Polygon()
    push!(poly3, Vertex(0.9,-0.1))
    push!(poly3, Vertex(0.9,0.1))
    push!(poly3, Vertex(0.5,-0.05))
    push!(poly3, Vertex(0.1,0.1))
    push!(poly3, Vertex(0.1,-0.1))

    #test phase1
    @test length(poly1) == 4
    @test length(poly3) == 5
    pc.phase1!(poly3, poly1)
    @test length(poly1) == 8
    @test length(poly3) == 9
    intersects = 0
    for p1 in poly1, p2 in poly3
        if p1.location == p2.location
            @test p1.neighbor === p2
            @test p2.neighbor === p1
            @test p1.intersect
            @test p2.intersect
            intersects += 1
        end
    end
    @test intersects == 4 # make sure we found 4 intersections

    pc.phase2!(poly3, poly1)
    pc.phase2!(poly1, poly3)
    entries = 0
    for vert in poly1
        if vert.entry
            entries += 1
        end
    end
    @test entries == 6
    entries = 0
    for vert in poly3
        if vert.entry
            entries += 1
        end
    end
    @test entries == 5


    # Test phase1 with holes
    poly1 = Polygon()
    push!(poly1, Vertex(0.3,1.5))
    push!(poly1, Vertex(0.6,1.5))
    push!(poly1, Vertex(0.6,-1.5))
    push!(poly1, Vertex(0.3,-1.5))
    poly2 = Polygon()
    push!(poly2, Vertex(0.25,0.25))
    push!(poly2, Vertex(0.25,0.75))
    push!(poly2, Vertex(0.75,0.75))
    push!(poly2, Vertex(0.75,0.25))
    poly3 = Polygon()
    push!(poly3, Vertex(0,1))
    push!(poly3, Vertex(1,1))
    push!(poly3, Vertex(1,0))
    push!(poly3, Vertex(0,0))
    pc.phase1!(poly1,poly2,poly3)
    @test length(poly1) == 12
    @test length(poly2) == 8
    @test length(poly3) == 8
    intersects = 0
    for p1 in poly1, p2 in poly2
        if p1.location == p2.location
            @test p1.neighbor === p2
            @test p2.neighbor === p1
            @test p1.intersect
            @test p2.intersect
            intersects += 1
        end
    end
    for p1 in poly1, p2 in poly3
        if p1.location == p2.location
            @test p1.neighbor === p2
            @test p2.neighbor === p1
            @test p1.intersect
            @test p2.intersect
            intersects += 1
        end
    end
    @test intersects == 8 # make sure we found 4 intersections

    poly1 = Polygon()
    push!(poly1, Vertex(0,1))
    push!(poly1, Vertex(1,1))
    push!(poly1, Vertex(1,0))
    push!(poly1, Vertex(0,0))
    poly3 = Polygon()
    push!(poly3, Vertex(0.9,-0.1))
    push!(poly3, Vertex(0.9,0.1))
    push!(poly3, Vertex(0.5,-0.05))
    push!(poly3, Vertex(0.1,0.1))
    push!(poly3, Vertex(0.1,-0.1))

    results = intersection(poly3, poly1)

    @test length(results) == 2
    @test length(results[1]) == 4
    @test length(results[2]) == 4

    poly1 = Polygon()
    push!(poly1, Vertex(0,1))
    push!(poly1, Vertex(1,1))
    push!(poly1, Vertex(1,0))
    push!(poly1, Vertex(0,0))

    poly2 = Polygon()
    push!(poly2, Vertex(0.5,0.5))
    push!(poly2, Vertex(1.5,0.5))
    push!(poly2, Vertex(1.5,-0.5))
    push!(poly2, Vertex(0.5,-0.5))
    results = intersection(poly1, poly2)
    @test length(results) == 1
    @test length(results[1]) == 5

    poly1 = Polygon()
    push!(poly1, Vertex(1,0))
    push!(poly1, Vertex(1,1))
    push!(poly1, Vertex(0,1))
    push!(poly1, Vertex(0,0))

    poly2 = Polygon()
    push!(poly2, Vertex(0.5,0.5))
    push!(poly2, Vertex(1.5,0.5))
    push!(poly2, Vertex(1.5,-0.5))
    push!(poly2, Vertex(0.5,-0.5))
    results = intersection(poly1, poly2)
    @test length(results) == 1
    @test length(results[1]) == 5


    # Issue 2

    polya = Polygon()
    push!(polya, Vertex(-0.5, 0))
    push!(polya, Vertex(1.5, 0.0))
    push!(polya, Vertex(1.5, 1))
    push!(polya, Vertex(-0.5, 1))

    polyb = Polygon()
    push!(polyb, Vertex(0, -0.5))
    push!(polyb, Vertex(0, 1.5))
    push!(polyb, Vertex(1, 1.5))
    push!(polyb, Vertex(1, -0.5))

    PolygonClipping.phase1!(polya, polyb)

    intersects = 0
    for p1 in polya, p2 in polyb
        if p1.location == p2.location
            @test p1.neighbor === p2
            @test p2.neighbor === p1
            @test p1.intersect
            @test p2.intersect
            intersects += 1
        end
    end
    @test intersects == 4 # make sure we found 4 intersections

    polya = Polygon()
    push!(polya, Vertex(-0.5, 0))
    push!(polya, Vertex(1.5, 0.0))
    push!(polya, Vertex(1.5, 1))
    push!(polya, Vertex(-0.5, 1))

    polyb = Polygon()
    push!(polyb, Vertex(0, -0.5))
    push!(polyb, Vertex(0, 1.5))
    push!(polyb, Vertex(1, 1.5))
    push!(polyb, Vertex(1, -0.5))

    PolygonClipping.phase1!(polyb, polya)

    intersects = 0
    for p1 in polya, p2 in polyb
        if p1.location == p2.location
            @test p1.neighbor === p2
            @test p2.neighbor === p1
            @test p1.intersect
            @test p2.intersect
            intersects += 1
        end
    end
    @test intersects == 4 # make sure we found 4 intersections

    PolygonClipping.phase2!(polyb, polya)
    PolygonClipping.phase2!(polya, polyb)
end

@testset "infill" begin
    polya = Polygon()
    push!(polya, Vertex(0.0, 1.0))
    push!(polya, Vertex(1.0, 1.0))
    push!(polya, Vertex(1.0, 0.0))
    push!(polya, Vertex(0.0, 0.0))

    polyb = Polygon()
    push!(polyb, Vertex(-0.15, -0.5))
    push!(polyb, Vertex(-0.15, 1.5))
    push!(polyb, Vertex(0.15, 1.5))
    push!(polyb, Vertex(0.15, -0.2))
    push!(polyb, Vertex(0.3, -0.2))
    push!(polyb, Vertex(0.3, 1.5))
    push!(polyb, Vertex(0.45, 1.5))
    push!(polyb, Vertex(0.45, -0.5))
    fill = infill(polya, polyb)
end
