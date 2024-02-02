if SlashCmdList == nil then
    SlashCmdList = {}
end

if eDungeonFilter == nil then
    eDungeonFilter = {}
end

if eDungeonFilter == nil then
    eDungeonFilter = {}
end

if C_LFGList == nil then
    C_LFGList = {}
end

if C_ChallengeMode == nil then
    C_ChallengeMode = {}
end

local localButtons
eDungeonFilter.GetButton = function(name)
    if localButtons[name] ~= nil then
        return localButtons[name]
    end

    print("Creating button for " .. name)

    local button = {
        Name = ""
    }

    function button:GetFontString(self)
        print("Getting button font string")
        return eDungeonFilter.GetFontString(self.Name)
    end

    localButtons[name] = button
    return button
end

local localFontStrings = {}
eDungeonFilter.GetFontString = function(name)
    if localFontStrings[name] ~= nil then
        print("Returning font string " .. name)
        return localFontStrings[name]
    end

    print("Creating fontstring for " .. name)
    local fontString = {
        Name = "",
        myString = ""
    }

    function fontString:GetName(self)
        self.Name = name
    end

    function fontString:GetText(self)
        print("Getting font string for " .. self.Name)
        return self.myString
    end

    function fontString:SetText(self, str)
        print("Setting font string for " .. self.Name .. ", " .. str)
        self.myString = str
    end

    function fontString:SetTextColor(self, r, g, b, a)
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    end

    function fontString:GetTextColor(self, r, g, b, a)
        self.r = r
        self.g = g
        self.b = b
        self.a = a

        return {
            r = self.r,
            g = self.g,
            b = self.b,
            a = self.a
        }
    end

    localFontStrings[name] = fontString
    return fontString
end

if DungeonFilterRate == nil then
    DungeonFilterRate = {}
end
