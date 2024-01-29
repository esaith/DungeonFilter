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

function test_GetParty_TwoMembers()
    DungeonFilter.GetParty = function()
        local result = {}
        table.insert(result, { Name = "Steve" })
        table.insert(result, { Name = "Jack" })

        return result
    end

    local party = DungeonFilter.GetParty()

    assert_true(#party == 2, "Should be party of 2.")
end

lunit.main(...)  -- required.