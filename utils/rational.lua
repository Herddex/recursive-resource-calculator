--a Lua module for rational numbers

local function gcd(a, b)
    if a < 0 then a = -a end
    if b < 0 then b = -b end
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
    local numerator = a.numerator * b.denominator
    local denominator = a.denominator * b.numerator
    if denominator < 0 then
        numerator = -numerator
        denominator = -denominator
    end
    return new_rational(numerator, denominator)
end

rational_metatable.__unm = function(a)
    return new_rational(-a.numerator, a.denominator)
end

rational_metatable.__le = function(a, b)
    local common_denominator = a.denominator * b.denominator / gcd(a.denominator, b.denominator)
    return common_denominator / a.denominator * a.numerator <= common_denominator / b.denominator * b.numerator
end

rational_metatable.__lt = function(a, b)
    local common_denominator = a.denominator * b.denominator / gcd(a.denominator, b.denominator)
    return common_denominator / a.denominator * a.numerator < common_denominator / b.denominator * b.numerator
end

rational_metatable.__eq = function(a, b)
    return a.denominator == b.denominator and a.numerator == b.numerator
end

--Attempts to parse the given division_string ("integer/integer") and build a rational number out of it. If succesful, the number is returned. Otherwise, nil is returned
local function from_division_string(division_string)
    local slash_position = string.find(division_string, "/", 1, true)
    if not slash_position then return nil end

    local numerator = tonumber(string.sub(division_string, 1, slash_position - 1))
    local denominator = tonumber(string.sub(division_string, slash_position + 1))
    if not numerator or not denominator then return nil end

    return new_rational(numerator, denominator)
end

--Attempts to parse the given pozitive decimal number given as a string (sequence of digits with a dot between two of the digits) and build a rational number out of it. If succesful, the number is returned. Otherwise, nil is returned
local function from_decimal_string(decimal)
    local dot_position = string.find(decimal, ".", 1, true)
    if not dot_position or dot_position == 1 or dot_position == string.len(decimal) then return nil end

    local fractional_part_length = string.len(decimal) - dot_position
    local numerator = tonumber(string.sub(decimal, 1, dot_position - 1) .. string.sub(decimal, dot_position + 1))
    if not numerator then return nil end

    return new_rational(numerator, 10 ^ fractional_part_length)
end

--Builds and returns a rational number from the given integer number. If the input was not an integer, nil is returned instead
local function from_integer(format)
    local number = tonumber(format)
    if not number or math.floor(number) ~= number then return nil end
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
        if numerator < 0 then numerator = -numerator end

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
        
        return (rational.numerator < 0 and "-" or "") .. integer_part .. "." .. string.format("%0" .. power_of_10 .. "d", remainder)
    end
end

Rational = {}

function Rational.reset_metatable(rational) --used for resetting the metatables of rational numbers (which are tables); Factorio does not save metatables from one game session to another, making this task necessary sometimes.
    setmetatable(rational, rational_metatable)
end

--Attempts to build and return a rational number from parsing the given string. Accepted formats are integers (example: 5), integer ratios (example: 2/3), and finite decimal numbers (example: 1.6). Optionally, a "-" sign is also accepted in front of all these formats. On failure, nil is returned
function Rational.from_string(rational_number_string)
    local negative = rational_number_string[1] == '-'
    if negative then rational_number_string = string.sub(rational_number_string, 2) end

    local rational = from_integer(rational_number_string) or from_decimal_string(rational_number_string) or from_division_string(rational_number_string)

    if rational and negative then
        rational.numerator = -rational.numerator
    end

    return rational
end

--Returns either the finite decimal representation, if possible, or the fraction representation ("integer/integer"), otherwise, of the given rational number. If the number happens to be an integer, then it's returned directly as such, with no fractional part.
function Rational.to_string(rational)
    local numerator_string = tostring(rational.numerator)
    if rational.denominator == 1 then return numerator_string end

    local possible_decimal_representation = to_decimal_string(rational)
    if possible_decimal_representation then
        return possible_decimal_representation
    end

    local denominator_string = tostring(rational.denominator)
    return numerator_string .. "/" .. denominator_string
end

--Returns the Lua number approximation of the rational number
function Rational.numerical_approximation(rational)
    return rational.numerator / rational.denominator
end

function Rational.from_double(double)
    return Rational.from_string(tostring(double))
end

function Rational.from_double_with_two_decimals_precision(double)
    return Rational.from_string(string.format("%.2f", double))
end

Rational.module_multiplyer_minimum_value = new_rational(1, 5)

return Rational