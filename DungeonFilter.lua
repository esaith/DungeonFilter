SLASH_DUNGEONFILTER1 = '/drate'

local DungeonCategoryId = 2

function SlashCmdList.DUNGEONFILTER(msg, editbox)
    if DungeonFilter:IsShown() then
        DungeonFilter:Hide()
    else
        DungeonFilter:Show()
    end

    DungeonFilterRate:Show()
end

DungeonFilter.Dungeons = {}
DungeonFilter.Dungeons['tott'] = 'Throne of the Tides'
DungeonFilter.Dungeons['dht'] = 'Darkheart Thicket'
DungeonFilter.Dungeons['eb'] = 'The Everbloom'
DungeonFilter.Dungeons['brh'] = 'Black Rook Hold'
DungeonFilter.Dungeons['wm'] = 'Waycrest Manor'
DungeonFilter.Dungeons['fall'] = 'Galakrond\'s Fall - Dawn of the Infinite'
DungeonFilter.Dungeons['ad'] = 'Atal\'Dazar'
DungeonFilter.Dungeons['rise'] = 'Murozond\'s Rise - Dawn of the Infinite'
 
local reverseDungeons = {}
for k, v in pairs(DungeonFilter.Dungeons) do
    reverseDungeons[v .. ' (Mythic Keystone)'] = k
end

function DungeonFilter_OnLoad(self, event, ...)
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
    eDungeonFilter[self.Name] = self:GetChecked()
end

local function CreateLayout()
    local previousButton = nil;
    local btn = nil; 
    local fontstring = nil;

    for k, v in pairs(DungeonFilter.Dungeons) do
        btn = CreateFrame('CheckButton', 'DungeonFilter_' .. k .. '_CheckButton', DungeonFilter, 'UICheckButtonTemplate')        
        btn:SetSize(25, 25)
        btn.Name = k
        btn:SetScript('OnClick', ToggleOption)
        fontstring = btn:CreateFontString('$parent_FontString', 'ARTWORK', 'GameFontNormal')
        fontstring:SetText(v)
        fontstring:SetPoint('LEFT', '$parent', 'RIGHT', 0, 0)
        btn:SetFontString(fontstring)
        btn:Show()

        if previousButton == nil then
            btn:SetPoint('TOPLEFT', DungeonFilter, 'TOPLEFT', 20, -40)
        else            
            btn:SetPoint('TOP', previousButton, 'BOTTOM', 0, -5)
        end

        previousButton = _G['DungeonFilter_' .. k .. '_CheckButton']
    end
end

local function SetPartyRating(self)
    print('Called Set Party Rating')
end

local function CreateRateLayout()
    local index = 1
    local previousWidget = _G['DungeonFilterRate']

    while index <= 4 do
        index = index + 1
        local buttonName = 'Party'..index

        local btnA = CreateFrame('Button', 'DungeonFilter_' .. buttonName .. '_Rate_1_Button', _G['DungeonFilterRate'], 'UIMenuButtonStretchTemplate')        
        btnA:SetSize(50, 25)
        btnA.Name = buttonName
        btnA:SetScript('OnClick', SetPartyRating)
        btnA:SetPoint('TOPLEFT', previousWidget, 'TOPLEFT', 0, 15)
        local fontstring = btnA:CreateFontString('$parent_FontString', 'ARTWORK', 'GameFontNormal')
        fontstring:SetPoint('CENTER', '$parent', 'CENTER', 0, 0)
        fontstring:SetText('Bad')
        btnA:SetFontString(fontstring)
        btnA:Show()

        local btnB = CreateFrame('Button', 'DungeonFilter_' .. buttonName .. '_Rate_2_Button', _G['DungeonFilterRate'], 'UIMenuButtonStretchTemplate')        
        btnB:SetSize(50, 25)
        btnB.Name = buttonName
        btnB:SetScript('OnClick', SetPartyRating)
        btnB:SetPoint('LEFT', btnA, 'RIGHT', 15, 0)
        fontstring = btnB:CreateFontString('$parent_FontString', 'ARTWORK', 'GameFontNormal')
        fontstring:SetPoint('CENTER', '$parent', 'CENTER', 0, 0)
        fontstring:SetText('Average')
        btnB:SetFontString(fontstring)
        btnB:Show()

        local btnC = CreateFrame('Button', 'DungeonFilter_' .. buttonName .. '_Rate_3_Button', _G['DungeonFilterRate'], 'UIMenuButtonStretchTemplate')        
        btnC:SetSize(50, 25)
        btnC.Name = buttonName
        btnC:SetScript('OnClick', SetPartyRating)
        btnC:SetPoint('LEFT', btnb, 'RIGHT', 15, 0)
        fontstring = btnC:CreateFontString('$parent_FontString', 'ARTWORK', 'GameFontNormal')
        fontstring:SetText('Very good')
        fontstring:SetPoint('LEFT', '$parent', 'RIGHT', 0, 0)
        btnC:SetFontString(fontstring)
        btnC:Show()

        previousWidget = btnA
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

local function isTitleSpam(name)
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

    for k, v in pairs(DungeonFilter.Dungeons) do
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
            if not isTitleSpam(searchResultInfo.name) then
				local shortDungeonName = reverseDungeons[activityTable.fullName]

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

local function SetCheckBoxes()
    if eDungeonFilter ~= nil then
        for key, value in pairs(eDungeonFilter) do
            if _G['DungeonFilter_' .. key .. '_CheckButton'] ~= nil then
                _G['DungeonFilter_' .. key .. '_CheckButton']:SetChecked(value)
            end
        end
    else
        eDungeonFilter = {}
    end
end

local function printTable(tb, spacing)
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
            printTable(v, "   " .. spacing)
        else
            print(spacing .. "  ".. k .. ": " .. tostring(v))
        end
    end

    print(spacing .. '}')
end

local CURRENTPLAYER
local function getCurrentPlayer()
    if not CURRENTPLAYER then
        CURRENTPLAYER = UnitName("player") .. "-" .. GetRealmName()
        CURRENTPLAYER = string.gsub(CURRENTPLAYER, " ", "")
    end

    return CURRENTPLAYER
end

DungeonFilter.GetParty = function()
    local partyInfo = GetHomePartyInfo() or {}
    local party = {};

    for i, partyMember in pairs(partyInfo) do
        if partyMember:find("-") == nil then
            partyMember = partyMember .. "-" .. realmName
        end

        table.insert(party, partyMember)
    end

    return party;
end

local function MostRecentlyAddedPartyMatchesCurrentParty(currentParty)
    if eDungeonFilterParty == nil then
        print('History is nil for most recently added party check.')
        return false;
    end

    local historyLength = #eDungeonFilterParty

    if historyLength ~= nil then
        local lastParty = eDungeonFilterParty[historyLength - 1]

        if lastParty == nil then
            print("Unable to get last party.")
            return false;
        end

        for i, partyMember in ipairs(currentParty) do
            if i > 2 then            
                if lastParty[i] ~= nil then
                    if partyMember.Name ~= lastParty[i].Name then
                        print("Party member name does not match: "..partyMember.Name.. ", "..lastParty[i].Name)
                        return false;
                    end
                else
                    print('Unable to get lastParty member by index');
                    return false;
                end 
            end
        end
    else 
        print("Unable to get last element in eDungeonFilterParty")
    end

    print('All party member names match')
    return true;
end

local function ChallengeModeStart()    
    local _, _, difficulty, _, _, _, _, lfgDungeonId = GetInstanceInfo()
    -- if (lfgDungeonId == 8) then
        local PartyList = {}
        table.insert(PartyList, time())
        table.insert(PartyList, getCurrentPlayer())

        local count = 0;
        for i, partyMember in pairs(GetParty()) do
            count = count + 1
            table.insert(PartyList, {
                Name = partyMember,
                Rating = 0
            })
        end

        if count > 0 and MostRecentlyAddedPartyMatchesCurrentParty(PartyList) == false then
            table.insert(eDungeonFilterParty, PartyList)            
        end
    -- end   
end

local function RateMythicRun()

end

function DungeonFilter_OnEvent(self, event, arg1, arg2)
    if event == 'ADDON_LOADED' and arg1 == 'DungeonFilter' then
        CreateLayout()
        CreateRateLayout()
        AddHooks()
        SetCheckBoxes()  
        ChallengeModeStart()  
        
        if eDungeonFilterParty == nil then
            eDungeonFilterParty = {}
        end      
    elseif event == 'LFG_LIST_SEARCH_RESULTS_RECEIVED' or event == 'LFG_LOCK_INFO_RECEIVED' then
        ShowDungeonFilter()
    elseif event == 'CHALLENGE_MODE_START' then
        ChallengeModeStart()
    elseif event == 'CHALLENGE_MODE_COMPLETED' then        
        RateMythicRun()
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
