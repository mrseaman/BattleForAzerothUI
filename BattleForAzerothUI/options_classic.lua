-- BattleForAzerothUI/options_classic.lua
-- Slash commands, Settings API, static popups, pixel perfect scaling, and gryphon hiding.
-- Classic Era (WOW_PROJECT_CLASSIC) and TBC Classic Anniversary
-- (WOW_PROJECT_BURNING_CRUSADE_CLASSIC). NOT modern retail / Midnight.
if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC and WOW_PROJECT_ID ~= WOW_PROJECT_BURNING_CRUSADE_CLASSIC then return end

------------------------------==≡≡[ SETTINGS API ]≡≡==------------------------------

local bfaCategory

local function InitializeSettings()
	bfaCategory = Settings.RegisterCanvasLayoutCategory(BFAOptionsFrame, "BattleForAzerothUI")
	Settings.RegisterAddOnCategory(bfaCategory)

	if BFAOptionsFrameClose then
		BFAOptionsFrameClose:Hide()
	end
	if BFAOptionsFrameHeader then
		BFAOptionsFrameHeader:Hide()
	end
	if BFAOptionsFrameHeaderText then
		BFAOptionsFrameHeaderText:Hide()
	end
end

------------------------------==≡≡[ SLASH COMMANDS ]≡≡==------------------------------

SlashCmdList.BFA = function()
	if bfaCategory then
		Settings.OpenToCategory(bfaCategory:GetID())
	end
end
SLASH_BFA1 = "/bfa"
SLASH_BFA2 = "/bfaui"

local settingsFrame = CreateFrame("Frame")
settingsFrame:RegisterEvent("ADDON_LOADED")
settingsFrame:SetScript("OnEvent", function(self, event, addonName)
	if addonName == "BattleForAzerothUI" then
		C_Timer.After(0.1, InitializeSettings)
		self:UnregisterEvent("ADDON_LOADED")
	end
end)

------------------------------==≡≡[ STATIC POPUPS ]≡≡==------------------------------

StaticPopupDialogs["WELCOME_POPUP"] = {
	text = "Welcome to Battle for Azeroth UI\n\nType /bfa to open options.",
	button1 = "Open Options",
	button2 = "Close",
	OnAccept = function()
		if bfaCategory then
			Settings.OpenToCategory(bfaCategory:GetID())
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["ReloadUI_Popup"] = {
	text = "Reload your UI to apply changes?",
	button1 = "Reload",
	button2 = "Later",
	OnAccept = function()
		ReloadUI()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

------------------------------==≡≡[ GRYPHONS ]≡≡==------------------------------

local function HideGryphons()
	if BFAUI_SavedVars.Options.HideGryphons == true then
		MainMenuBarLeftEndCap:Hide()
		MainMenuBarRightEndCap:Hide()
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", HideGryphons)

