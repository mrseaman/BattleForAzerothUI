-- BattleForAzerothUI/actionbars_retail.lua
-- Retail / Midnight (WOW_PROJECT_MAINLINE) action bar handling.
--
-- Bar POSITIONS come from a dedicated Edit Mode layout Blizzard applies via its own
-- secure code (see the EDIT MODE LAYOUT section) to avoid taint issues.
-- This file is OVERLAY ONLY -- art plate, gryphons, page number, flat icons -- anchored
-- to the action BUTTONS so they track the bars wherever the layout parks them.

if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

local isUpdating = false

local function HalfRow()
    local b1, b12 = ActionButton1, ActionButton12
    local l = b1 and b1:GetLeft()
    local r = b12 and b12:GetRight()
    if l and r then return (r - l) / 2 end
    return 281
end

-- Art horizontal shift: LONG covers the main + bottom-right cluster, SHORT the main row.
local ART_X_OFFSET_LONG = 161
local ART_X_OFFSET_SHORT = 20
local ART_Y_OFFSET = -14

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

local ART_BASE_W, ART_BASE_H = 1024, 128
local ART_SCALE = 1.12

local function SizeArt(art)
    if art then art:SetSize(ART_BASE_W * ART_SCALE, ART_BASE_H * ART_SCALE) end
end

local function ApplyLongArt()
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

    if BFAUI_SetBarWidth then BFAUI_SetBarWidth(798, -111) end
end

local function ApplyShortArt()
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

    if BFAUI_SetBarWidth then BFAUI_SetBarWidth(542, -237) end
end

-- Hide the dark slot square (.SlotArt) Midnight draws behind each icon so our art shows
-- through flat. Buttons re-show it on update, so hook Show/SetShown to re-hide.
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

-- Widen only the vertical gap between the 2x6's two rows: Edit Mode's IconPadding is
-- coupled (both axes), so instead we lift the top-row containers (7-12). Child frames,
-- taint-free; idempotent via a captured base; only while our layout is active.
local LAYOUT_NAME = "BattleForAzerothUI"
local ROW_GAP = 8

local function IsBfALayoutActive()
    local li = EditModeManagerFrame and EditModeManagerFrame.layoutInfo
    local active = li and li.layouts and li.layouts[li.activeLayout]
    return active ~= nil and active.layoutName == LAYOUT_NAME
end

local function ApplyRowGap()
    if not IsBfALayoutActive() then return end
    if not (MultiBarBottomRight and MultiBarBottomRight:IsShown()) then return end
    for i = 7, 12 do
        local c = _G["MultiBarBottomRightButtonContainer" .. i]
        if c then
            local p, rel, rp, x, y = c:GetPoint()
            if p then
                c.__bfaBaseY = c.__bfaBaseY or y
                c:ClearAllPoints()
                c:SetPoint(p, rel, rp, x or 0, c.__bfaBaseY + ROW_GAP)
            end
        end
    end
end

-- Move the page number + flip arrows to the right of the bar (BfA layout). Child region,
-- so this SetPoint is taint-safe.
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

local function UpdateOverlay()
    if InCombatLockdown() or isUpdating then return end
    isUpdating = true

    RepositionPageNumber()

    if MultiBarBottomRight and MultiBarBottomRight:IsShown() then
        ApplyLongArt()
    else
        ApplyShortArt()
    end

    isUpdating = false
end

-- Re-pin the page number when the engine moves it.
if MainActionBar.ActionBarPageNumber and MainActionBar.ActionBarPageNumber.SetPoint then
    hooksecurefunc(MainActionBar.ActionBarPageNumber, "SetPoint", function()
        if not repositioningPage then RepositionPageNumber() end
    end)
end

-- Redraw from our own events, deferred one frame so Blizzard's layout settles first.
local function Reapply()
    C_Timer.After(0, function()
        UpdateOverlay()
        ApplyRowGap()
        FlattenButtons()
    end)
end

local BFA_Manager = CreateFrame("Frame")
BFA_Manager:RegisterEvent("PLAYER_LOGIN")
BFA_Manager:RegisterEvent("PLAYER_ENTERING_WORLD")
BFA_Manager:RegisterEvent("PLAYER_REGEN_ENABLED")      -- redraw after combat
BFA_Manager:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED") -- re-anchor when the layout changes
BFA_Manager:SetScript("OnEvent", Reapply)

if MultiBarBottomLeft then
    MultiBarBottomLeft:HookScript("OnShow", UpdateOverlay)
    MultiBarBottomLeft:HookScript("OnHide", UpdateOverlay)
end
if MultiBarBottomRight then
    MultiBarBottomRight:HookScript("OnShow", UpdateOverlay)
    MultiBarBottomRight:HookScript("OnHide", UpdateOverlay)
end

-- ============================ EDIT MODE LAYOUT ============================
-- Write our bar positions into a dedicated custom layout and let Blizzard apply it
-- securely (taint-free). MakeNewLayout crashes when called cold from an addon, so we
-- build the layout manually: copy the active one, rename/retype, insert, save, activate.

-- Source of truth for the bottom-right bar is the live system toggle (2nd action-bar
-- toggle), keeping our centering and the options checkbox in sync both ways.
local function ShowBar3()
    if GetActionBarToggles then
        local _, bottomRight = GetActionBarToggles()
        return bottomRight and true or false
    end
    return true
end

-- systemIndex -> anchor + row count; main/bottomleft X depends on ShowBar3.
local function BarConfigs()
    local mainX = ShowBar3() and -163 or 0
    return {
        [1]  = { x = mainX, y = 14,  rows = 1 }, -- MainActionBar
        [2]  = { x = mainX, y = 68,  rows = 1 }, -- MultiBarBottomLeft
        [3]  = { x = 305,   y = 14,  rows = 2 }, -- MultiBarBottomRight (2x6)
        [11] = { x = -360,  y = 120, rows = 1 }, -- StanceBar
        [12] = { x = -360,  y = 120, rows = 1 }, -- PetActionBar
    }
end

local function SetSetting(systemInfo, setting, value)
    systemInfo.settings = systemInfo.settings or {}
    for _, e in ipairs(systemInfo.settings) do
        if e.setting == setting then e.value = value; return end
    end
    table.insert(systemInfo.settings, { setting = setting, value = value })
end

local function WriteBars(layout)
    local cfg = BarConfigs()
    for _, s in ipairs(layout.systems) do
        if s.system == Enum.EditModeSystem.ActionBar and cfg[s.systemIndex] then
            local c = cfg[s.systemIndex]
            s.isInDefaultPosition = false
            s.anchorInfo = { point = "BOTTOM", relativeTo = "UIParent",
                             relativePoint = "BOTTOM", offsetX = c.x, offsetY = c.y }
            SetSetting(s, Enum.EditModeActionBarSetting.NumRows, c.rows)
        end
    end
end

local applying = false
local function ApplyBfALayout()
    if applying then return end
    if InCombatLockdown() then
        print("|cffdedee2BfA:|r can't change the layout in combat.")
        return
    end
    local EM = EditModeManagerFrame
    local li = EM and EM.layoutInfo
    if not li or not li.layouts then
        print("|cffdedee2BfA:|r Edit Mode isn't ready yet; try again after login.")
        return
    end
    applying = true

    local idx
    for i, lay in ipairs(li.layouts) do
        if lay.layoutName == LAYOUT_NAME then idx = i break end
    end
    if not idx then
        local base = CopyTable(li.layouts[li.activeLayout])
        base.layoutName = LAYOUT_NAME
        base.layoutType = Enum.EditModeLayoutType.Account
        table.insert(li.layouts, base)
        idx = #li.layouts
    end

    WriteBars(li.layouts[idx])
    li.activeLayout = idx
    C_EditMode.SaveLayouts(li)
    if C_EditMode.SetActiveLayout then C_EditMode.SetActiveLayout(idx) end

    applying = false

    StaticPopupDialogs["BFAUI_LAYOUT_RELOAD"] = StaticPopupDialogs["BFAUI_LAYOUT_RELOAD"] or {
        text = "BattleForAzerothUI action bar layout applied.\nReload now to position the bars?",
        button1 = OKAY or "Okay",
        button2 = CANCEL or "Cancel",
        OnAccept = function() C_UI.Reload() end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopup_Show("BFAUI_LAYOUT_RELOAD")
end

-- Exposed for the options panel.
BFAUI_ApplyLayout = ApplyBfALayout

SLASH_BFALAYOUT1 = "/bfalayout"
SlashCmdList["BFALAYOUT"] = function() ApplyBfALayout() end

-- Two-way sync with the bottom-right bar toggle. Gate until after login so Blizzard's own
-- toggle-restore doesn't trigger a reload.
local function CurrentBottomRight()
    if not GetActionBarToggles then return nil end
    local _, br = GetActionBarToggles()
    return br and true or false
end

local bfaReady = false
local lastBottomRight
local readyFrame = CreateFrame("Frame")
readyFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
readyFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    C_Timer.After(1, function()
        lastBottomRight = CurrentBottomRight()
        bfaReady = true
    end)
end)

-- Options checkbox hook: flip the system bar; the SetActionBarToggles hook below reacts.
function BFAUI_SetBottomRightBar(enabled)
    if InCombatLockdown() then
        print("|cffdedee2BfA:|r can't change action bars in combat.")
        return
    end
    if not (GetActionBarToggles and SetActionBarToggles) then
        print("|cffdedee2BfA:|r action bar toggle API unavailable on this client.")
        return
    end
    local bl, _, r, l, a = GetActionBarToggles()
    SetActionBarToggles(bl, enabled and true or false, r, l, a)
end

-- Re-apply (re-center main) when the bottom-right bar is toggled, from our checkbox or
-- Blizzard's. Gated to after load + our active layout; `applying` guards recursion.
if SetActionBarToggles then
    hooksecurefunc("SetActionBarToggles", function()
        if not bfaReady or applying then return end
        if InCombatLockdown() then return end
        if not IsBfALayoutActive() then return end
        local br = CurrentBottomRight()
        if br == lastBottomRight then return end
        lastBottomRight = br
        ApplyBfALayout()
    end)
end
