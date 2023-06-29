module HerbCore

include("rulenode.jl")
include("constraint.jl")
include("grammar.jl")

export 
    AbstractRuleNode,
    RuleNode,
    Hole,

    depth,
    node_depth,
    rulesoftype,
    swap_node,
    get_rulesequence,
    rulesonleft,
    get_node_at_location,
    contains_hole,

    Constraint,
    Grammar

end # module HerbCore