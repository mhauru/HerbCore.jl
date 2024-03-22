using HerbCore
using Test

@testset "HerbCore.jl" verbose=true begin
    @testset "RuleNode tests"  begin 
        @testset "Equality tests" begin 
            @test RuleNode(1) == RuleNode(1)

            node = RuleNode(1,[RuleNode(2),RuleNode(3)])
            @test node == node
            @test RuleNode(1,[RuleNode(2),RuleNode(3)]) == RuleNode(1,[RuleNode(2),RuleNode(3)])
            @test RuleNode(1,[RuleNode(2),node]) == RuleNode(1,[RuleNode(2),node])


            @test RuleNode(1) !== RuleNode(2)
            @test RuleNode(1,[RuleNode(2),RuleNode(3)]) !== RuleNode(2,[RuleNode(2),RuleNode(3)])

        end

        @testset "Hash tests" begin 
            node = RuleNode(1,[RuleNode(2),RuleNode(3)])
            @test hash(node) == hash(node)
            @test hash(node) == hash(RuleNode(1,[RuleNode(2),RuleNode(3)]))
            @test hash(RuleNode(1,[RuleNode(2)])) !== hash(RuleNode(1))
        end

        @testset "Depth tests" begin 
            @test depth(RuleNode(1)) == 1
            @test depth(RuleNode(1,[RuleNode(2), RuleNode(3)])) == 2
        end

        @testset "Length tests" begin 
            @test length(RuleNode(1)) == 1
            @test length(RuleNode(1,[RuleNode(2), RuleNode(3)])) == 3
            @test length(RuleNode(1,[RuleNode(2, [RuleNode(3), RuleNode(4)])])) == 4
        end
        @testset "RuleNode compare" begin
            @test HerbCore._rulenode_compare(RuleNode(1), RuleNode(1)) == 0
            @test RuleNode(1) < RuleNode(2)
            @test RuleNode(2) > RuleNode(1) 
            @test RuleNode(1,[RuleNode(2)]) < RuleNode(1,[RuleNode(3)]) 
            @test RuleNode(1,[RuleNode(2)]) < RuleNode(2,[RuleNode(1)]) 
        end

        @testset "Node depth from a tree" begin 
            #=    1      -- depth 1
               2  3  4   -- depth 2
                    5  6 -- depth 3

            =#
            rulenode = RuleNode(1,[RuleNode(2),RuleNode(3),RuleNode(4,[RuleNode(5),RuleNode(6)])])
            @test node_depth(rulenode, rulenode) == 1
            
            @test node_depth(rulenode, rulenode.children[1]) == 2
            @test node_depth(rulenode, rulenode.children[2]) == 2
            @test node_depth(rulenode, rulenode.children[3]) == 2
            
            @test node_depth(rulenode, rulenode.children[3].children[1]) == 3
            @test node_depth(rulenode, rulenode.children[3].children[2]) == 3

            # in case a random node appears the node_depth is 0
            @test node_depth(rulenode, RuleNode(100)) == 0
        end

        @testset "rule sequence" begin 

            #=    1      
               2  3  4   
                    5  6 
                   7    9
                          10 
            =#
            rulenode = 
                RuleNode(1,
                    [
                        RuleNode(2),
                        RuleNode(3),
                        RuleNode(4,
                            [
                                RuleNode(5,
                                    [RuleNode(7)]
                                ),
                                RuleNode(6,
                                    [RuleNode(9,[RuleNode(10)])]
                                )
                            ]
                        )
                    ]
                )
            @test get_rulesequence(rulenode, [3,1,1]) == [1,4,5,7]
            @test get_rulesequence(rulenode, [3,2,1]) == [1,4,6,9]
            @test get_rulesequence(rulenode, [3,2,1,1]) == [1,4,6,9,10]

            # putting out of bounds indices returns the root
            @test get_rulesequence(rulenode, [100,4,1000]) == [1]
        end

        @testset "get_node_at_location" begin
            rulenode = FixedShapedHole(BitVector((1, 1, 0, 0)), [RuleNode(3), RuleNode(4)])
            @test get_node_at_location(rulenode, Vector{Int64}()) isa FixedShapedHole
            @test get_node_at_location(rulenode, [1]).ind == 3
            @test get_node_at_location(rulenode, [2]).ind == 4
        end

        @testset "get_node_path" begin
            n1 = RuleNode(1)
            n2 = RuleNode(2)
            n3 = FixedShapedHole(BitVector((1, 1, 1)), [RuleNode(1), n2])
            n4 = RuleNode(1)
            root = RuleNode(4, [
                RuleNode(4, [
                    n1,
                    RuleNode(1)
                ]),
                n3
            ])
            @test get_node_path(root, n1) == [1, 1]
            @test get_node_path(root, n2) == [2, 2]
            @test get_node_path(root, n3) == [2]
            @test isnothing(get_node_path(root, n4))
        end

        @testset "Length tests with holes" begin
            domain=BitVector((1, 1))
            @test length(FixedShapedHole(domain, [])) == 1
            @test length(FixedShapedHole(domain, [RuleNode(2)])) == 2
            @test length(RuleNode(1,[RuleNode(2, [Hole(domain), RuleNode(4)])])) == 4
            @test length(FixedShapedHole(domain,[RuleNode(2, [RuleNode(4), RuleNode(4)])])) == 4
        end

        @testset "Depth tests with holes" begin 
            domain=BitVector((1, 1))
            @test depth(FixedShapedHole(domain, [])) == 1
            @test depth(FixedShapedHole(domain, [RuleNode(2)])) == 2
            @test depth(RuleNode(1,[RuleNode(2, [Hole(domain), RuleNode(4)])])) == 3
            @test depth(FixedShapedHole(domain,[RuleNode(2, [RuleNode(4), RuleNode(4)])])) == 3
        end

        @testset "number_of_holes" begin
            domain=BitVector((1, 1))
            @test number_of_holes(RuleNode(1)) == 0
            @test number_of_holes(VariableShapedHole(domain)) == 1
            @test number_of_holes(FixedShapedHole(domain, [RuleNode(1), RuleNode(1)])) == 1
            @test number_of_holes(FixedShapedHole(domain, [VariableShapedHole(domain), RuleNode(1)])) == 2
            @test number_of_holes(RuleNode(2, [VariableShapedHole(domain), RuleNode(1)])) == 1
            @test number_of_holes(FixedShapedHole(domain, [
                VariableShapedHole(domain),
                FixedShapedHole(domain, [VariableShapedHole(domain), RuleNode(1)])
            ])) == 4
        end

        @testset "isfixedshaped" begin
            domain=BitVector((1, 1))

            @test isfixedshaped(RuleNode(1, [RuleNode(2)])) == true
            @test isfixedshaped(FixedShapedHole(domain, [RuleNode(2)])) == true

            @test isfixedshaped(RuleNode(1)) == true
            @test isfixedshaped(RuleNode(1, [])) == true
            @test isfixedshaped(FixedShapedHole(domain, [])) == true

            @test isfixedshaped(VariableShapedHole(domain)) == false
        end

        @testset "isfilled" begin
            domain1=BitVector((0, 1, 0, 0, 0))
            domain2=BitVector((0, 1, 0, 1, 0))
            @test isfilled(RuleNode(1, [])) == true
            @test isfilled(RuleNode(1, [RuleNode(2)])) == true
            @test isfilled(RuleNode(1, [VariableShapedHole(domain1)])) == true
            @test isfilled(RuleNode(1, [VariableShapedHole(domain2)])) == true

            @test isfilled(FixedShapedHole(domain1, [VariableShapedHole(domain2)])) == true
            @test isfilled(FixedShapedHole(domain2, [VariableShapedHole(domain2)])) == false

            @test isfilled(VariableShapedHole(domain1)) == true
            @test isfilled(VariableShapedHole(domain2)) == false
        end

        @testset "get_rule" begin
            domain_of_size_1=BitVector((0, 1, 0, 0, 0))
            @test get_rule(RuleNode(99, [RuleNode(3), RuleNode(4)])) == 99
            @test get_rule(RuleNode(2, [RuleNode(3), RuleNode(4)])) == 2
            @test get_rule(FixedShapedHole(domain_of_size_1, [RuleNode(5), RuleNode(6)])) == 2
            @test get_rule(VariableShapedHole(domain_of_size_1)) == 2
        end
    end
end
