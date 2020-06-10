-- Init Menu
Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Enable Menu Walk", "cEnableMWalk", true)

Hack.RegisterCallback("CreateMove", function (cmd, send)
    if not Menu.GetBool("cEnableMWalk") or not Globals.MenuOpened() then return end

    if InputSys.IsKeyDown(87) then cmd.forwardmove = 450 elseif cmd.forwardmove == 450 then cmd.forwardmove = 0 end --W
    if InputSys.IsKeyDown(83) then cmd.forwardmove = -450 elseif cmd.forwardmove == -450 then cmd.forwardmove = 0 end --S
    if InputSys.IsKeyDown(65) then cmd.sidemove = -450 elseif cmd.sidemove == -450 then cmd.sidemove = 0 end --A
    if InputSys.IsKeyDown(68) then cmd.sidemove = 450 elseif cmd.sidemove == 450 then cmd.sidemove = 0 end --D
    if InputSys.IsKeyDown(32) then cmd.buttons = SetBit(cmd.buttons, 1) end --Space
    if InputSys.IsKeyDown(17) then cmd.buttons = SetBit(cmd.buttons, 2) end --Crouch

end)