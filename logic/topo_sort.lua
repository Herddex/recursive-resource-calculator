local Set = require "utils/set"
local TopoSorter = {}

--A function which takes two Lua tables of the form [_item_type_] -> set[_item_type_], with the same key set, mapping each item to some dependencies (which are other keys in said tables);returns a topologically sorted list of all the items (such that each item in the list has all of its inbound dependencies somewhere to its left in the list)
function TopoSorter.topo_sort(inbound_dependencies, outbound_dependencies)
    --This is an application of Kahn's topological sorting algorithm
    --Source: https://en.wikipedia.org/wiki/Topological_sorting

    --Note: this function computes an inverse topo sort, with the most dependent items first and the items with no dependencies last
    local set_of_no_depenceny_items = Set.new()
    for item, dependency_set in pairs(outbound_dependencies) do
        if Set.empty(dependency_set) then Set.add(set_of_no_depenceny_items, item) end
    end

    local final_list = {}

    while not Set.empty(set_of_no_depenceny_items) do
        local item = Set.random_key(set_of_no_depenceny_items)
        Set.remove(set_of_no_depenceny_items, item)
        final_list[#final_list + 1] = item
        
        for dependency, _ in Set.parse(inbound_dependencies[item]) do
            Set.remove(outbound_dependencies[dependency], item)
            if Set.empty(outbound_dependencies[dependency]) then
                Set.add(set_of_no_depenceny_items, dependency)
            end
        end
    end

    return final_list
end

return TopoSorter