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

-- Half-width of the 12-button main row (i.e. the button-row center measured from
-- ActionButton1's left). On Midnight MainActionBar is an asymmetric ~1547px frame
-- whose buttons sit at its LEFT edge, so anchoring the frame by BOTTOM (its center)
-- shoves the buttons far left. We anchor by BOTTOMLEFT and center art on the row
-- using this value, computed live so it survives UI-scale / resolution changes.
local function HalfRow()
    local b1, b12 = ActionButton1, ActionButton12
    local l = b1 and b1:GetLeft()
    local r = b12 and b12:GetRight()
    if l and r then return (r - l) / 2 end
    return 281
end

-- On Midnight, MainActionBar is an Edit Mode system frame (system 0) whose RENDER
-- position is locked by the engine: SetPoint on the frame updates its stored anchor
-- but the frame still draws at its Edit Mode slot (verified live -- shoving the anchor
-- 400px did not move the frame at all). So the row cannot be centered by moving the
-- bar frame. The button rows ARE movable: each button sits in
-- MainActionBarButtonContainer1..12, plain children anchored BOTTOMLEFT to the bar at a
-- fixed 47px pitch. Shifting all 12 by the same delta slides the whole row, and the art
-- / gryphons / page number (which anchor to the buttons) follow along.
--
-- CenterRow measures the row's actual center from the buttons (not from MainActionBar,
-- whose render-left is Edit-Mode-locked and reads unreliably early in login), computes
-- the error to screen center + BAR_SHIFT, and nudges every container's current offset by
-- that error. Purely self-correcting: each container keeps whatever offset it has and is
-- shifted by the measured error, so it converges to centered in one pass and the dead-zone
-- guard (|err| < 0.5) stops it re-firing. No absolute/base bookkeeping, so a bad early
-- measurement can't blow the row off-screen -- the next call just corrects it.
-- Positive BAR_SHIFT moves the row right of screen center.
local BAR_SHIFT = 0
local CONTAINER_COUNT = 12
local centeringRow = false
local function CenterRow()
    if centeringRow then return end
    local b1, b12 = ActionButton1, ActionButton12
    local l = b1 and b1:GetLeft()
    local r = b12 and b12:GetRight()
    if not (l and r) then return end
    local err = (UIParent:GetWidth() / 2 + BAR_SHIFT) - (l + r) / 2
    if math.abs(err) < 0.5 then return end
    centeringRow = true
    for i = 1, CONTAINER_COUNT do
        local c = _G["MainActionBarButtonContainer" .. i]
        if c and c.GetNumPoints and c:GetNumPoints() > 0 then
            local p, rel, rp, x, y = c:GetPoint(1)
            c:ClearAllPoints()
            c:SetPoint(p, rel, rp, (x or 0) + err, y or 0)
        end
    end
    centeringRow = false
end

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
-- Perch them just outside the main 12-button row. Anchoring to the buttons (not the
-- 1024px art frame) keeps them attached to the bar ends regardless of art width or
-- short-vs-long mode; anchoring to the art frame left the left cap floating far out
-- near the chat. GRYPHON_OVERLAP nudges them onto the bar ends.
local GRYPHON_OVERLAP = 6
local function ApplyGryphons()
    local caps = MainBar.EndCaps
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
local ART_SCALE = 1.1
-- Fine alignment of the art plate to the button row (the plate sits slightly left
-- and high within its texture). Positive X = art right; Y is the art bottom vs the
-- button bottom (more negative = art lower).
local ART_X_OFFSET = 5
local ART_Y_OFFSET = -13

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
        ActionBarArt:SetPoint("BOTTOM", ActionButton1, "BOTTOMLEFT", half + ART_X_OFFSET, ART_Y_OFFSET)
    end
    if ActionBarArtSmall then ActionBarArtSmall:Hide() end
    HideDefaultBarArt()
    ApplyGryphons()

    MainBar:ClearAllPoints()
    MainBar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", 110 - half, 11)

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

    local half = HalfRow()
    if ActionBarArt then ActionBarArt:Hide() end
    if ActionBarArtSmall then
        ActionBarArtSmall:Show()
        SizeArt(ActionBarArtSmall)
        ActionBarArtSmall:ClearAllPoints()
        ActionBarArtSmall:SetPoint("BOTTOM", ActionButton1, "BOTTOMLEFT", half + ART_X_OFFSET, ART_Y_OFFSET)
    end
    HideDefaultBarArt()
    ApplyGryphons()

    MainBar:ClearAllPoints()
    MainBar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", 237 - half, 11)

    if MultiBarBottomLeft then
        MultiBarBottomLeft:ClearAllPoints()
        MultiBarBottomLeft:SetPoint("BOTTOMLEFT", MainBar, "TOPLEFT", 8, 0)
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
    local pn = MainBar.ActionBarPageNumber
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

    -- MainActionBar's render is Edit-Mode-locked, so center the row by shifting its
    -- button containers (see CenterRow). Runs last so it overrides whatever the bar's
    -- own layout just did to the containers.
    CenterRow()

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

-- MainActionBar's render is Edit-Mode-locked, so we center the row by shifting its
-- button containers; reassert whenever the bar's own layout moves them back.
for i = 1, CONTAINER_COUNT do
    local c = _G["MainActionBarButtonContainer" .. i]
    if c and c.SetPoint then
        hooksecurefunc(c, "SetPoint", function()
            if not centeringRow then CenterRow() end
        end)
    end
end

-- Keep the page number / flip arrows pinned to the right when the engine moves them.
if MainBar.ActionBarPageNumber and MainBar.ActionBarPageNumber.SetPoint then
    hooksecurefunc(MainBar.ActionBarPageNumber, "SetPoint", function()
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
