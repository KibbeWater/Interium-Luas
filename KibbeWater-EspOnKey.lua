Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Text("KibbeWater - ESP On Key")
Menu.Spacing()
Menu.Spacing()
Menu.Spacing()
Menu.Text("Options")
Menu.Separator()
Menu.Combo("Behaviour Type", "espKey.behaviour", { "Hold", "Toggle" }, 0)
Menu.KeyBind("ESP Key", "espKey.key", 86)

local espState = false
local oldKeyState = false
Hack.RegisterCallback("PaintTraverse", function()
    local curKeyState = InputSys.IsKeyDown(Menu.GetInt("espKey.key"))

    if Menu.GetInt("espKey.behaviour") == 0 then --Hold
        espState = curKeyState
    else --Toggle
        if curKeyState and not oldKeyState then -- Keydown
            espState = not espState
        end
    end

    Menu.SetBool("espKey.state", espState) -- PUBLIC API STUFF
    SetBool(Vars.esp_enabled, espState)

    oldKeyState = curKeyState
end)
