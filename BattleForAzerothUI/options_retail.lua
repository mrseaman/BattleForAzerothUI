-- BattleForAzerothUI/options_retail.lua
-- Slash commands, Settings API, static popups, pixel perfect scaling, gryphon hiding.
-- Modern retail / Midnight only (WOW_PROJECT_MAINLINE, interface 120005).
-- The TBC Anniversary 20505 path is options_anniversary.lua.
if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

------------------------------==≡≡[ SLASH COMMANDS ]≡≡==------------------------------

SlashCmdList.BFA = function()
	Settings.OpenToCategory("BattleForAzerothUI")
end
SLASH_BFA1 = "/bfa"
SLASH_BFA2 = "/bfaui"

------------------------------==≡≡[ SETTINGS API ]≡≡==------------------------------

local function InitializeSettings()
	local category = Settings.RegisterCanvasLayoutCategory(BFAOptionsFrame, "BattleForAzerothUI")
	category.ID = "BattleForAzerothUI"
	Settings.RegisterAddOnCategory(category)

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
		Settings.OpenToCategory("BattleForAzerothUI")
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

------------------------------==≡≡[ PIXEL PERFECT ]≡≡==------------------------------

local function PixelPerfect()
	if BFAUI_SavedVars.Options.PixelPerfect == true and Advanced_UseUIScale and Advanced_UIScaleSlider then
		Advanced_UseUIScale:Disable()
		Advanced_UIScaleSlider:Disable()
		getglobal(Advanced_UseUIScale:GetName() .. "Text"):SetTextColor(1, 0, 0, 1)
		getglobal(Advanced_UseUIScale:GetName() .. "Text"):SetText("The 'Use UI Scale' toggle is unavailable while Pixel Perfect mode is active. Type '/bfa' for options.")
		if Advanced_UseUIScaleText then
			Advanced_UseUIScaleText:SetPoint("LEFT", Advanced_UseUIScale, "LEFT", 4, -40)
		end
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", PixelPerfect)

-- Gryphon (end cap) hiding. On Midnight the caps are MainActionBar.EndCaps, not the
-- legacy MainMenuBarLeftEndCap/RightEndCap globals (which are nil here). The actual
-- Midnight gryphon handling lives in actionbars_retail.lua alongside the bar art;
-- this guarded block is a safe no-op on Midnight and only acts if the legacy
-- globals somehow exist.
local function HideGryphons()
	if BFAUI_SavedVars.Options.HideGryphons == true then
		if MainMenuBarLeftEndCap then MainMenuBarLeftEndCap:Hide() end
		if MainMenuBarRightEndCap then MainMenuBarRightEndCap:Hide() end
	end
end

local g = CreateFrame("Frame")
g:RegisterEvent("PLAYER_ENTERING_WORLD")
g:SetScript("OnEvent", HideGryphons)

local function SetPixelPerfect(self, event)
	if BFAUI_SavedVars.Options.PixelPerfect == true then
		if not InCombatLockdown() then
			local scale = min(2, max(0.20, 768 / select(2, GetPhysicalScreenSize())))
			scale = tonumber(string.sub(scale, 0, 5))

			if scale < 0.64 then
				UIParent:SetScale(scale)
			else
				self:UnregisterEvent("UI_SCALE_CHANGED")
				SetCVar("uiScale", scale)
			end
		else
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
		end

		if event == "PLAYER_REGEN_ENABLED" then
			self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		end
	end
end

local h = CreateFrame("Frame")
h:RegisterEvent("VARIABLES_LOADED")
h:RegisterEvent("UI_SCALE_CHANGED")
h:SetScript("OnEvent", SetPixelPerfect)
