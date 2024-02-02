---@diagnostic disable: lowercase-global, duplicate-set-field, undefined-global
require "lunit"
require "blizzard-globals"
require "DungeonFilter"
require "test-setup"

module("test", package.seeall, lunit.testcase)

-- function test_success()
--     assert_true( true, "This test never fails.")
-- end

-- function test_failure()
--     assert_true( "Hello World!", "This test always fails!")
-- end

function test_OnMythicStart_CurrentPartyShouldNotBeNil()
    -- Arrange
    eDungeonFilter.GetParty = function()
        local result = {}
        table.insert(result, { Name = "Saith" })
        table.insert(result, { Name = "Targether-Anub" })
        table.insert(result, { Name = "Hatis-Stormscale" })
        table.insert(result, { Name = "Disc-Stormscale" })

        return result
    end

    C_ChallengeMode.IsChallengeModeActive = function()
        return true
    end

    eDungeonFilter.GetInstanceInfo = function()
        return "Waycrest Manor"
    end

    eDungeonFilter.GetActiveKeystoneInfo = function()
        return 20
    end

    -- Act
    eDungeonFilter.OnChallengeModeStart()

    -- Assert
    local mythicParty = eDungeonFilter:GetMythicParty()
    assert_true(#mythicParty.Players == 4, "Should be party of 4")
    assert_true(mythicParty.Level == 20)
    assert_true(mythicParty.DungeonName == "Waycrest Manor")
end

function test_OnGameLog_WasNotPreviousInMythicPlus_CurrentPartyShouldBeNil()
    -- Arrange
    eDungeonFilter.GetParty = function()
        local result = {}
        table.insert(result, { Name = "Saith" })
        table.insert(result, { Name = "Targether-Anub" })
        table.insert(result, { Name = "Hatis-Stormscale" })
        table.insert(result, { Name = "Disc-Stormscale" })

        return result
    end

    C_ChallengeMode.IsChallengeModeActive = function()
        return false
    end

    -- Act
    eDungeonFilter.AddOnLoaded()

    -- Assert
    assert_true(eDungeonFilter:GetMythicParty() == nil)
end

function test_OnGameLog_IsInMythicPlus_ShouldSetCurrentGroup()
    -- Arrange
    local mythicParty = {
        Players = {},
        Level = 20,
        DungeonName = "Waycrest Manor"
    }

    table.insert(mythicParty.Players, "Saith")
    table.insert(mythicParty.Players, "Targether-Anub")
    table.insert(mythicParty.Players, "Hatis-Stormscale")
    table.insert(mythicParty.Players, "Disc-Stormscale")

    eDungeonFilter:SetNewMythicParty(mythicParty)

    C_ChallengeMode.IsChallengeModeActive = function()
        return true
    end

    eDungeonFilter.GetInstanceInfo = function()
        return "Waycrest Manor"
    end

    eDungeonFilter.GetActiveKeystoneInfo = function()
        return 20
    end

    -- Act
    eDungeonFilter.AddOnLoaded()

    -- Assert
    local mythicParty = eDungeonFilter:GetMythicParty()
    assert_true(#mythicParty.Players == 4, "Should be 4 players")
    assert_true(mythicParty.Players[1] == "Saith")
    assert_true(mythicParty.Players[2] == "Targether-Anub")
end

function test_OnChallengeModeCompleted_ShouldShowRateModal_UpdatedFontStringNames()
    -- Arrange
    function C_ChallengeMode.IsChallengeModeActive()
        return false
    end

    eDungeonFilter.AddOnLoaded()

    local mythicParty = {
        Players = {},
        Level = 20,
        DungeonName = "Waycrest Manor"
    }

    table.insert(mythicParty.Players, "Saith")
    table.insert(mythicParty.Players, "Targether-Anub")
    table.insert(mythicParty.Players, "Hatis-Stormscale")
    table.insert(mythicParty.Players, "Disc-Stormscale")

    eDungeonFilter:SetNewMythicParty(mythicParty)

    DungeonFilterRate.Showing = false
    function DungeonFilterRate:Show()
        DungeonFilterRate.Showing = true
    end

    -- eDungeonFilter.PrintTable(eDungeonFilter)

    -- Act
    eDungeonFilter.OnChallengeModeComplete()

    -- Assert
    assert_true(DungeonFilterRate.Showing == true)

    local fontString = eDungeonFilter.GetFontString("DungeonFilterRate_FontString1")
    assert_true(fontString ~= nil)
    assert_true(fontString:GetText() == "Saith")

    fontString = eDungeonFilter.GetFontString("DungeonFilterRate_FontString2")
    assert_true(fontString ~= nil)
    assert_true(fontString:GetText() == "Targether-Anub")

    fontString = eDungeonFilter.GetFontString("DungeonFilterRate_FontString3")
    assert_true(fontString ~= nil)
    assert_true(fontString:GetText() == "Hatis-Stormscale")

    fontString = eDungeonFilter.GetFontString("DungeonFilterRate_FontString4")
    assert_true(fontString ~= nil)
    assert_true(fontString:GetText() == "Disc-Stormscale")

    local editBox = eDungeonFilter.GetFrame("DungeonFilterRate_EditBox_1")
    assert_true(editBox ~= nil)
    assert_true(editBox:GetText() == "")

    editBox = eDungeonFilter.GetFrame("DungeonFilterRate_EditBox_2")
    assert_true(editBox ~= nil)
    assert_true(editBox:GetText() == "")

    editBox = eDungeonFilter.GetFrame("DungeonFilterRate_EditBox_3")
    assert_true(editBox ~= nil)
    assert_true(editBox:GetText() == "")

    editBox = eDungeonFilter.GetFrame("DungeonFilterRate_EditBox_4")
    assert_true(editBox ~= nil)
    assert_true(editBox:GetText() == "")

    local row = 0
    local column = 0
    while row < 4 do
        row = row + 1
        column = 0

        while column < 4 do
            column = column + 1
            local button = eDungeonFilter.GetFrame("DungeonFilterRate_Party" .. row .. "_Button" .. column .. "_Button")
            assert_true(button ~= nil)

            local fontString = button:GetFontString()
            assert_true(fontString ~= nil)

            local r, g, b, a = fontString:GetTextColor()
            assert_true(r == 1)
            assert_true(g == 1)
            assert_true(b == 1)
            assert_true(a == nil)
        end
    end
end

function test_PartyMemberLeaves_InAnActiveMythicPlus_ShouldShowRateModal()
    -- Arrange
    local mythicParty = {
        Players = {},
        Level = 20,
        DungeonName = "Waycrest Manor"
    }

    table.insert(mythicParty.Players, "Saith")
    table.insert(mythicParty.Players, "Targether-Anub")
    table.insert(mythicParty.Players, "Hatis-Stormscale")
    table.insert(mythicParty.Players, "Disc-Stormscale")

    eDungeonFilter:SetNewMythicParty(mythicParty)

    eDungeonFilter.Showing = false
    eDungeonFilter.Show = function()
        eDungeonFilter.Showing = true
    end

    function C_ChallengeMode.IsChallengeModeActive()
        return true
    end

    -- Act
    eDungeonFilter.OnGroupRosterUpdate()

    -- Assert
    assert_true(DungeonFilterRate.Showing == true)

    local mythicParty = eDungeonFilter:GetMythicParty()
    assert_true(mythicParty ~= nil)
end

function test_PartyMemberLeaves_NotInMythicPlus_ShouldNotShowRateModal()
    -- Arrange
    local mythicParty = {
        Players = {},
        Level = 20,
        DungeonName = "Waycrest Manor"
    }

    table.insert(mythicParty.Players, "Saith")
    table.insert(mythicParty.Players, "Targether-Anub")
    table.insert(mythicParty.Players, "Hatis-Stormscale")
    table.insert(mythicParty.Players, "Disc-Stormscale")

    eDungeonFilter:SetNewMythicParty(mythicParty)

    eDungeonFilter.Showing = false
    eDungeonFilter.Show = function()
        eDungeonFilter.Showing = true
    end

    function C_ChallengeMode.IsChallengeModeActive()
        return true
    end

    -- Act
    eDungeonFilter.OnGroupRosterUpdate()

    -- Assert
    assert_true(DungeonFilterRate.Showing == true)

    local mythicParty = eDungeonFilter:GetMythicParty()
    assert_true(mythicParty ~= nil)
end

lunit.main(...) -- required.
