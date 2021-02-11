local sendText = ""
local printText = false

local Wins_Offset = Hack.GetOffset("DT_CSPlayerResource", "m_iCompetitiveWins")
local Rank_Offset = Hack.GetOffset("DT_CSPlayerResource", "m_iCompetitiveRanking")
local Team_Offset = Hack.GetOffset("DT_BaseEntity", "m_iTeamNum")

function Split (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

--thx NizeL
function BuildData(msg_data)
	local SpaceIdx = 0
	for i = 1, string.len(msg_data) do
		if (string.byte(string.sub(msg_data, i, i)) == 34) then
			SpaceIdx = i
			break
		end
	end

	local ChatName = string.sub(msg_data, 1, SpaceIdx-1)
    local ChatText = string.sub(msg_data, SpaceIdx)
    
    return {ChatName, ChatText}
end

Hack.RegisterCallback("DispatchUserMessage", function (type, a3, length, data)
    if type ~= 6 then return end

    local msg = {}
    local ChatType = ""

    if (data:find("Cstrike_Chat_All", 0)) then
		ChatType = "Cstrike_Chat_All"
		data = string.sub(data, string.find(data, "Cstrike_Chat_All") + string.len("Cstrike_Chat_All") + 1)
		msg = BuildData(data)
	elseif (data:find("Cstrike_Chat_CT", 0)) then
		ChatType = "Cstrike_Chat_CT"
		data = string.sub(data, string.find(data, "Cstrike_Chat_CT") + string.len("Cstrike_Chat_CT") + 1)
		msg = BuildData(data)
	elseif (data:find("Cstrike_Chat_T", 0)) then
		ChatType = "Cstrike_Chat_T"
		data = string.sub(data, string.find(data, "Cstrike_Chat_T") + string.len("Cstrike_Chat_T") + 1)
		msg = BuildData(data)
	end

    if #msg == 0 then return end

    local username = msg[1]
    local text = msg[2]

    local args = Split(text, " ")
    local ranks = {
        "Unranked",
        "Silver I",
        "Silver II",
        "Silver III",
        "Silver IV",
        "Silver Elite",
        "Silver Elite Master",

        "Gold Nova I",
        "Gold Nova II",
        "Gold Nova III",
        "Gold Nova Master",
        "Master Guardian I",
        "Master Guardian II",

        "Master Guardian Elite",
        "Distinguished Master Guardian",
        "Legendary Eagle",
        "Legendary Eagle Master",
        "Supreme Master First Class",
        "The Global Elite"
    }

    if string.match(args[1], "$dumpwins") then
        
        local returnText = string.sub(text, string.len(args[1]) + 1):sub(1, -2)

        local p = {}
        local ct = {}

        for i=1, 64 do
            local Player = IEntityList.GetPlayer(i)
            if not Player then goto continue end
            local team = Player:GetPropInt(Team_Offset)
            if team == 2 then table.insert(p, i) elseif team == 3 then table.insert(ct, i) end

            ::continue::
        end

        for i=1, #ct do table.insert(p, ct[i]) end

        for i=1, #p do
            local Player = IEntityList.GetPlayer(p[i])
            if not Player then goto continue end

            local PlayerInfo = CPlayerInfo.new()
            if (not Player:GetPlayerInfo(PlayerInfo)) then goto continue end

            local resource = Player:GetPlayerResource()
            local wins = resource:GetPropInt(Wins_Offset)
            local rank = resource:GetPropInt(Rank_Offset)
            local team = Player:GetPropInt(Team_Offset)
            local color = "\x02"
            if team == 2 then color = "\x09" elseif team == 3 then color = "\x0C" end
            if PlayerInfo.szName == "GOTV" or PlayerInfo.fakeplayer then goto continue end

            --IChatElement.ChatPrintf(0, 0, color .. PlayerInfo.szName .. ":\x01 " .. wins .. " Wins (" .. ranks[rank+1] .. ")") 
            IChatElement.ChatPrintf(0, 0, " " .. color .. PlayerInfo.szName .. ":\x01 " .. wins .. " Wins (" .. ranks[rank+1] .. ")")
            ::continue::
        end

        data = ""
    end

    if string.match(args[1], "$wins") then
        
        local returnText = string.sub(text, string.len(args[1]) + 1):sub(1, -2)

        local p = {}
        local ct = {}

        for i=1, 64 do
            local Player = IEntityList.GetPlayer(i)
            if not Player then goto continue end
            local team = Player:GetPropInt(Team_Offset)
            if team == 2 then table.insert(p, i) elseif team == 3 then table.insert(ct, i) end

            ::continue::
        end

        for i=1, #ct do table.insert(p, ct[i]) end

        for i=1, #p do
            local Player = IEntityList.GetPlayer(p[i])
            if not Player then goto continue end

            local PlayerInfo = CPlayerInfo.new()
            if (not Player:GetPlayerInfo(PlayerInfo)) then goto continue end

            local resource = Player:GetPlayerResource()
            local wins = resource:GetPropInt(Wins_Offset)
            local rank = resource:GetPropInt(Rank_Offset)
            local team = Player:GetPropInt(Team_Offset)
            local color = "???: "
            if team == 2 then color = "T: " elseif team == 3 then color = "CT: " end
            if PlayerInfo.szName == "GOTV" or PlayerInfo.fakeplayer then goto continue end

            --IChatElement.ChatPrintf(0, 0, color .. PlayerInfo.szName .. ":\x01 " .. wins .. " Wins (" .. ranks[rank+1] .. ")") 
            --Print("say " .. color .. PlayerInfo.szName .. ": " .. wins .. " Wins (" .. ranks[rank+1] .. ")")
            IEngine.ExecuteClientCmd("say " .. color .. PlayerInfo.szName .. ": " .. wins .. " Wins (" .. ranks[rank+1] .. ")")
            
            Sleep(0.8)
            ::continue::
        end

        data = ""
    end
    
end)

Hack.RegisterCallback("CreateMove", function (cmd, send)
    if printText then 
        IChatElement.ChatPrintf(0, 0, "\x01Set your clantag to \"\x02" .. sendText .. "\x01\"") 
        printText = false
    end
end)