require "lunit"
require "test-setup"
require "DungeonFilter"

module("test", package.seeall, lunit.testcase)

-- function test_success()
--     assert_true( true, "This test never fails.")
-- end

-- function test_failure()
--     assert_true( "Hello World!", "This test always fails!")
-- end

function xtest_OnMythicStart_CurrentPartyShouldNotBeNil()
    -- Arrange
    eDungeonFilter.GetParty = function()
        local result = {}
        table.insert(result, {Name = "Saith"})
        table.insert(result, {Name = "Targether-Anub"})
        table.insert(result, {Name = "Hatis-Stormscale"})
        table.insert(result, {Name = "Disc-Stormscale"})

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
    assert_true(#eDungeonFilterPartyTemp.Players == 4, "Should be party of 4")
    assert_true(eDungeonFilterPartyTemp.Level == 20)
    assert_true(eDungeonFilterPartyTemp.DungeonName == "Waycrest Manor")
end

function xtest_OnGameLog_WasNotPreviousInMythicPlus_CurrentPartyShouldBeNil()
    -- Arrange
    eDungeonFilter.GetParty = function()
        local result = {}
        table.insert(result, {Name = "Saith"})
        table.insert(result, {Name = "Targether-Anub"})
        table.insert(result, {Name = "Hatis-Stormscale"})
        table.insert(result, {Name = "Disc-Stormscale"})

        return result
    end

    C_ChallengeMode.IsChallengeModeActive = function()
        return false
    end

    -- Act
    eDungeonFilter.AddOnLoaded()

    -- Assert
    assert_true(eDungeonFilterPartyTemp == nil)
end

function xtest_OnGameLog_IsInMythicPlus_ShouldSetCurrentGroup()
    -- Arrange
    eDungeonFilterPartyTemp = {
        Players = {},
        Level = 20,
        DungeonName = "Waycrest Manor"
    }

    table.insert(eDungeonFilterPartyTemp.Players, "Saith")
    table.insert(eDungeonFilterPartyTemp.Players, "Targether-Anub")
    table.insert(eDungeonFilterPartyTemp.Players, "Hatis-Stormscale")
    table.insert(eDungeonFilterPartyTemp.Players, "Disc-Stormscale")

    eDungeonFilter.GetParty = function()
        local result = {}
        table.insert(result, "Saith 2")
        table.insert(result, "Targether-Anub 2")
        table.insert(result, "Hatis-Stormscale 2")
        table.insert(result, "Disc-Stormscale 2")

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
    eDungeonFilter.AddOnLoaded()

    -- Assert
    assert_true(#eDungeonFilterPartyTemp.Players == 4, "Should be 4 players")
    assert_true(eDungeonFilterPartyTemp.Players[1] == "Saith")
    assert_true(eDungeonFilterPartyTemp.Players[2] == "Targether-Anub")
end

function test_OnChallengeModeCompleted_ShouldShowRateModal_UpdatedFontStringNames()
    -- Arrange

    eDungeonFilterPartyTemp = {
        Players = {},
        Level = 20,
        DungeonName = "Waycrest Manor"
    }

    table.insert(eDungeonFilterPartyTemp.Players, "Saith")
    table.insert(eDungeonFilterPartyTemp.Players, "Targether-Anub")
    table.insert(eDungeonFilterPartyTemp.Players, "Hatis-Stormscale")
    table.insert(eDungeonFilterPartyTemp.Players, "Disc-Stormscale")

    DungeonFilterRate.Showing = false
    function DungeonFilterRate:Show()
        DungeonFilterRate.Showing = true
    end

    C_ChallengeMode.IsChallengeModeActive = function()
        return false
    end

    eDungeonFilter.GetCachedParty = function()
        return eDungeonFilterPartyTemp
    end

    -- Act
    eDungeonFilter.OnChallengeModeComplete()

    -- Assert
    assert_true(DungeonFilterRate.Showing == true)
    assert_true(eDungeonFilter.GetFontString("DungeonFilterRate_FontString1"):GetText() == "Saith")
    assert_true(_G["DungeonFilterRate_FontString2"]:GetText() == "Targether-Anub")
    assert_true(_G["DungeonFilterRate_FontString3"]:GetText() == "Hatis-Stormscale")
    assert_true(_G["DungeonFilterRate_FontString4"]:GetText() == "Disc-Stormscale")

    -- assert_true(_G["DungeonFilterRate_EditBox_1"]:GetText() == "")
    -- assert_true(_G["DungeonFilterRate_EditBox_2"]:GetText() == "")
    -- assert_true(_G["DungeonFilterRate_EditBox_3"]:GetText() == "")
    -- assert_true(_G["DungeonFilterRate_EditBox_4"]:GetText() == "")

    -- assert_true(_G["DungeonFilterRate_Party1_Button1_Button"]:GetFontString():GetTextColor() == "")
end

function xtest_PartyMemberLeaves_InMythicPlus_ShouldShowRateModal()
    -- Arrange

    eDungeonFilter.GetParty = function()
        local result = {}
        table.insert(result, {Name = "Saith"})
        table.insert(result, {Name = "Targether-Anub"})
        table.insert(result, {Name = "Hatis-Stormscale"})
        table.insert(result, {Name = "Disc-Stormscale"})

        return result
    end

    eDungeonFilter.IsInMythicPlus = function()
        return true
    end

    eDungeonFilter.SetParty()

    eDungeonFilter.Showing = false
    eDungeonFilter.Show = function()
        eDungeonFilter.Showing = true
    end

    -- Act
    eDungeonFilter.OnGroupRosterUpdate()

    -- Assert
    assert_true(eDungeonFilter.Showing == true)
    assert_true(eDungeonFilter == nil)
end

function xtest_PartyMemberLeaves_NotInMythicPlus_ShouldNotShowRateModal()
    -- Arrange

    eDungeonFilter.GetParty = function()
        local result = {}
        table.insert(result, {Name = "Saith"})
        table.insert(result, {Name = "Targether-Anub"})
        table.insert(result, {Name = "Hatis-Stormscale"})
        table.insert(result, {Name = "Disc-Stormscale"})

        return result
    end

    eDungeonFilter.IsInMythicPlus = function()
        return false
    end

    eDungeonFilter.SetParty()

    eDungeonFilter.Showing = false
    eDungeonFilter.Show = function()
        eDungeonFilter.Showing = true
    end

    -- Act
    eDungeonFilter.OnGroupRosterUpdate()

    -- Assert
    assert_true(eDungeonFilter.Showing == false)
    assert_true(eDungeonFilter.CurrentParty == nil)
end

lunit.main(...) -- required.
