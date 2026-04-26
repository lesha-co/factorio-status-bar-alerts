
local last_state = nil


script.on_init(
    function()
        game.players[1].print("Hello player 1!")

        game.print("alerts.log monitoring started!!!")
        for _, player in pairs(game.players) do
            player.print("alerts.log monitoring started")
        end
    end
)


script.on_event(
    defines.events.on_tick,
    function(event)
        for _, player in pairs(game.players) do
            local result = get_alerts_as_string(player)
            if result ~= last_state then
                last_state = result
                helpers.write_file("alerts.log", event.tick .. ',' .. result, false, player.index)
            end
        end
    end
)



function get_alerts_as_string(player)
    local alerts = player.get_alerts({})
    local item_counts = {}

    for surface_index, alert_types in pairs(alerts) do
        for alert_type, alert_list in pairs(alert_types) do
            if item_counts[alert_type] == nil then
                item_counts[alert_type] = 0
            end
            item_counts[alert_type] = item_counts[alert_type] + #alert_list
        end
    end


    local parts = {}
    for alert_type, count in pairs(item_counts) do
        if count > 0 then
            table.insert(parts, alert_type .. ":" .. count)
        end
    end
    return (table.concat(parts, ","))
end
