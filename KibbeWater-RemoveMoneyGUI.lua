Menu.Checkbox("Enable money hud", "cMoneyDisabler", false)

local oldEnabled = false

Hack.RegisterCallback("PaintTraverse", function ()

    --Money disabled changed
    if Menu.GetBool("cMoneyDisabler") ~= oldEnabled then

        --Inject money remover
        IPanorama.RunScript_Hud([[
            var itemsToDelete = ["HudRadar", "HudMoney"];
            itemsToDelete.forEach(obj => {
                var money = $('#Hud').FindChildInLayoutFile(obj);
                money.visible = ]] .. tostring(Menu.GetBool("cMoneyDisabler")) .. [[;
            });
        ]])

        --Change state
        oldEnabled = Menu.GetBool("cMoneyDisabler")
    end
end)