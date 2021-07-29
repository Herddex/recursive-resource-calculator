--a Lua module for pozitive rational numbers

local function gcd(a, b)
    while b ~= 0 do
        local c = a
        a = b
        b = math.fmod(c, b) -- c % b
    end
    return a
end

local rational_metatable = {}

local function new_rational(numerator, denominator)
    local d = gcd(numerator, denominator)
    local rational = {
        numerator = numerator / d,
        denominator = denominator / d
    }
    setmetatable(rational, rational_metatable)
    return rational
end

rational_metatable.__add = function(a, b)
    local numerator = a.numerator * b.denominator + b.numerator * a.denominator
    local denominator = a.denominator * b.denominator
    return new_rational(numerator, denominator)
end

rational_metatable.__sub = function(a, b)
    local numerator = a.numerator * b.denominator - b.numerator * a.denominator
    local denominator = a.denominator * b.denominator
    return new_rational(numerator, denominator)
end

rational_metatable.__mul = function(a, b)
    return new_rational(a.numerator * b.numerator, a.denominator * b.denominator)
end

rational_metatable.__div = function(a, b)
    return new_rational(a.numerator * b.denominator, a.denominator * b.numerator)
end

--Attempts to parse the given division string ("integer/integer") and build a rational number out of it. If succesful, the number is returned. Otherwise, nil is returned
local function from_division_string(division)
    local slash_position = string.find(division, "/", 1, true)
    if not slash_position then return nil end

    local numerator = tonumber(string.sub(division, 1, slash_position - 1))
    local denominator = tonumber(string.sub(division, slash_position + 1))
    if not numerator or not denominator or numerator <= 0 or denominator <= 0 then return nil end

    return new_rational(numerator, denominator)
end

--Attempts to parse the given pozitive decimal number given as a string (sequence of digits with a dot between two of the digits) and build a rational number out of it. If succesful, the number is returned. Otherwise, nil is returned
local function from_decimal_string(decimal)
    local dot_position = string.find(decimal, ".", 1, true)
    if not dot_position or dot_position == 1 or dot_position == string.len(decimal) then return nil end

    local fractional_part_length = string.len(decimal) - dot_position
    local numerator = tonumber(string.sub(decimal, 1, dot_position - 1) .. string.sub(decimal, dot_position + 1))
    if not numerator or numerator <= 0 then return nil end

    return new_rational(numerator, 10 ^ fractional_part_length)
end

--Builds and returns a rational number from the given integer number. If the input was not an integer, nil is returned instead
local function from_integer(format)
    local number = tonumber(format)
    if not number or math.floor(number) ~= number or number <= 0 then return nil end
    return new_rational(number, 1)
end

--If possible, the function returns the finite decimal representation of the given rational number. Otherwise, it returns nil
local function to_decimal_string(rational)
    local denominator = rational.denominator
    local power_of_2 = 0
    local power_of_5 = 0
    
    while math.fmod(denominator, 2) == 0 do
        denominator = denominator / 2
        power_of_2 = power_of_2 + 1
    end
    while math.fmod(denominator, 5) == 0 do
        denominator = denominator / 5
        power_of_5 = power_of_5 + 1
    end

    if denominator == 1 then
        local numerator = rational.numerator
        local power_of_10 = power_of_2 --assume the two powers are equal for now

        --Compute the correct power if they are actually different
        if power_of_2 < power_of_5 then
            local difference = power_of_5 - power_of_2
            numerator = numerator * (2 ^ difference)
            power_of_10 = power_of_5
        elseif power_of_2 > power_of_5 then
            local difference = power_of_2 - power_of_5
            numerator = numerator * (5 ^ difference)
            power_of_10 = power_of_2
        end

        local p = 10 ^ power_of_10
        local remainder = math.fmod(numerator, p)
        local integer_part = (numerator - remainder) / p
        
        return integer_part .. "." .. string.format("%0" .. power_of_10 .. "d", remainder)
    end
end

Rational = {}

--Attempts to build and return a rational number from parsing the given string. Accepted formats are integers (example: 5), integer ratios (example: 2/3), and finite decimal numbers (example: 1.6). On failure, nil is returned
function Rational.from_string(format)
    return from_integer(format) or from_decimal_string(format) or from_division_string(format)
end

--Returns either the finite decimal representation, if possible, or the fraction representation ("integer/integer"), otherwise, of the given rational number. If the number happens to be an integer, then it's returned directly as such, with no fractional part. If the input is not a rational number, nil is returned
function Rational.to_string(rational)
    local numerator = tostring(rational.numerator)
    if rational.denominator == 1 then return numerator end

    local possible_decimal_representation = to_decimal_string(rational)
    if possible_decimal_representation and type(possible_decimal_representation) == "string" then
        return possible_decimal_representation
    end

    local denominator = tostring(rational.denominator)
    return numerator .. "/" .. denominator
end

--Returns the Lua number approximation of the rational number
function Rational.numerical_approximation(rational)
    return rational.numerator / rational.denominator
end

return Rational