SLASH_DUNGEONFILTER1 = '/dfilter'

local DungeonCategoryId = 2

function SlashCmdList.DUNGEONFILTER(msg, editbox)
    if DungeonFilter:IsShown() then
        DungeonFilter:Hide()
    else
        DungeonFilter:Show()
    end
end

local dungeons = {}
dungeons['tott'] = 'Throne of the Tides'
dungeons['dht'] = 'Darkheart Thicket'
dungeons['eb'] = 'The Everbloom'
dungeons['brh'] = 'Black Rook Hold'
dungeons['wm'] = 'Waycrest Manor'
dungeons['fall'] = 'Galakrond\'s Fall - Dawn of the Infinite'
dungeons['ad'] = 'Atal\'Dazar'
dungeons['rise'] = 'Murozond\'s Rise - Dawn of the Infinite'
 
local reverseDungeons = {}
for k, v in pairs(dungeons) do
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

    for k, v in pairs(dungeons) do
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

    for k, v in pairs(dungeons) do
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

function DungeonFilter_OnEvent(self, event, arg1, arg2)
    if event == 'ADDON_LOADED' and arg1 == 'DungeonFilter' then
        CreateLayout()
        AddHooks()
        SetCheckBoxes()
    elseif event == 'LFG_LIST_SEARCH_RESULTS_RECEIVED' or event == 'LFG_LOCK_INFO_RECEIVED' then
        ShowDungeonFilter()
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