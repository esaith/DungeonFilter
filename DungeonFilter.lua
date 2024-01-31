SLASH_DUNGEONFILTER1 = '/rate'
SLASH_DUNGEONFILTER1 = '/erate'

local DungeonCategoryId = 2
eDungeonFilter = {}


function DungeonFilter_OnLoad(self, event, ...)
    self:RegisterForDrag('LeftButton', 'RightButton')
    self:RegisterEvent('ADDON_LOADED')
    self:RegisterEvent('PLAYER_LOGOUT')
    self:RegisterEvent('LFG_LIST_SEARCH_RESULTS_RECEIVED')
    self:RegisterEvent('LFG_LOCK_INFO_RECEIVED')

    eDungeonFilter.Dungeons = {}
    eDungeonFilter.Dungeons['tott'] = 'Throne of the Tides'
    eDungeonFilter.Dungeons['dht'] = 'Darkheart Thicket'
    eDungeonFilter.Dungeons['eb'] = 'The Everbloom'
    eDungeonFilter.Dungeons['brh'] = 'Black Rook Hold'
    eDungeonFilter.Dungeons['wm'] = 'Waycrest Manor'
    eDungeonFilter.Dungeons['fall'] = 'Galakrond\'s Fall - Dawn of the Infinite'
    eDungeonFilter.Dungeons['ad'] = 'Atal\'Dazar'
    eDungeonFilter.Dungeons['rise'] = 'Murozond\'s Rise - Dawn of the Infinite'

    eDungeonFilter.ReversedDungeons = {}
    for k, v in pairs(eDungeonFilter.Dungeons) do
        eDungeonFilter.ReversedDungeons[v .. ' (Mythic Keystone)'] = k
    end
end

function DungeonFilterRate_OnLoad(self, event, ...)
    self:RegisterForDrag('LeftButton', 'RightButton')
    self:RegisterEvent('ADDON_LOADED')
    self:RegisterEvent('PLAYER_LOGOUT')
    self:RegisterEvent('LFG_LIST_SEARCH_RESULTS_RECEIVED')
    self:RegisterEvent('LFG_LOCK_INFO_RECEIVED')
end

local function ShowDungeonFilter()
    if
        LFGListFrame.SearchPanel:IsShown() and LFGListFrame.SearchPanel.categoryID == DungeonCategoryId and
            LFGListFrame.SearchPanel.SearchBox:IsShown()
     then
        DungeonFilter:Show()
    else
        DungeonFilter:Hide()
    end
end

local function ToggleOption(self)
    eDungeonFilterVar[self.Name] = self:GetChecked()
end

local function CreateLayout()
    local previousButton = nil;
    local btn = nil;
    local fontstring = nil;

    for k, v in pairs(eDungeonFilter.Dungeons) do
        btn = CreateFrame('CheckButton', 'DungeonFilter_' .. k .. '_CheckButton', DungeonFilter, 'UICheckButtonTemplate')
        btn:SetSize(25, 25)
        btn.Name = k
        btn:SetScript('OnClick', ToggleOption)
        fontstring = btn:CreateFontString('$parent_FontString', 'ARTWORK', 'GameFontNormal')
        fontstring:SetText(v)
        fontstring:SetPoint('LEFT', '$parent', 'RIGHT', 0, 0)
        btn:SetFontString(fontstring)
        btn:Show()

        if eDungeonFilterVar ~= nil and eDungeonFilterVar[k] ~= nil then
            btn:SetChecked(eDungeonFilterVar[k])
        end

        if previousButton == nil then
            btn:SetPoint('TOPLEFT', DungeonFilter, 'TOPLEFT', 20, -40)
        else
            btn:SetPoint('TOP', previousButton, 'BOTTOM', 0, -5)
        end

        previousButton = _G['DungeonFilter_' .. k .. '_CheckButton']
    end
end

local function GetRateButtonName(row, column)
    if row == nil then
        print("Unable to get button name. Row is nil")
        return
    end

    if column == nil then
        print("Unable to get button name. Column is nil")
        return
    end

    return 'DungeonFilterRate_Party' .. row .. '_Button' .. column ..'_Button'
end

function SetPartyMemberRating(self)
    local fontString = self:GetFontString();
    local r,g,b,a = fontString:GetTextColor();

    if r == 0 then
        fontString:SetTextColor(1,1,1)
    else
        fontString:SetTextColor(0,1,0)
    end

    local column = 0
    while column < 4 do
        column = column + 1
        if self.Column ~= column then
            local fontString = _G[GetRateButtonName(self.Row, column)]:GetFontString()
            fontString:SetTextColor(1,1,1)
        end
    end
end

local function AddRateButton(label, row, column,  neighborButton)
    local name = GetRateButtonName(row, column)
    local button = CreateFrame('Button', name, DungeonFilterRate, 'UIMenuButtonStretchTemplate')

    if string.len(label) <= 4 then
        button:SetSize(50, 25)
    elseif string.len(label) <= 10 then
        button:SetSize(75, 25)
    else
        button:SetSize(100, 25)
    end

    button.Name = name
    button.Row = row
    button.Column = column    

    button:SetScript('OnClick', SetPartyMemberRating)

    if column == 1 then
        button:SetPoint('TOPLEFT', neighborButton, 'BOTTOMLEFT', 0, -5)
    else
        button:SetPoint('LEFT', neighborButton, 'RIGHT', 10, 0)
    end

    button:Show()

    local fontstring = button:CreateFontString('$parent_FontString', 'ARTWORK', 'GameFontNormal')
    fontstring:SetPoint('CENTER', '$parent', 'CENTER', 0, 0)
    fontstring:SetText(label)
    button:SetFontString(fontstring)

    return button
end

local function ResetRateButtons()
    local row = 0

    while row < 4 do
        local column = 0
        row = row + 1

        while column < 4 do
            column = column + 1
            _G[GetRateButtonName(row, column)]:SetTextColor(1,1,1)
        end
    end
end

local function UpdateRateButtons()
    if eDungeonFilter.CurrentParty == nil then
        return
    end

    for key, memberInfo in ipairs(eDungeonFilter.CurrentParty) do
        _G['DungeonFilterRate_FontString'..key]:SetText(memberInfo.Name)
    end

    ResetRateButtons()
end

local function CreateRateLayout()
    local row = 0
    local previousWidget = DungeonFilterRate
    DungeonFilterRate:SetScale(2.5)

    while row < 2 do
        row = row + 1

        local fontstring = DungeonFilterRate:CreateFontString('DungeonFilterRate_FontString'..row, 'ARTWORK', 'GameFontNormal')

        if row == 1 then
            fontstring:SetPoint('TOPLEFT', previousWidget, 'TOPLEFT', 15, -35)
        else
            fontstring:SetPoint('TOPLEFT', previousWidget, 'TOPLEFT', 0, -80)
        end

        fontstring:SetText('Player '.. row)

        local btnA = AddRateButton('Bad', row, 1, fontstring)
        local btnB = AddRateButton('Meh', row, 2, btnA)
        local btnC = AddRateButton('Good', row, 3, btnB)
        local btnD = AddRateButton('Very Good', row, 4, btnC)
        
        local name = "DungeonFilterRate_EditBox_"..row
        local editButton = CreateFrame('EditBox', name, DungeonFilterRate, 'ChatFrameEditBoxTemplateCustom')
        editButton:SetPoint('TOPLEFT', btnA, 'BOTTOMLEFT', 5, -10)
      
        editButton:SetFontObject("GameFontNormal")
        editButton:SetAutoFocus(false)
        
        
        -- sf:SetScrollChild(eb)

        previousWidget = editButton
    end
end

local function getKeysSortedByValue(tbl, sortFunction)
    local keys = {}
    for key in pairs(tbl) do
        table.insert(keys, key)
    end

    table.sort(
        keys,
        function(a, b)
            return sortFunction(tbl[a], tbl[b])
        end
    )

    return keys
end

local function IsTitleSpam(name)
    if name == nil then
        return true
    end

    local val = ' ' .. name .. ' '

    local result =
        string.find(name, 'WTS') == nil and string.find(name, 'LOOT') == nil and string.find(name, 'CARRY') == nil and
        string.find(name, 'OFF') == nil and
        string.find(name, 'Fast') == nil and
        string.find(name, 'FAST') == nil and
        string.find(name, 'twitch') == nil and
        string.find(name, 'Twitch') == nil and
        string.find(name, 'free') == nil and
        string.find(name, 'Free') == nil and
        string.find(name, 'FREE') == nil

    return (not result)
end

local function LFGListUtil_SortSearchResults_Hook(results)
    local filtering = false

    for k, v in pairs(eDungeonFilter.Dungeons) do
        if _G['DungeonFilter_' .. k .. '_CheckButton']:GetChecked() then
            filtering = true
        end
    end

    if not filtering then
        LFGListFrame.SearchPanel.results = results
        LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel)
        return
    end

    local idsToRemove = {}

    for _, searchId in pairs(results) do
        local searchResultInfo = C_LFGList.GetSearchResultInfo(searchId)
        local activityTable = C_LFGList.GetActivityInfoTable(searchResultInfo.activityID)

        if activityTable.isMythicPlusActivity then
            if not IsTitleSpam(searchResultInfo.name) then
				local shortDungeonName = DungeonFilter.ReversedDungeons[activityTable.fullName]

				if shortDungeonName == nil then
					print(activityTable.fullName)
				else
					if not _G['DungeonFilter_' .. shortDungeonName .. '_CheckButton']:GetChecked() then
						for i = 1, #results, 1 do
							if (results[i] == searchId) then
								table.insert(idsToRemove, i)
								break
							end
						end
					end
				end
            end
        end
    end

    local sortedKeys = getKeysSortedByValue(idsToRemove, function(a, b) return a > b end)

    for _, key in ipairs(sortedKeys) do
        table.remove(results, idsToRemove[key])
    end

    LFGListFrame.SearchPanel.results = results
    LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel)
end

local function AddHooks()
    hooksecurefunc('LFGListUtil_SortSearchResults', LFGListUtil_SortSearchResults_Hook)
end

eDungeonFilter.PrintTable = function (tb, spacing)
    if spacing == nil then
        spacing = ""
    end

    if tb == nil then
        print("nil")
        return
    end

    print(spacing..'{')

    if type(tb) == "string" then
        print("String: " .. tb)
        return
    end

    if type(tb) == "number" then
        print("Number: " .. tostring(tb))
        return
    end

    local count = 0
    for k, v in pairs(tb) do
        if type(v) == "table" then
            eDungeonFilter.PrintTable(v, "   " .. spacing)
        else
            print(spacing .. "  ".. k .. ": " .. tostring(v))
        end
    end

    print(spacing .. '}')
end

eDungeonFilter.GetParty = function()
    -- local partyInfo = GetHomePartyInfo() or {}
    -- local party = {};

    -- for i, partyMember in pairs(partyInfo) do
    --     if partyMember:find("-") == nil then
    --         partyMember = partyMember .. "-" .. realmName
    --     end

    --     table.insert(party, partyMember)
    -- end

    local result = {}
    table.insert(result, { Name = "Saith" })
    table.insert(result, { Name = "Targether-Anub" })
    table.insert(result, { Name = "Hatis-Stormscale" })
    table.insert(result, { Name = "Disc-Stormscale" })

    return result

    -- return party;
end

eDungeonFilter.IsInMythicPlus = function ()
    return true
    -- local _, _, difficultyId = GetInstanceInfo()
    -- return difficultyId == 8
end

eDungeonFilter.CurrentParty = nil
eDungeonFilter.SetCurrentParty = function()
    local isInMythicPlus = eDungeonFilter.IsInMythicPlus()

    if isInMythicPlus then
        eDungeonFilter.CurrentParty = eDungeonFilter.GetParty()
    else
        eDungeonFilter.CurrentParty = nil
    end
end

eDungeonFilter.UpdateRateUI = function()

end

eDungeonFilter.RatePlayers = function()
    eDungeonFilter.UpdateRateUI()
    eDungeonFilter.Show()
end

eDungeonFilter.OnGroupRosterUpdate = function()
    if eDungeonFilter.CurrentParty ~= nil then
        eDungeonFilter.RatePlayers()
        eDungeonFilter.CurrentParty = nil;
    end
end

function DungeonFilter_OnEvent(self, event, arg1, arg2)
    if event == 'ADDON_LOADED' and arg1 == 'DungeonFilter' then
        CreateLayout()
        CreateRateLayout()
        AddHooks()

        eDungeonFilter.SetCurrentParty()
    elseif event == 'LFG_LIST_SEARCH_RESULTS_RECEIVED' or event == 'LFG_LOCK_INFO_RECEIVED' then
        ShowDungeonFilter()
    elseif event == 'CHALLENGE_MODE_START' then
        eDungeonFilter.SetCurrentParty()
    elseif event == 'CHALLENGE_MODE_COMPLETED' then
        eDungeonFilter.RatePlayers()
    elseif event == 'GROUP_ROSTER_UPDATE' then
        eDungeonFilter.OnGroupRosterUpdate()
    end
end

function DungeonFilter_OnMouseDown(self, event, ...)
    if event == 'LeftButton' then
        self:StartMoving()
    end
end

function DungeonFilter_OnMouseUp(self, event, ...)
    self:StopMovingOrSizing()
end

function DungeonFilter_OnStopDrag(self, event, ...)
    self:StopMovingOrSizing()
end

-- The following is code snippet to help prevent the follow LUA error that Blizzard throws
-- ADDON_ACTION_BLOCKED due to protected function GetPlaystyleString()
-- https://github.com/0xbs/premade-groups-filter/issues/64

function LFMPlus_GetPlaystyleString(playstyle,activityInfo)
    if activityInfo and playstyle ~= (0 or nil) and C_LFGList.GetLfgCategoryInfo(activityInfo.categoryID).showPlaystyleDropdown then
      local typeStr
      if activityInfo.isMythicPlusActivity then
        typeStr = "GROUP_FINDER_PVE_PLAYSTYLE"
      elseif activityInfo.isRatedPvpActivity then
        typeStr = "GROUP_FINDER_PVP_PLAYSTYLE"
      elseif activityInfo.isCurrentRaidActivity then
        typeStr = "GROUP_FINDER_PVE_RAID_PLAYSTYLE"
      elseif activityInfo.isMythicActivity then
        typeStr = "GROUP_FINDER_PVE_MYTHICZERO_PLAYSTYLE"
      end
      return typeStr and _G[typeStr .. tostring(playstyle)] or nil
    else
      return nil
    end
end

C_LFGList.GetPlaystyleString = function(playstyle,activityInfo)
    return LFMPlus_GetPlaystyleString(playstyle, activityInfo)
end

function SlashCmdList.DUNGEONFILTER(msg, editbox)
    if DungeonFilter:IsShown() then
        DungeonFilter:Hide()
    else
        DungeonFilter:Show()
    end

    DungeonFilterRate:Show()

    UpdateRateButtons()
end