-- BattleForAzerothUI/actionbars_retail.lua
-- Main action bar, MultiBarBottomLeft/Right, pet bar, and stance bar positioning.
-- Retail engine clients only. Not loaded on Classic Era.
-- Depends on ActionBarArt / ActionBarArtSmall defined in artFrames.xml.
-- Depends on BFAUI_SetBarWidth defined in xpbar_retail.lua.
if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then return end

local BFA_Manager = CreateFrame("Frame")
BFA_Manager:RegisterEvent("PLAYER_LOGIN")
BFA_Manager:RegisterEvent("PLAYER_ENTERING_WORLD")
BFA_Manager:RegisterEvent("PLAYER_REGEN_ENABLED") -- To apply changes after combat ends
BFA_Manager:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED") -- Core event for Retail positioning

local isUpdating = false -- Flag to prevent infinite loops during hooks

local function ActivateLongBar()
    if InCombatLockdown() then return end
    
    ActionBarArt:Show()
    ActionBarArtSmall:Hide()

    if not BFAUI_SavedVars.Options.HideGryphons or (MainMenuBarLeftEndCap:IsShown() or MainMenuBarRightEndCap:IsShown()) then
        MainMenuBarLeftEndCap:ClearAllPoints()
        MainMenuBarLeftEndCap:SetPoint("LEFT", ActionBarArt, "LEFT", 12, 0)
        MainMenuBarRightEndCap:ClearAllPoints()
        MainMenuBarRightEndCap:SetPoint("RIGHT", ActionBarArt, "RIGHT", -12, 0)
    else
        MainMenuBarLeftEndCap:Hide()
        MainMenuBarRightEndCap:Hide()
    end

    MainMenuBar:ClearAllPoints()
    MainMenuBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 110, 11)

    MultiBarBottomLeft:ClearAllPoints()
    MultiBarBottomLeft:SetPoint("BOTTOMLEFT", MainMenuBar, "TOPLEFT", 8, 0)

    MultiBarBottomRight:ClearAllPoints()
    MultiBarBottomRight:SetPoint("TOPLEFT", MultiBarBottomLeft, "TOPRIGHT", 43, 0)

    for i = 1, 6 do
        local buttonContainer = _G["MultiBarBottomRightButtonContainer"..i+6]
        if buttonContainer then
            buttonContainer:ClearAllPoints()
            buttonContainer:SetPoint("TOPLEFT", _G["MultiBarBottomRightButtonContainer"..i], "BOTTOMLEFT", 0, -12)
        end
    end

    if BFAUI_SetBarWidth then BFAUI_SetBarWidth(798, -111) end
end

local function ActivateShortBar()
    if InCombatLockdown() then return end

    ActionBarArt:Hide()
    ActionBarArtSmall:Show()

    if not BFAUI_SavedVars.Options.HideGryphons or (MainMenuBarLeftEndCap:IsShown() or MainMenuBarRightEndCap:IsShown()) then
        MainMenuBarLeftEndCap:ClearAllPoints()
        MainMenuBarLeftEndCap:SetPoint("LEFT", ActionBarArt, "LEFT", 12, 0)
        MainMenuBarRightEndCap:ClearAllPoints()
        MainMenuBarRightEndCap:SetPoint("RIGHT", ActionBarArt, "RIGHT", -264, 0)
    else
        MainMenuBarLeftEndCap:Hide()
        MainMenuBarRightEndCap:Hide()
    end

    MainMenuBar:ClearAllPoints()
    MainMenuBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 237, 11)

    MultiBarBottomLeft:ClearAllPoints()
    MultiBarBottomLeft:SetPoint("BOTTOMLEFT", MainMenuBar, "TOPLEFT", 8, 0)

    if BFAUI_SetBarWidth then BFAUI_SetBarWidth(542, -237) end
end

local function UpdateActionBars()
    if InCombatLockdown() or isUpdating then return end
    isUpdating = true -- Start protection

    local referenceBar = MultiBarBottomLeft:IsShown() and MultiBarBottomLeft or MainMenuBar

    if PetActionBar then
        PetActionBar:ClearAllPoints()
        if referenceBar == MainMenuBar then
            PetActionBar:SetPoint("BOTTOMLEFT", referenceBar, "TOPLEFT", 51, -2)
        else
            -- MultiBarBottomLeft is shown; keep PetActionBar above it.
            -- Must always set a point after ClearAllPoints — leaving PetActionBar
            -- unanchored causes EditModeUtil to call abs(nil) on its position.
            PetActionBar:SetPoint("BOTTOMLEFT", referenceBar, "TOPLEFT", 51, 3)
        end
    end

    if StanceBar then
        StanceBar:ClearAllPoints()
        if referenceBar == MainMenuBar then
            StanceBar:SetPoint("BOTTOMLEFT", referenceBar, "TOPLEFT", 51, -2)
        else
            StanceBar:SetPoint("BOTTOMLEFT", referenceBar, "TOPLEFT", 51, 3)        
        end
    end

    if MultiBarBottomRight:IsShown() then
        ActivateLongBar()
    else
        ActivateShortBar()
    end

    isUpdating = false -- End protection
end

-- Opt out of UIParentManageBottomFrameContainer automatic repositioning.
-- Without this flag, the game resets each bar's anchor to UIParent during combat
-- (triggered by any bar visibility change), overriding our layout. PetActionBar
-- already carries this flag from the game; we set it on the bars we manage.
MainMenuBar.skipAutomaticPositioning = true
MultiBarBottomLeft.skipAutomaticPositioning = true
MultiBarBottomRight.skipAutomaticPositioning = true

-- Hook SetPoint on each managed bar so our layout is reapplied whenever the
-- game or Edit Mode moves them outside of combat.
hooksecurefunc(MainMenuBar, "SetPoint", UpdateActionBars)
hooksecurefunc(MultiBarBottomLeft, "SetPoint", UpdateActionBars)
hooksecurefunc(MultiBarBottomRight, "SetPoint", UpdateActionBars)
hooksecurefunc(PetActionBar, "SetPoint", UpdateActionBars)
hooksecurefunc(StanceBar, "SetPoint", UpdateActionBars)



-- Event Handling
BFA_Manager:SetScript("OnEvent", function(self, event, ...)
    UpdateActionBars()
end)

-- Keep your existing hooks for visibility changes
MultiBarBottomLeft:HookScript("OnShow", UpdateActionBars)
MultiBarBottomLeft:HookScript("OnHide", UpdateActionBars)
MultiBarBottomRight:HookScript("OnShow", UpdateActionBars)
MultiBarBottomRight:HookScript("OnHide", UpdateActionBars)