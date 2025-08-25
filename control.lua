event_handlers = {}
event_handlers.on_gui_click = {}
event_handlers.on_gui_confirmed = {}
event_handlers.on_gui_elem_changed = {}

local Calculator = require "gui.calculator"
local Sheet = require "gui.sheet"
local Indexer = require "logic.indexer"
local PlayerData = require "logic.player_data"
local PlayerDataUpdater = require "logic.player_data_updater"
local Updates = require "updates"

async_calls = {Sheet.calculate, Calculator.auto_center}

local function set_up_new_player(player)
    PlayerData.initialize_player_data(player.index)
    Calculator.build(player)
end

script.on_init(function()
    Indexer.run()
    storage.computation_stack = {}
    for _, player in pairs(game.players) do
        set_up_new_player(player)
    end
end)

script.on_configuration_changed(function(configuration_changed_data)
    Indexer.run()

    local rrc_version_change = configuration_changed_data.mod_changes.RecursiveResourceCalculator
    if rrc_version_change then
        Updates.update_from(rrc_version_change.old_version)
    end

    storage.computation_stack = {}
    for _, player in pairs(game.players) do
        PlayerDataUpdater.reinitialize(player.index)
        Calculator.recompute_everything(player.index)
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    set_up_new_player(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_removed, function(event)
    storage[event.player_index] = nil
end)

script.on_event("hxrrc_toggle_calculator", function(event)
    Calculator.toggle(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_gui_closed, function(event)
    if event.element and event.element.name == "hxrrc_calculator" and event.element.visible then
        Calculator.toggle(game.get_player(event.player_index))
    end
end)

script.on_event(defines.events.on_research_finished, function(event)
    for _, effect in ipairs(event.research.prototype.effects) do
        if effect.type == "change-recipe-productivity" then
            for player_index, _ in ipairs(event.research.force.players) do
                Calculator.recompute_everything(player_index)
            end
            return
        end
    end
end)

--Register handlers for which event.element.name exists
for _, event_type in ipairs({
    "on_gui_click",
    "on_gui_elem_changed",
    "on_gui_confirmed",
    }) do
    script.on_event(defines.events[event_type], function(event)
        local handler = event_handlers[event_type][event.element.name]
        if handler then handler(event) end
    end)
end

--Do each sheet calculation in its own tick
script.on_event(defines.events.on_tick, function()
    if storage.computation_stack[1] then
        local async_call_data = table.remove(storage.computation_stack)
        local call = async_calls[async_call_data.call_id]
        call(table.unpack(async_call_data.parameters))
        local player_index = async_call_data.player_index
        game.get_player(player_index).gui.screen.hxrrc_calculator.enabled = storage[player_index].backlogged_computation_count == 0
    end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting == "hxrrc-displayed-floating-point-precision" then
        Calculator.recompute_everything(event.player_index)
    end
end)