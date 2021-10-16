# Recursive Resource Calculator
A Lua mod for the automation and base management game Factorio that gives users the ability to more easily plan their factories, by automatically calculating the production rate and machinery needed for each intermediate product.

The mod leverages the game's API (https://lua-api.factorio.com/latest/) to:
+ build a directed graph of recipe dependencies that is used in the decomposition of products;
+ perform precise calculations of the number and type of machines needed, energy consumption and pollution emissions for each product;
+ compile the results of the computations into neatly built reports;
+ and finally, build the GUI that puts it all together.

For pictures, more detailed information, and downloads, consult the official Factorio Mod Portal page: https://mods.factorio.com/mod/RecursiveResourceCalculator
