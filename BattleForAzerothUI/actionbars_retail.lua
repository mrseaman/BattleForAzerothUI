-- BattleForAzerothUI/actionbars_retail.lua
-- Main action bar, MultiBar, pet bar, and stance bar positioning + BfA art.
-- Modern retail / Midnight only (WOW_PROJECT_MAINLINE, interface 120005).

if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

local isUpdating = false

local function HalfRow()
    local b1, b12 = ActionButton1, ActionButton12
    local l = b1 and b1:GetLeft()
    local r = b12 and b12:GetRight()
    if l and r then return (r - l) / 2 end
    return 281
end


local LONG_BAR_X_SHIFT = 164
local BAR2_X_OFFSET = 0
local BAR2_Y_OFFSET = 14

if ActionBarArt then ActionBarArt:SetParent(UIParent); ActionBarArt:SetFrameStrata("LOW") end
if ActionBarArtSmall then ActionBarArtSmall:SetParent(UIParent); ActionBarArtSmall:SetFrameStrata("LOW") end

local function HideDefaultBarArt()
    if MainActionBar.BorderArt then
        MainActionBar.BorderArt:SetAlpha(0)
        MainActionBar.BorderArt:Hide()
    end
end

local GRYPHON_OVERLAP = 6
local function ApplyGryphons()
    local caps = MainActionBar.EndCaps
    if not caps then return end
    local L, R = caps.LeftEndCap, caps.RightEndCap
    local hide = BFAUI_SavedVars and BFAUI_SavedVars.Options and BFAUI_SavedVars.Options.HideGryphons
    if hide then
        if L then L:Hide() end
        if R then R:Hide() end
        return
    end
    if L and ActionButton1 then
        L:ClearAllPoints()
        L:SetPoint("RIGHT", ActionButton1, "LEFT", GRYPHON_OVERLAP, 0)
        L:Show()
    end
    if R and ActionButton12 then
        R:ClearAllPoints()
        R:SetPoint("LEFT", ActionButton12, "RIGHT", -GRYPHON_OVERLAP, 0)
        R:Show()
    end
end

-- The BfA art (1024x128 base) was drawn for a slightly narrower bar than Midnight's
-- 562px 12-button row, so the outer buttons overhang the plate. Nudge the art up a
-- touch to cover them. Tunable: raise if buttons still overhang, lower if too big.
local ART_BASE_W, ART_BASE_H = 1024, 128
local ART_SCALE = 1.12
-- Per-mode X offset of the art plate (the two textures center differently). Positive = right.
local ART_X_OFFSET_LONG = LONG_BAR_X_SHIFT
local ART_X_OFFSET_SHORT = 20
local ART_Y_OFFSET = -14

local function SizeArt(art)
    if art then art:SetSize(ART_BASE_W * ART_SCALE, ART_BASE_H * ART_SCALE) end
end

local function ActivateLongBar()
    if InCombatLockdown() then return end

    local half = HalfRow()
    if ActionBarArt then
        ActionBarArt:Show()
        SizeArt(ActionBarArt)
        ActionBarArt:ClearAllPoints()
        ActionBarArt:SetPoint("BOTTOM", ActionButton1, "BOTTOMLEFT", half + ART_X_OFFSET_LONG, ART_Y_OFFSET)
    end
    if ActionBarArtSmall then ActionBarArtSmall:Hide() end
    HideDefaultBarArt()
    ApplyGryphons()

    MainActionBar:ClearAllPoints()
    MainActionBar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", -half - LONG_BAR_X_SHIFT, 11)

    MultiBarBottomLeft:ClearAllPoints()
    MultiBarBottomLeft:SetPoint("BOTTOMLEFT", MainActionBar, "TOPLEFT", BAR2_X_OFFSET, BAR2_Y_OFFSET)

    MultiBarBottomRight:ClearAllPoints()
    MultiBarBottomRight:SetPoint("BOTTOMLEFT", MultiBarBottomLeft, "BOTTOMRIGHT", 48, 0)

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

    local half = HalfRow()
    if ActionBarArt then ActionBarArt:Hide() end
    if ActionBarArtSmall then
        ActionBarArtSmall:Show()
        SizeArt(ActionBarArtSmall)
        ActionBarArtSmall:ClearAllPoints()
        ActionBarArtSmall:SetPoint("BOTTOM", ActionButton1, "BOTTOMLEFT", half + ART_X_OFFSET_SHORT, ART_Y_OFFSET)
    end
    HideDefaultBarArt()
    ApplyGryphons()

    MainActionBar:ClearAllPoints()
    MainActionBar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", -half, 11)

    if MultiBarBottomLeft then
        MultiBarBottomLeft:ClearAllPoints()
        MultiBarBottomLeft:SetPoint("BOTTOMLEFT", MainActionBar, "TOPLEFT", BAR2_X_OFFSET, BAR2_Y_OFFSET)
    end

    if BFAUI_SetBarWidth then BFAUI_SetBarWidth(542, -237) end
end

-- Midnight draws a dark slot square (UI-HUD-ActionBar-IconFrame-Slot, the button's
-- .SlotArt) behind every action icon, on top of our BfA art. Hide it on the bars the
-- art backs to restore the flat classic look; the button border is a separate
-- UI-HUD-ActionBar-IconFrame overlay and is left intact. Buttons re-show these on
-- update, so hook Show->Hide once per texture.
local function KillTexture(tex)
    if not tex then return end
    tex:SetAlpha(0)
    tex:Hide()
    if not tex.__bfaHidden then
        tex.__bfaHidden = true
        hooksecurefunc(tex, "Show", function(self) self:Hide() end)
        if tex.SetShown then
            hooksecurefunc(tex, "SetShown", function(self, shown) if shown then self:Hide() end end)
        end
    end
end

local function FlattenButtons()
    for _, prefix in ipairs({ "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton" }) do
        for i = 1, 12 do
            local btn = _G[prefix .. i]
            if btn then KillTexture(btn.SlotArt) end
        end
    end
end

-- Midnight puts the page number + up/down flip arrows on the LEFT of the bar, but
-- the BfA art reserves the RIGHT end for them (classic layout). ActionBarPageNumber
-- already bundles the number and both arrows as a vertical stack, so we just move the
-- whole frame to the right of the last button. Has its own re-entry guard because we
-- hook its SetPoint to reapply when Edit Mode moves it back.
local PAGE_NUMBER_X = 10
local repositioningPage = false
local function RepositionPageNumber()
    local pn = MainActionBar.ActionBarPageNumber
    if not pn or not ActionButton12 or repositioningPage then return end
    repositioningPage = true
    pn:ClearAllPoints()
    pn:SetPoint("LEFT", ActionButton12, "RIGHT", PAGE_NUMBER_X, 0)
    repositioningPage = false
end

local function UpdateActionBars()
    if InCombatLockdown() or isUpdating then return end
    isUpdating = true

    RepositionPageNumber()

    local referenceBar = MultiBarBottomLeft:IsShown() and MultiBarBottomLeft or MainActionBar

    if PetActionBar then
        PetActionBar:ClearAllPoints()
        if referenceBar == MainActionBar then
            PetActionBar:SetPoint("BOTTOMLEFT", referenceBar, "TOPLEFT", 51, 14)
        else
            PetActionBar:SetPoint("BOTTOMLEFT", referenceBar, "TOPLEFT", 51, 3)
        end
    end

    if StanceBar then
        StanceBar:ClearAllPoints()
        if referenceBar == MainActionBar then
            StanceBar:SetPoint("BOTTOMLEFT", referenceBar, "TOPLEFT", 51, 14)
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
for _, b in ipairs({ MainActionBar, MultiBarBottomLeft, MultiBarBottomRight }) do
    if b then b.skipAutomaticPositioning = true end
end

-- Reapply our layout whenever Edit Mode or the engine moves a managed bar.
for _, b in ipairs({ MainActionBar, MultiBarBottomLeft, MultiBarBottomRight, PetActionBar, StanceBar }) do
    if b and b.SetPoint then hooksecurefunc(b, "SetPoint", UpdateActionBars) end
end

-- Keep the page number / flip arrows pinned to the right when the engine moves them.
if MainActionBar.ActionBarPageNumber and MainActionBar.ActionBarPageNumber.SetPoint then
    hooksecurefunc(MainActionBar.ActionBarPageNumber, "SetPoint", function()
        if not repositioningPage then RepositionPageNumber() end
    end)
end

local BFA_Manager = CreateFrame("Frame")
BFA_Manager:RegisterEvent("PLAYER_LOGIN")
BFA_Manager:RegisterEvent("PLAYER_ENTERING_WORLD")
BFA_Manager:RegisterEvent("PLAYER_REGEN_ENABLED")    -- reapply after combat
BFA_Manager:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
BFA_Manager:SetScript("OnEvent", function()
    -- Defer past Edit Mode's synchronous handlers / protected exit context.
    C_Timer.After(0, function()
        UpdateActionBars()
        FlattenButtons()
    end)
end)

if MultiBarBottomLeft then
    MultiBarBottomLeft:HookScript("OnShow", UpdateActionBars)
    MultiBarBottomLeft:HookScript("OnHide", UpdateActionBars)
end
if MultiBarBottomRight then
    MultiBarBottomRight:HookScript("OnShow", UpdateActionBars)
    MultiBarBottomRight:HookScript("OnHide", UpdateActionBars)
end