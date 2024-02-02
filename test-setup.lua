---@diagnostic disable: duplicate-set-field, lowercase-global, undefined-global


if eDungeonFilter == nil then
    eDungeonFilter = {}
end

if eDungeonFilterMythicGroup == nil then
    eDungeonFilterMythicGroup = {}
end


local localFontStrings = {}
function eDungeonFilter.GetFontString(name)
    if localFontStrings[name] ~= nil then
        return localFontStrings[name]
    end

    return nil;
end

function UpdateName(name, parent)
    if parent == nil then
        return name
    end

    local index = string.find(name, '$parent')
    if index == nil then
        return name
    end

    name = string.gsub(name, '$parent', parent)
    return name
end

local localFrames = {}
function eDungeonFilter.CreateFrame(type, name, parent, template)
    name = UpdateName(name, parent)

    local frame = {
        Name = name,
        Parent = parent,
        Template = template,
        Width = 0,
        Height = 0,
        Showing = false,
        Event = "",
        Func = nil,
        FontString = nil,
        Type = type
    }

    function frame:SetSize(width, height)
        self.Width = width
        self.Height = height
    end

    function frame:SetScript(event, func)
        self.Event = event
        self.Func = func
    end

    function frame:Show()
        self.Showing = true
    end

    function frame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
        self.point = point
        self.relativeTo = relativeTo
        self.relativePoint = relativePoint
        self.xOfs = xOfs
        self.yOfs = yOfs
    end

    function frame:CreateFontString(name, layer, font)
        name = UpdateName(name, self.Name)

        if localFontStrings[name] ~= nil then
            return localFontStrings[name]
        end

        local fontString = {
            Name = name,
            Layer = layer,
            Font = font,
            myString = ""
        }

        function fontString:GetName()
            self.Name = name
        end

        function fontString:GetText()
            return self.myString
        end

        function fontString:SetText(str)
            self.myString = str
        end

        function fontString:SetTextColor(r, g, b, a)
            self.r = r
            self.g = g
            self.b = b
            self.a = a
        end

        function fontString:GetTextColor()
            return self.r, self.g, self.b, self.a
        end

        function fontString:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
            self.point = point
            self.relativeTo = relativeTo
            self.relativePoint = relativePoint
            self.xOfs = xOfs
            self.yOfs = yOfs
        end

        function fontString:GetPoint(self)
            return self.point, self.relativeTo, self.relativePoint, self.xOfs, self.yOfs
        end

        localFontStrings[name] = fontString
        return fontString
    end

    function frame:SetFontString(fontString)
        self.FontString = fontString
    end

    function frame:GetFontString()
        return self.FontString
    end

    function frame:SetText(str)
        self.Text = str
    end

    function frame:GetText()
        return self.Text
    end

    localFrames[name] = frame
    return frame
end

function eDungeonFilter.GetFrame(name)
    return localFrames[name]
end

if DungeonFilterRate == nil then
    DungeonFilterRate = eDungeonFilter.CreateFrame("Frame", "DungeonFilterRate");
end
