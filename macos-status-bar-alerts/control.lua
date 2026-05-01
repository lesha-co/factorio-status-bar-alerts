local last_state = nil

local function get_alerts_as_string(player)
    local alerts = player.get_alerts({})
    local item_counts = {}

    for _, alert_types in pairs(alerts) do
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

script.on_event(
    defines.events.on_tick,
    function(event)
        for _, player in pairs(game.players) do
            local result = get_alerts_as_string(player)
            if result ~= last_state then
                last_state = result
                helpers.write_file("macos-status-bar-alerts/alerts.log", event.tick .. ',' .. result, false, player
                    .index)
            end
        end
    end
)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local function app_companion_notice(player)
    if storage.msba_dismissed_players and storage.msba_dismissed_players[player.index] then
        player.print("macos-status-bar-alerts: notice is suppressed")
        return
    end

    local screen = player.gui.screen
    if screen["msba_companion_dialog"] then
        screen["msba_companion_dialog"].destroy()
    end

    local dialog = screen.add({
        type = "frame",
        name = "msba_companion_dialog",
        direction = "vertical",
        caption = "Companion App Required"
    })
    dialog.auto_center = true

    local content = dialog.add({
        type = "flow",
        direction = "vertical"
    })
    content.style.horizontal_align = "center"
    content.style.vertical_spacing = 10
    content.style.padding = {10, 10, 10, 10}

    content.add({
        type = "label",
        caption = "macos-status-bar-alerts is a mod that requires a companion application to run."
    })
    content.add({
        type = "label",
        caption = "More info: https://lesha.co/msba"
    })

    local button_flow = content.add({
        type = "flow",
        direction = "horizontal"
    })
    button_flow.style.horizontal_spacing = 10
    button_flow.style.top_margin = 10
    button_flow.style.horizontal_align = "right"


    button_flow.add({
        type = "button",
        name = "msba_companion_dismiss",
        caption = "Dismiss",
        style = "back_button"
    })
    button_flow.add({
        type = "button",
        name = "msba_companion_dismiss_and_never_show_again",
        caption = "Dismiss and do not show again",
        style = "back_button"
    })
    player.opened = dialog
end

local function on_first_tick()
    for _, player in pairs(game.players) do
        app_companion_notice(player)
    end
    script.on_nth_tick(1, nil)
end

script.on_event(
    defines.events.on_gui_click,
    function(event)
        local element = event.element
        if not element or not element.valid then return end

        local player = game.get_player(event.player_index)
        if not player then return end

        if element.name == "msba_companion_dismiss" then
            if player.gui.screen["msba_companion_dialog"] then
                player.gui.screen["msba_companion_dialog"].destroy()
            end
        elseif element.name == "msba_companion_dismiss_and_never_show_again" then
            if player.gui.screen["msba_companion_dialog"] then
                player.gui.screen["msba_companion_dialog"].destroy()
            end
            if not storage.msba_dismissed_players then
                storage.msba_dismissed_players = {}
            end
            storage.msba_dismissed_players[event.player_index] = true
        end
    end
)


script.on_load(function()
    script.on_nth_tick(1, on_first_tick)
end)

script.on_init(function()
    script.on_nth_tick(1, on_first_tick)
end)
