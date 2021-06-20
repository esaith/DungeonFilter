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
dungeons['dos'] = 'De Other Side'
dungeons['hoa'] = 'Halls of Atonement'
dungeons['mots'] = 'Mists of Tirna Scithe'
dungeons['pf'] = 'Plaguefall'
dungeons['sd'] = 'Sanguine Depths'
dungeons['soa'] = 'Spires of Ascension'
dungeons['tnw'] = 'The Necrotic Wake'
dungeons['top'] = 'Theater of Pain'

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
    local btn = CreateFrame('CheckButton', 'DungeonFilter_dos_CheckButton', DungeonFilter, 'UICheckButtonTemplate')
    btn:SetPoint('TOPLEFT', DungeonFilter, 'TOPLEFT', 20, -40)
    btn:SetSize(25, 25)
    btn.Name = 'dos'
    btn:SetScript('OnClick', ToggleOption)
    local fontstring = btn:CreateFontString('$parent_FontString', 'ARTWORK', 'GameFontNormal')
    fontstring:SetText('De Other Side')
    fontstring:SetPoint('LEFT', '$parent', 'RIGHT', 0, 0)
    btn:SetFontString(fontstring)
    btn:Show()

    local previousButton = _G['DungeonFilter_dos_CheckButton']

    for k, v in pairs(dungeons) do
        if k ~= 'dos' then
            btn =
                CreateFrame(
                'CheckButton',
                'DungeonFilter_' .. k .. '_CheckButton',
                DungeonFilter,
                'UICheckButtonTemplate'
            )

            btn.Name = k
            btn:SetPoint('TOP', previousButton, 'BOTTOM', 0, -5)
            btn:SetSize(25, 25)
            btn:SetScript('OnClick', ToggleOption)
            fontstring = btn:CreateFontString('$parent_FontString', 'ARTWORK', 'GameFontNormal')
            fontstring:SetText(v)
            fontstring:SetPoint('LEFT', '$parent', 'RIGHT', 0, 0)
            btn:SetFontString(fontstring)
            btn:Show()
            previousButton = _G['DungeonFilter_' .. k .. '_CheckButton']
        end
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
        local activityName = C_LFGList.GetActivityInfo(searchResultInfo.activityID, nil, searchResultInfo.isWarMode)

        if string.find(activityName, 'Keystone') and not isTitleSpam(searchResultInfo.name) then
            local shortDungeonName = reverseDungeons[activityName]

            if not _G['DungeonFilter_' .. shortDungeonName .. '_CheckButton']:GetChecked() then
                for i = 1, #results, 1 do
                    if (results[i] == searchId) then
                        table.insert(idsToRemove, i)
                        break
                    end
                end
            end
        else
            for i = 1, #results, 1 do
                if (results[i] == searchId) then
                    table.insert(idsToRemove, i)
                    break
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
    hooksecurefunc('LFGListUtil_SortSearchResults', LFGListUtil_SortSearchResults_Hook)
end

local function SetCheckBoxes()
    if eDungeonFilter ~= nil then
        for key, value in pairs(eDungeonFilter) do
            _G['DungeonFilter_' .. key .. '_CheckButton']:SetChecked(value)
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
