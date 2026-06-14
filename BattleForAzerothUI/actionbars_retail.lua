-- BattleForAzerothUI/actionbars_retail.lua
-- Main action bar, MultiBar, pet bar, and stance bar positioning + BfA art.
-- Modern retail / Midnight only (WOW_PROJECT_MAINLINE, interface 120005).
-- The TBC Anniversary 20505 path is actionbars_anniversary.lua.
-- Depends on ActionBarArt / ActionBarArtSmall defined in artFrames.xml.
-- Depends on BFAUI_SetBarWidth defined in xpbar_retail.lua.
--
-- Midnight rebuilt the action bar system. Verified on a live 120005 client:
--   * main bar       = MainActionBar (UIParent child, Edit Mode system 0)
--   * buttons        = MainActionBar > MainActionBarButtonContainer1..12 > ActionButton1..12
--   * MultiBars       = MultiBar*  > MultiBar*ButtonContainer1..12 > buttons
--   * gryphons       = MainActionBar.EndCaps.LeftEndCap / .RightEndCap (Textures)
--   * default bar art = MainActionBar.BorderArt (Texture, atlas UI-HUD-ActionBar-Frame)
--   * positioning     = governed by Edit Mode; we force the BfA layout (user choice).
-- The legacy MainMenuBar / MainMenuBar*EndCap / MainMenuBarPerformanceBar globals
-- do NOT exist on Midnight, which is why the old retail code (now _anniversary.lua)
-- could not run here.
if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

local MainBar = MainActionBar
if not MainBar then return end -- defensive: Midnight UI not as expected

local isUpdating = false

-- Reparent the BfA art overlays onto the Midnight main bar so they track it.
-- artFrames.xml declares parent="MainMenuBar" which is nil on Midnight, so the
-- frames were created effectively parentless; re-home them here.
if ActionBarArt then ActionBarArt:SetParent(MainBar) end
if ActionBarArtSmall then ActionBarArtSmall:SetParent(MainBar) end

-- Hide the default Blizzard bar frame art so the BfA art replaces it.
local function HideDefaultBarArt()
    if MainBar.BorderArt then
        MainBar.BorderArt:SetAlpha(0)
        MainBar.BorderArt:Hide()
    end
end

-- Gryphons / end caps. On Midnight these are textures inside MainActionBar.EndCaps.
local function ApplyGryphons(art, leftX, rightX)
    local caps = MainBar.EndCaps
    if not caps then return end
    local L, R = caps.LeftEndCap, caps.RightEndCap
    local hide = BFAUI_SavedVars and BFAUI_SavedVars.Options and BFAUI_SavedVars.Options.HideGryphons
    if hide then
        if L then L:Hide() end
        if R then R:Hide() end
        return
    end
    -- Show the gryphons at the ends of our BfA art overlay.
    if art and L then
        L:ClearAllPoints()
        L:SetPoint("LEFT", art, "LEFT", leftX, 0)
        L:Show()
    end
    if art and R then
        R:ClearAllPoints()
        R:SetPoint("RIGHT", art, "RIGHT", rightX, 0)
        R:Show()
    end
end

local function ActivateLongBar()
    if InCombatLockdown() then return end

    if ActionBarArt then ActionBarArt:Show() end
    if ActionBarArtSmall then ActionBarArtSmall:Hide() end
    HideDefaultBarArt()
    ApplyGryphons(ActionBarArt, 12, -12)

    MainBar:ClearAllPoints()
    MainBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 110, 11)

    if MultiBarBottomLeft then
        MultiBarBottomLeft:ClearAllPoints()
        MultiBarBottomLeft:SetPoint("BOTTOMLEFT", MainBar, "TOPLEFT", 8, 0)
    end

    if MultiBarBottomRight then
        MultiBarBottomRight:ClearAllPoints()
        MultiBarBottomRight:SetPoint("TOPLEFT", MultiBarBottomLeft or MainBar, "TOPRIGHT", 43, 0)
    end

    -- Wrap MultiBarBottomRight's 12-button single row into a 2x6 block by
    -- stacking containers 7..12 beneath 1..6 (containers exist on Midnight).
    for i = 1, 6 do
        local lower = _G["MultiBarBottomRightButtonContainer" .. (i + 6)]
        local upper = _G["MultiBarBottomRightButtonContainer" .. i]
        if lower and upper then
            lower:ClearAllPoints()
            lower:SetPoint("TOPLEFT", upper, "BOTTOMLEFT", 0, -12)
        end
    end

    if BFAUI_SetBarWidth then BFAUI_SetBarWidth(798, -111) end
end

local function ActivateShortBar()
    if InCombatLockdown() then return end

    if ActionBarArt then ActionBarArt:Hide() end
    if ActionBarArtSmall then ActionBarArtSmall:Show() end
    HideDefaultBarArt()
    ApplyGryphons(ActionBarArtSmall, 12, -264)

    MainBar:ClearAllPoints()
    MainBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 237, 11)

    if MultiBarBottomLeft then
        MultiBarBottomLeft:ClearAllPoints()
        MultiBarBottomLeft:SetPoint("BOTTOMLEFT", MainBar, "TOPLEFT", 8, 0)
    end

    if BFAUI_SetBarWidth then BFAUI_SetBarWidth(542, -237) end
end

local function UpdateActionBars()
    if InCombatLockdown() or isUpdating then return end
    isUpdating = true

    local mbblShown = MultiBarBottomLeft and MultiBarBottomLeft:IsShown()
    local referenceBar = mbblShown and MultiBarBottomLeft or MainBar

    if PetActionBar then
        PetActionBar:ClearAllPoints()
        if referenceBar == MainBar then
            PetActionBar:SetPoint("BOTTOMLEFT", referenceBar, "TOPLEFT", 51, -2)
        else
            PetActionBar:SetPoint("BOTTOMLEFT", referenceBar, "TOPLEFT", 51, 3)
        end
    end

    if StanceBar then
        StanceBar:ClearAllPoints()
        if referenceBar == MainBar then
            StanceBar:SetPoint("BOTTOMLEFT", referenceBar, "TOPLEFT", 51, -2)
        else
            StanceBar:SetPoint("BOTTOMLEFT", referenceBar, "TOPLEFT", 51, 3)
        end
    end

    if MultiBarBottomRight and MultiBarBottomRight:IsShown() then
        ActivateLongBar()
    else
        ActivateShortBar()
    end

    isUpdating = false
end

-- Opt the managed bars out of the engine's automatic bottom-container layout so
-- our forced BfA positions are not reset on bar visibility changes / combat.
for _, b in ipairs({ MainBar, MultiBarBottomLeft, MultiBarBottomRight }) do
    if b then b.skipAutomaticPositioning = true end
end

-- Reapply our layout whenever Edit Mode or the engine moves a managed bar.
for _, b in ipairs({ MainBar, MultiBarBottomLeft, MultiBarBottomRight, PetActionBar, StanceBar }) do
    if b and b.SetPoint then hooksecurefunc(b, "SetPoint", UpdateActionBars) end
end

local BFA_Manager = CreateFrame("Frame")
BFA_Manager:RegisterEvent("PLAYER_LOGIN")
BFA_Manager:RegisterEvent("PLAYER_ENTERING_WORLD")
BFA_Manager:RegisterEvent("PLAYER_REGEN_ENABLED")    -- reapply after combat
BFA_Manager:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
BFA_Manager:SetScript("OnEvent", function()
    -- Defer past Edit Mode's synchronous handlers / protected exit context.
    C_Timer.After(0, UpdateActionBars)
end)

if MultiBarBottomLeft then
    MultiBarBottomLeft:HookScript("OnShow", UpdateActionBars)
    MultiBarBottomLeft:HookScript("OnHide", UpdateActionBars)
end
if MultiBarBottomRight then
    MultiBarBottomRight:HookScript("OnShow", UpdateActionBars)
    MultiBarBottomRight:HookScript("OnHide", UpdateActionBars)
end
