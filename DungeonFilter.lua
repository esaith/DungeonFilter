SLASH_DUNGEONFILTER1 = "/rate"
SLASH_DUNGEONFILTER2 = "/erate"

local DungeonCategoryId = 2
eDungeonFilter = {}

if eDungeonFilterVar == nil then
    eDungeonFilterVar = {}
end

if eDungeonFilterVar.Player == nil then
    eDungeonFilterVar.Player = {}
end

local dungeons = {}
dungeons["tott"] = "Throne of the Tides"
dungeons["dht"] = "Darkheart Thicket"
dungeons["eb"] = "The Everbloom"
dungeons["brh"] = "Black Rook Hold"
dungeons["wm"] = "Waycrest Manor"
dungeons["fall"] = "Galakrond's Fall - Dawn of the Infinite"
dungeons["ad"] = "Atal'Dazar"
dungeons["rise"] = "Murozond's Rise - Dawn of the Infinite"

reversedDungeons = {}
for k, v in pairs(dungeons) do
    reversedDungeons[v .. " (Mythic Keystone)"] = k
end

function DungeonFilter_OnLoad(self, event, ...)
    self:RegisterForDrag("LeftButton", "RightButton")
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
    self:RegisterEvent("LFG_LOCK_INFO_RECEIVED")
    self:RegisterEvent("CHALLENGE_MODE_START")
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
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
    local previousButton = nil
    local btn = nil
    local fontstring = nil

    for k, v in pairs(dungeons) do
        btn =
            CreateFrame("CheckButton", "DungeonFilter_" .. k .. "_CheckButton", DungeonFilter, "UICheckButtonTemplate")
        btn:SetSize(25, 25)
        btn.Name = k
        btn:SetScript("OnClick", ToggleOption)
        fontstring = btn:CreateFontString("$parent_FontString", "ARTWORK", "GameFontNormal")
        fontstring:SetText(v)
        fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
        btn:SetFontString(fontstring)
        btn:Show()

        if eDungeonFilterVar ~= nil and eDungeonFilterVar[k] ~= nil then
            btn:SetChecked(eDungeonFilterVar[k])
        end

        if previousButton == nil then
            btn:SetPoint("TOPLEFT", DungeonFilter, "TOPLEFT", 20, -40)
        else
            btn:SetPoint("TOP", previousButton, "BOTTOM", 0, -5)
        end

        previousButton = _G["DungeonFilter_" .. k .. "_CheckButton"]
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

    return "DungeonFilterRate_Party" .. row .. "_Button" .. column .. "_Button"
end

function SetPartyMemberRating(self)
    local fontString = self:GetFontString()
    local r, g, b, a = fontString:GetTextColor()

    if r == 0 then
        fontString:SetTextColor(1, 1, 1)
    else
        fontString:SetTextColor(0, 1, 0)
    end

    local column = 0
    while column < 4 do
        column = column + 1
        if self.Column ~= column then
            local fontString = _G[GetRateButtonName(self.Row, column)]:GetFontString()
            fontString:SetTextColor(1, 1, 1)
        end
    end
end

local function AddRateButton(label, row, column, neighborButton)
    local name = GetRateButtonName(row, column)
    local button = CreateFrame("Button", name, DungeonFilterRate, "UIMenuButtonStretchTemplate")

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

    button:SetScript("OnClick", SetPartyMemberRating)

    if column == 1 then
        button:SetPoint("TOPLEFT", neighborButton, "BOTTOMLEFT", -5, -5)
    else
        button:SetPoint("LEFT", neighborButton, "RIGHT", 10, 0)
    end

    button:Show()

    local fontstring = button:CreateFontString("$parent_FontString", "ARTWORK", "GameFontNormal")
    fontstring:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
    fontstring:SetText(label)
    button:SetFontString(fontstring)

    return button
end

local function ResetRateButtons()
    local row = 0

    while row < 4 do
        local column = 0
        row = row + 1
        local editBox = _G["DungeonFilterRate_EditBox_" .. row]
        editBox:SetText("")

        while column < 4 do
            column = column + 1
            local fontString = eDungeonFilter.GetButton(GetRateButtonName(row, column)):GetFontString()
            fontString:SetTextColor(1, 1, 1)
        end
    end
end

local function UpdateRateButtons()
    if eDungeonFilter == nil then
        print("eDungeonFilter is nil!??!?!")
    end

    local cachedParty = eDungeonFilter.GetCachedParty()
    if cachedParty == nil then
        print("cachedParty is empty. Skipping updating rate buttons")
        return
    end

    for key, name in ipairs(cachedParty.Players) do
        local fontString = eDungeonFilter.GetFontString("DungeonFilterRate_FontString" .. key)

        if fontString == nil then
            print("Font string is nil " .. key)
        end

        fontString:SetText(name)
    end

    ResetRateButtons()
end

local function SubmitRating()
    DungeonFilterRate:Hide()
    local todaysDate = date("%b %d, %Y")

    if eDungeonFilterPartyTemp == nil then
        ResetRateButtons()
        return
    end

    for row, playerName in ipairs(eDungeonFilterPartyTemp.Players) do
        local column = 0
        local rating = 0
        local editBox = _G["DungeonFilterRate_EditBox_" .. row]
        local note = nil

        if editBox ~= nil then
            note = editBox:GetText()
        end

        while column < 4 do
            column = column + 1

            local fontString = _G[GetRateButtonName(row, column)]:GetFontString()
            local r, g, b, a = fontString:GetTextColor()

            if r == 0 then
                rating = column
            end
        end

        if rating > 0 or note ~= nil and string.len(note) > 0 then
            if eDungeonFilterVar.Player[playerName] == nil then
                eDungeonFilterVar.Player[playerName] = {}
            end

            if eDungeonFilterVar.Player[playerName].Entry == nil then
                eDungeonFilterVar.Player[playerName].Entry = {}
            end

            local entry = {
                Date = todaysDate,
                DifficultyLevel = eDungeonFilterPartyTemp.Level,
                DungeonName = eDungeonFilterPartyTemp.DungeonName,
                Rate = row,
                Note = note
            }

            table.insert(eDungeonFilterVar.Player[playerName].Entry, entry)
        end
    end

    ResetRateButtons()
    eDungeonFilterPartyTemp = nil
end

local function CreateSubmitButton()
    local name = "DungeonFilterRate_Submit_Button"
    local button = CreateFrame("Button", name, DungeonFilterRate, "UIMenuButtonStretchTemplate")

    button:SetSize(50, 25)
    button.Name = name
    button:SetScript("OnClick", SubmitRating)

    button:SetPoint("TOPRIGHT", DungeonFilterRate, "TOPRIGHT", -15, -33)
    button:Show()

    local fontstring = button:CreateFontString("$parent_FontString", "ARTWORK", "GameFontNormal")
    fontstring:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
    fontstring:SetText("Submit")
    button:SetFontString(fontstring)
end

local function CreateRateLayout()
    local row = 0
    local previousWidget = DungeonFilterRate

    while row < 4 do
        row = row + 1
        local fontstring =
            DungeonFilterRate:CreateFontString("DungeonFilterRate_FontString" .. row, "ARTWORK", "GameFontNormal")

        if row == 1 then
            fontstring:SetPoint("TOPLEFT", previousWidget, "TOPLEFT", 20, -35)
        else
            fontstring:SetPoint("TOPLEFT", previousWidget, "BOTTOMLEFT", 0, -40)
        end

        fontstring:SetText("Party" .. row)

        local btnA = AddRateButton("Bad", row, 1, fontstring)
        local btnB = AddRateButton("Meh", row, 2, btnA)
        local btnC = AddRateButton("Good", row, 3, btnB)
        local btnD = AddRateButton("Very Good", row, 4, btnC)

        local name = "DungeonFilterRate_EditBox_" .. row
        local editButton = CreateFrame("EditBox", name, DungeonFilterRate, "ChatFrameEditBoxTemplateCustom")
        editButton:SetPoint("TOPLEFT", btnA, "BOTTOMLEFT", 5, -10)

        previousWidget = editButton
    end

    CreateSubmitButton(previousWidget)
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

    local val = " " .. name .. " "

    local result =
        string.find(name, "WTS") == nil and string.find(name, "LOOT") == nil and string.find(name, "CARRY") == nil and
        string.find(name, "OFF") == nil and
        string.find(name, "Fast") == nil and
        string.find(name, "FAST") == nil and
        string.find(name, "twitch") == nil and
        string.find(name, "Twitch") == nil and
        string.find(name, "free") == nil and
        string.find(name, "Free") == nil and
        string.find(name, "FREE") == nil

    return (not result)
end

local function LFGListUtil_SortSearchResults_Hook(results)
    local filtering = false

    for k, v in pairs(dungeons) do
        if _G["DungeonFilter_" .. k .. "_CheckButton"]:GetChecked() then
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
                local shortDungeonName = reversedDungeons[activityTable.fullName]

                if shortDungeonName == nil then
                    print(activityTable.fullName)
                else
                    if not _G["DungeonFilter_" .. shortDungeonName .. "_CheckButton"]:GetChecked() then
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

    local sortedKeys =
        getKeysSortedByValue(
        idsToRemove,
        function(a, b)
            return a > b
        end
    )

    for _, key in ipairs(sortedKeys) do
        table.remove(results, idsToRemove[key])
    end

    LFGListFrame.SearchPanel.results = results
    LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel)
end

local function AddHooks()
    hooksecurefunc("LFGListUtil_SortSearchResults", LFGListUtil_SortSearchResults_Hook)
end

eDungeonFilter.PrintTable = function(tb, spacing)
    if spacing == nil then
        spacing = ""
    end

    if tb == nil then
        print("nil")
        return
    end

    if type(tb) == "string" then
        print("Data type string: " .. tb)
        return
    end

    if type(tb) == "number" then
        print("Data type number: " .. tostring(tb))
        return
    end

    if type(tb) == "boolean" then
        print("Data type boolean: " .. tostring(tb))
        return
    end

    print(spacing .. "{")

    local count = 0
    for k, v in pairs(tb) do
        if type(v) == "table" then
            print(spacing .. "  " .. k .. ":")
            eDungeonFilter.PrintTable(v, "  " .. spacing)
        else
            print(spacing .. "  " .. k .. ": " .. tostring(v))
        end
    end

    print(spacing .. "}")
end

eDungeonFilter.GetParty = function()
    local partyInfo = GetHomePartyInfo() or {}
    local result = {}

    for i, partyMember in pairs(partyInfo) do
        if partyMember:find("-") == nil then
            partyMember = partyMember .. "-" .. realmName
        end

        table.insert(result, partyMember)
    end

    -- table.insert(result, "Saith")
    -- table.insert(result, "Targether-Anub")
    -- table.insert(result, "Hatis-Stormscale")
    -- table.insert(result, "Disc-Stormscale")

    return result
end

eDungeonFilter.GetInstanceInfo = function()
    return GetInstanceInfo()
end

eDungeonFilter.GetActiveKeystoneInfo = function()
    return C_ChallengeMode.GetActiveKeystoneInfo()
end

eDungeonFilter.CacheParty = function()
    if C_ChallengeMode.IsChallengeModeActive() then
        eDungeonFilterPartyTemp = {
            Players = eDungeonFilter.GetParty(),
            DungeonName = eDungeonFilter.GetInstanceInfo(),
            Level = eDungeonFilter.GetActiveKeystoneInfo()
        }
    end
end

eDungeonFilter.GetCachedParty = function()
    return eDungeonFilterPartyTemp
end

eDungeonFilter.OnChallengeModeStart = function()
    eDungeonFilter.CacheParty()
end

eDungeonFilter.OnChallengeModeComplete = function()
    UpdateRateButtons()
    DungeonFilterRate:Show()
end

eDungeonFilter.OnGroupRosterUpdate = function()
    -- if eDungeonFilterPartyTemp ~= nil then
    --     DungeonFilterRate:Show()
    -- end
end

eDungeonFilter.AddOnLoaded = function()
    CreateRateLayout()
    eDungeonFilter.CacheParty()
end

eDungeonFilter.GetFontString = function(name)
    return _G[name]
end

eDungeonFilter.GetButton = function(name)
    return _G[name]
end

function DungeonFilter_OnEvent(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "DungeonFilter" then
        CreateLayout()
        AddHooks()
        eDungeonFilter.AddOnLoaded()
    elseif event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" or event == "LFG_LOCK_INFO_RECEIVED" then
        ShowDungeonFilter()
    elseif event == "CHALLENGE_MODE_START" then
        eDungeonFilter.CacheParty()
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        eDungeonFilter.OnChallengeModeComplete()
    elseif event == "GROUP_ROSTER_UPDATE" then
        eDungeonFilter.OnGroupRosterUpdate()
    end
end

function DungeonFilter_OnMouseDown(self, event, ...)
    if event == "LeftButton" then
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

function LFMPlus_GetPlaystyleString(playstyle, activityInfo)
    if
        activityInfo and playstyle ~= (0 or nil) and
            C_LFGList.GetLfgCategoryInfo(activityInfo.categoryID).showPlaystyleDropdown
     then
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

C_LFGList.GetPlaystyleString = function(playstyle, activityInfo)
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
