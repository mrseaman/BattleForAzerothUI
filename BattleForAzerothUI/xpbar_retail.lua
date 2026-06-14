-- BattleForAzerothUI/xpbar_retail.lua
-- XP / reputation bar: positioning and BfA backdrop.
-- Modern retail / Midnight only (WOW_PROJECT_MAINLINE, interface 120005).
-- The TBC Anniversary 20505 path is xpbar_anniversary.lua.
-- Depends on XPBarBackground defined in artFrames.xml.
-- Defines the cross-file global BFAUI_SetBarWidth (consumed by actionbars_retail.lua),
-- so this file must load before actionbars_retail.lua in the TOC.
--
-- SCOPE NOTE: On Midnight the XP/rep bars live in StatusTrackingBarManager, but the
-- per-bar internal structure changed (no child .StatusBar; 7 anon child frames per
-- container). The deep default-texture stripping the Anniversary path does would be
-- fragile guesswork and is the highest taint-risk area, so this file delivers the
-- robust, visible part: anchor + size the manager to the active BfA bar width and
-- place the BfA dark backdrop behind it. Matching Blizzard's default bar textures
-- pixel-for-pixel can be a follow-up once that internal structure is probed.
if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

local STM = StatusTrackingBarManager

local isUpdating    = false
local currentWidth  = 798
local currentOffset = -111

-- artFrames.xml declares XPBarBackground parent="MainMenuBar", which is nil on
-- Midnight; re-home it under UIParent.
if XPBarBackground then
	XPBarBackground:SetParent(UIParent)
	XPBarBackground:SetFrameStrata("LOW")
	XPBarBackground:Hide()
end

local function ApplyLayout()
	if not STM or isUpdating or InCombatLockdown() then return end
	isUpdating = true

	local h = STM:GetHeight()
	if not h or h <= 0 then h = 20 end

	STM:ClearAllPoints()
	STM:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
	STM:SetWidth(currentWidth)

	if XPBarBackground then
		XPBarBackground:ClearAllPoints()
		XPBarBackground:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
		XPBarBackground:SetSize(currentWidth, h)
		XPBarBackground:Show()
	end

	isUpdating = false
end

-- Cross-file entry point: actionbars_retail.lua calls this on long/short switch.
local function SetBarWidth(width, offset)
	currentWidth  = width or currentWidth
	currentOffset = offset or currentOffset
	ApplyLayout()
end
BFAUI_SetBarWidth = SetBarWidth

if STM then
	if type(STM.UpdateBarsShown) == "function" then
		hooksecurefunc(STM, "UpdateBarsShown", function()
			if not isUpdating then ApplyLayout() end
		end)
	end
	hooksecurefunc(STM, "SetPoint", function()
		if not isUpdating then ApplyLayout() end
	end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("UPDATE_FACTION")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
f:SetScript("OnEvent", function()
	C_Timer.After(0, ApplyLayout)
end)
