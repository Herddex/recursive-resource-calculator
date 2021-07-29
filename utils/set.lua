--a lua module for Sets
local Set = {}

function Set.new()
    return {elems = {}, n = 0}
end

function Set.add(set, key)
    if set.elems[key] then return false end
    set.elems[key] = true
    set.n = set.n + 1
    return true
end

function Set.remove(set, key)
    if not set.elems[key] then return false end
    set.elems[key] = nil
    set.n = set.n - 1
    return true
end

function Set.empty(set)
    return set.n == 0
end

function Set.random_key(set)
    for key, _ in pairs(set.elems) do
        return key
    end
end

function Set.parse(set)
    return pairs(set.elems)
end

return Set