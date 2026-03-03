-- BattleForAzerothUI/core.lua
-- Entry point: version detection, saved variables, and shared frame utilities.
-- Must be loaded first (before all other addon files).

local WoWClassicEra = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local WoWRetail     = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

print("Battle for Azeroth UI: |cffdedee2Type /bfa to toggle the options menu.")

------------------==≡≡[ SAVED VARIABLES ]≡≡==------------------

local function EnteringWorld()
	if BFAUI_SavedVars == nil then -- Create Saved Variables:
		if GetCVar("xpBarText") == "1" then
			tf = true
		else
			tf = false
		end
		BFAUI_SavedVars = {}
		BFAUI_SavedVars["Options"] = {
			["PixelPerfect"] = false,
			["XPBarText"] = tf,
			["HideGryphons"] = false,
			["KeybindVisibility"] = {
				["PrimaryBar"] = true,
				["BottomLeftBar"] = true,
				["BottomRightBar"] = true,
				["RightBar"] = true,
				["RightBar2"] = true,
			},
		}
		StaticPopup_Show("WELCOME_POPUP")
	else -- Apply Saved Variables:
		if BFAUI_SavedVars.Options.KeybindVisibility.PrimaryBar then
			PrimaryBarAlpha = 1
		else
			PrimaryBarAlpha = 0
		end

		if BFAUI_SavedVars.Options.KeybindVisibility.BottomLeftBar then
			BottomLeftBarAlpha = 1
		else
			BottomLeftBarAlpha = 0
		end

		if BFAUI_SavedVars.Options.KeybindVisibility.BottomRightBar then
			BottomRightBarAlpha = 1
		else
			BottomRightBarAlpha = 0
		end

		if BFAUI_SavedVars.Options.KeybindVisibility.RightBar then
			RightBarAlpha = 1
		else
			RightBarAlpha = 0
		end

		if BFAUI_SavedVars.Options.KeybindVisibility.RightBar2 then
			RightBar2Alpha = 1
		else
			RightBar2Alpha = 0
		end

		for i = 1, 12 do
			_G["ActionButton" .. i .. "HotKey"]:SetAlpha(PrimaryBarAlpha)
			_G["MultiBarBottomLeftButton" .. i .. "HotKey"]:SetAlpha(BottomLeftBarAlpha)
			_G["MultiBarBottomRightButton" .. i .. "HotKey"]:SetAlpha(BottomRightBarAlpha)
			_G["MultiBarRightButton" .. i .. "HotKey"]:SetAlpha(RightBarAlpha)
			_G["MultiBarLeftButton" .. i .. "HotKey"]:SetAlpha(RightBar2Alpha)
		end
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", EnteringWorld)

------------------------==≡≡[ FRAME UTILITIES ]≡≡==------------------------

-- UIHider: permanently hidden parent frame.
-- Reparenting a frame here makes it invisible even if Show() is later called on it.
-- This is the canonical retail-engine technique (same as Bartender4's HideBlizzard.lua).
-- The retail engine no-ops Kill()-style methods, making them insufficient.
local UIHider = CreateFrame("Frame")
UIHider:Hide()

local function HideFrame(frame)
	if frame then
		frame:UnregisterAllEvents()
		frame:SetParent(UIHider)
	end
end

HideFrame(HonorWatchBar)
HideFrame(MainMenuBarMaxLevelBar)
HideFrame(ArtifactWatchBar)

-- StatusTrackingBarManager (retail engine) manages all status bars and
-- calls MainMenuBar:SetPositionForStatusBars() to shift the action bar upward.
HideFrame(StatusTrackingBarManager)

-- Prevent MainMenuBar from being pushed up by status bar layout code.
if MainMenuBar.SetPositionForStatusBars then
	MainMenuBar.SetPositionForStatusBars = function() end
end

-- Hide default action bar background textures.
for i = 0, 3 do
	local tex = _G["MainMenuBarTexture" .. i]
	if tex then tex:Hide() end
end
