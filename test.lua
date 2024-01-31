require "lunit"
require "test-setup"
require "DungeonFilter"

module("test", package.seeall, lunit.testcase )

-- function test_success()
--     assert_true( true, "This test never fails.")
-- end
  
-- function test_failure()
--     assert_true( "Hello World!", "This test always fails!")
-- end



function test_OnMythicStart_GetCurrentParty()
    -- Arrange
    eDungeonFilter.GetParty = function()
        local result = {}
        table.insert(result, { Name = "Saith" })
        table.insert(result, { Name = "Targether-Anub" })
        table.insert(result, { Name = "Hatis-Stormscale" })
        table.insert(result, { Name = "Disc-Stormscale" })

        return result
    end

    eDungeonFilter.IsInMythicPlus = function()
        return true;
    end 

    -- Act
    eDungeonFilter.SetCurrentParty()
    
    -- Assert
    assert_true(#eDungeonFilter.CurrentParty == 4, "Should be party of 4")
end

function test_OnGameLog_IsNotInMythicPlus_ShouldNilCurrentGroup()
     -- Arrange
     
     eDungeonFilter.GetParty = function()
        local result = {}
        table.insert(result, { Name = "Saith" })
        table.insert(result, { Name = "Targether-Anub" })
        table.insert(result, { Name = "Hatis-Stormscale" })
        table.insert(result, { Name = "Disc-Stormscale" })

        return result
    end
    
    eDungeonFilter.IsInMythicPlus = function()
        return false;
    end 

    -- Act
    eDungeonFilter.SetCurrentParty()
    
    -- Assert
    assert_true(eDungeonFilter.CurrentParty == nil)
end

function test_OnGameLog_IsInMythicPlus_ShouldSetCurrentGroup()
    -- Arrange
    
    eDungeonFilter.GetParty = function()
       local result = {}
       table.insert(result, { Name = "Saith" })
       table.insert(result, { Name = "Targether-Anub" })
       table.insert(result, { Name = "Hatis-Stormscale" })
       table.insert(result, { Name = "Disc-Stormscale" })

       return result
   end
   
   eDungeonFilter.IsInMythicPlus = function()
       return true;
   end 

   -- Act
   eDungeonFilter.SetCurrentParty()
   
   -- Assert
   assert_true(#eDungeonFilter.CurrentParty == 4, "Should be party of 4")
end

function test_OnMythicEnd_ShouldShowRateModal()
    -- Arrange
    
    eDungeonFilter.GetParty = function()
       local result = {}
       table.insert(result, { Name = "Saith" })
       table.insert(result, { Name = "Targether-Anub" })
       table.insert(result, { Name = "Hatis-Stormscale" })
       table.insert(result, { Name = "Disc-Stormscale" })

       return result
   end
   
   eDungeonFilter.IsInMythicPlus = function()
       return true;
   end 
   
   eDungeonFilter.SetCurrentParty()

   eDungeonFilter.Showing = false;
   eDungeonFilter.Show = function()
    eDungeonFilter.Showing = true;
   end

   -- Act
   eDungeonFilter.RatePlayers()

   -- Assert
   assert_true(eDungeonFilter.Showing == true)
end

function test_PartyMemberLeaves_InMythicPlus_ShouldShowRateModal()
    -- Arrange
    
    eDungeonFilter.GetParty = function()
       local result = {}
       table.insert(result, { Name = "Saith" })
       table.insert(result, { Name = "Targether-Anub" })
       table.insert(result, { Name = "Hatis-Stormscale" })
       table.insert(result, { Name = "Disc-Stormscale" })

       return result
   end
   
   eDungeonFilter.IsInMythicPlus = function()
       return true;
   end 
   
   eDungeonFilter.SetCurrentParty()

   eDungeonFilter.Showing = false;
   eDungeonFilter.Show = function()
    eDungeonFilter.Showing = true;
   end

   -- Act
   eDungeonFilter.OnGroupRosterUpdate()

   -- Assert
   assert_true(eDungeonFilter.Showing == true)
   assert_true(eDungeonFilter.CurrentParty == nil)
end

function test_PartyMemberLeaves_NotInMythicPlus_ShouldNotShowRateModal()
    -- Arrange
    
    eDungeonFilter.GetParty = function()
       local result = {}
       table.insert(result, { Name = "Saith" })
       table.insert(result, { Name = "Targether-Anub" })
       table.insert(result, { Name = "Hatis-Stormscale" })
       table.insert(result, { Name = "Disc-Stormscale" })

       return result
   end
   
   eDungeonFilter.IsInMythicPlus = function()
       return false;
   end 
   
   eDungeonFilter.SetCurrentParty()

   eDungeonFilter.Showing = false;
   eDungeonFilter.Show = function()
    eDungeonFilter.Showing = true;
   end

   -- Act
   eDungeonFilter.OnGroupRosterUpdate()

   -- Assert
   assert_true(eDungeonFilter.Showing == false)
   assert_true(eDungeonFilter.CurrentParty == nil)
end

lunit.main(...)  -- required.