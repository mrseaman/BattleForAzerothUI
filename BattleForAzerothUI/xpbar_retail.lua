-- BattleForAzerothUI/xpbar_retail.lua
-- XP bar and reputation bar: positioning, display logic, and text overlays.
-- Retail engine clients only. Not loaded on Classic Era.
-- Depends on XPBarBackground defined in artFrames.xml.
if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then return end

local isUpdating = false 

local function FinalStatusFix()
    if isUpdating or InCombatLockdown() then return end
    if not StatusTrackingBarManager then return end

    isUpdating = true 

    -- 1. Position the Master Manager
    StatusTrackingBarManager:ClearAllPoints()
    StatusTrackingBarManager:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 11)
    StatusTrackingBarManager:SetSize(798, 20)

    -- 2. Target the Specific Containers from your fstack
    local containers = {
        StatusTrackingBarManager.MainStatusTrackingBarContainer,
        StatusTrackingBarManager.SecondaryStatusTrackingBarContainer
    }

    for i, container in ipairs(containers) do
        if container and container:IsShown() then
            -- Force the container to have physical dimensions
            container:ClearAllPoints()
            container:SetPoint("BOTTOM", StatusTrackingBarManager, "BOTTOM", 0, (i-1)*10)
            container:SetSize(798, 10)
            container:SetAlpha(1)

            -- 3. The "Hex-ID" Fix: Loop through every child in the container
            -- This catches the MainStatusTrackingBarContainer.86f67cab0 frame
            local children = {container:GetChildren()}
            for _, child in ipairs(children) do
                child:ClearAllPoints()
                child:SetAllPoints(container)
                child:SetAlpha(1)
                child:Show()

                -- Force the Actual StatusBar inside the Hex-ID frame
                if child.StatusBar then
                    child.StatusBar:ClearAllPoints()
                    child.StatusBar:SetAllPoints(child)
                    child.StatusBar:SetAlpha(1)
                    
                    -- Retail bars often have "Art" overlays that block the view
                    if child.OverlayFrame then child.OverlayFrame:Hide() end
                end
            end

            -- 4. Hide the Blizzard 'MainMenuBar' background textures
            for _, region in pairs({container:GetRegions()}) do
                if region:IsObjectType("Texture") then
                    region:SetAlpha(0)
                end
            end
        end
    end

    isUpdating = false 
end

-- Hook the Retail manager's update cycle
if StatusTrackingBarManager then
    -- This is the function Bartender4 uses to trigger updates
    hooksecurefunc(StatusTrackingBarManager, "UpdateBarsShown", function()
        if not isUpdating then
            FinalStatusFix()
        end
    end)
    
    -- Also hook SetPoint to prevent the manager from snapping back to MainMenuBar
    hooksecurefunc(StatusTrackingBarManager, "SetPoint", function()
        if not isUpdating then
            FinalStatusFix()
        end
    end)
end

-- Ensure it runs on login and when combat ends
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", FinalStatusFix)