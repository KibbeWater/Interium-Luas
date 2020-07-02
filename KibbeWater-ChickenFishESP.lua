Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Enable Fish ESP", "cEnableFishESP", true)
Menu.ColorPicker("Fish Box Color", "cFishBoxClr", 255, 255, 255, 255)
Menu.ColorPicker("Fish Text Color", "cFishTextClr", 255, 255, 255, 255)
Menu.Spacing()
Menu.Separator()
Menu.Checkbox("Enable Chicken ESP", "cEnableChickenESP", true)
Menu.ColorPicker("Chicken Box Color", "cChickenBoxClr", 255, 255, 255, 255)
Menu.ColorPicker("Chicken Text Color", "cChickenTextClr", 255, 255, 255, 255)

Hack.RegisterCallback("PaintTraverse", function ()
    for i = 1, IEntityList.GetHighestEntityIndex() do
        local ent = IEntityList.GetEntity(i)
        
        if not ent then goto continue end
        if ent:GetClassId() ~= 75 and ent:GetClassId() ~= 36 then goto continue end

        if not ent:IsDormant() and ent:GetClassId() == 75 and Menu.GetBool("cEnableFishESP") then
            local box = ent:GetBox()
            Render.Rect(box.left-7, box.top-7, box.right+7, box.bottom+7, Menu.GetColor("cFishBoxClr"), 1, 1)
            Render.Text_1("Fish", ((box.right - box.left) / 2) + box.left, box.top - Render.CalcTextSize_1("Fish", 13).y - 7, 13, Menu.GetColor("cFishTextClr"), true, false)
        elseif not ent:IsDormant() and ent:GetClassId() == 36 and Menu.GetBool("cEnableChickenESP") then
            local box = ent:GetBox()
            Render.Rect(box.left, box.top, box.right, box.bottom, Menu.GetColor("cChickenBoxClr"), 1, 1)
            Render.Text_1("Chicken", ((box.right - box.left) / 2) + box.left, box.top - Render.CalcTextSize_1("Fish", 13).y, 13, Menu.GetColor("cChickenTextClr"), true, false)
        end
        ::continue::
    end
end)