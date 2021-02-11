-- Init Menu
Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Enable Gamesense", "cEnableGSSdk", true)
Menu.InputText("Port", "cGSSDKPort", "0")


--Remote Control
Hack.RegisterCallback("CreateMove", function ()
    if not Menu.GetBool("cEnableGSSdk") then return end
    if Menu.GetInt("cGSSDKPort") == "0" then return end
end)