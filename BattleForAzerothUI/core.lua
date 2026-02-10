----------------------------------==≡≡[ NOTES ]≡≡==----------------------------------
--[[
CHANGES:
	2.1 (Zechen):
		-Fixed XP bar not hiding at level 60 (max level).
		-Migrated options panel to WoW's Settings API for centralized addon options.
		-Fixed reputation bar display - can now show reputation progress when tracked.
		-Options accessible via /bfa or Game Menu > Options > AddOns > BattleForAzerothUI.
	1.12 (Zeechn):
		-Fix errors to make the addon work on WoW Classic Anniversary Servers, client version 1.15.8.
	1.11 (EsreverWoW):
		-Added free bag space data text on the backpack.
		-Potential fix for XP bar visibility.
	1.10 (EsreverWoW):
		-Updated art assets to match those found in BfA today.
		-Added an option and handling for hiding gryphons on the main action bar.
	1.09 (EsreverWoW):
		-Fixed an issue where the strata was too low for the XP bar.
	1.08 (EsreverWoW):
		-Changed the MicroMenuArt texture to have a shorter width since we didn't need three of the slots.
		-Fixed the QuestLogMicroButton placement/sizing when playing on a character below level 10.
		-Small change to pixel perfect scaling to correct for a bug present in 8.1/Classic.
		-Cleanup and refactoring.
	1.07 (EsreverWoW):
		-Modified to restore the BfA UI to WoW Classic.
		-Removed code irrelevant to WoW Classic.
	1.06:
		-The Objective Tracker should now position itself correctly underneath the Blizzard Arena Frames
		-The Vehicle Seat Indicator should now position itself correctly when the Objective Tracker or Arena Frames are visible
		-Pixel Perfect Mode now works as intended (minor bugs fixed)
		-Refactored code
	1.05:
		-Enabling 'Right Bar' while 'Right Bar 2' is disabled, will now enlarge and reposition the 'Right Bar'
		-Fixed visual issue where the Artifact bar would move around randomly during battlegrounds and other events
		-Fixed stance issue positioning for single stance bar when the Bottom Left Bar is hidden (Thanks to Ilraei for pointing it out)
		-Fixed issue where the Exhaustion Tick would not reposition correctly on experience bar resize
		-Fixed issue where the Vehicle Seat Indicator would appear on top the Objective/Quest frame
		-Refactored code
	1.04:
		-Fixed visual issue when unequipping artifact weapon at max level
		-Fixed visual issue when logging in at max level with no artifact weapon equipped
	1.03:
		-Fixed Pet ActionBar positioning and art for when the Bottom Left ActionBar is hidden
		-Fixed [ADDON_ACTION_BLOCKED] errors. (The AddOn will now only call protected functions when out of combat)
	1.02:
		-Recreated Pixel Perfect Mode, now works on resolutions higher than 1080p
	1.01:
		-Fixed 98-109 issue where the artifact bar would appear on UPDATE_EXHAUSTION event

PERSONAL NOTES:
		C_Timer.After(3, function() -- 3 second delay
			-- do something
		end)
--]]

------------------==≡≡[ CREATING AND APPLYING SAVED VARIABLES ]≡≡==------------------

print("Battle for Azeroth UI: |cffdedee2Type /bfa to toggle the options menu.")
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
		StaticPopup_Show(WELCOME_POPUP)
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
			BottomLeftBarAlpha = 1
		else
			BottomLeftBarAlpha = 0
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
			_G["MultiBarBottomRightButton" .. i .. "HotKey"]:SetAlpha(BottomLeftBarAlpha)
			_G["MultiBarRightButton" .. i .. "HotKey"]:SetAlpha(RightBarAlpha)
			_G["MultiBarLeftButton" .. i .. "HotKey"]:SetAlpha(RightBar2Alpha)
		end
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", EnteringWorld)

------------------------------==≡≡[ OPTIONS FRAME ]≡≡==------------------------------

SlashCmdList.BFA = function()
	-- Open the Settings panel to our addon category
	Settings.OpenToCategory("BattleForAzerothUI")
end
SLASH_BFA1 = "/bfa"
SLASH_BFA2 = "/bfaui"

------------------------------==≡≡[ SETTINGS API ]≡≡==------------------------------

local function InitializeSettings()
	-- Create the settings category
	local category = Settings.RegisterCanvasLayoutCategory(BFAOptionsFrame, "BattleForAzerothUI")
	category.ID = "BattleForAzerothUI"
	Settings.RegisterAddOnCategory(category)

	-- Hide the original close button since Settings panel has its own
	if BFAOptionsFrameClose then
		BFAOptionsFrameClose:Hide()
	end

	-- Hide the header since Settings panel provides context
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
		-- Delay initialization to ensure Settings API is ready
		C_Timer.After(0.1, InitializeSettings)
		self:UnregisterEvent("ADDON_LOADED")
	end
end)

local function PixelPerfect()
	if BFAUI_SavedVars.Options.PixelPerfect == true then
		-- enable system button, hide text
		Advanced_UseUIScale:Disable()
		Advanced_UIScaleSlider:Disable()
		getglobal(Advanced_UseUIScale:GetName() .. "Text"):SetTextColor(1, 0, 0, 1)
		getglobal(Advanced_UseUIScale:GetName() .. "Text"):SetText("The 'Use UI Scale' toggle is unavailable while Pixel Perfect mode is active. Type '/bfa' for options.")
		Advanced_UseUIScaleText:SetPoint("LEFT", Advanced_UseUIScale, "LEFT", 4, -40)
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", PixelPerfect)

local function HideGryphons()
	if BFAUI_SavedVars.Options.HideGryphons == true then
		MainMenuBarLeftEndCap:Hide()
		MainMenuBarRightEndCap:Hide()
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", HideGryphons)

-- reference :http://wowwiki.wikia.com/wiki/Creating_simple_pop-up_dialog_boxes
StaticPopupDialogs.WELCOME_POPUP = {
	text = "Welcome to Battle for Azeroth UI\n\nType /bfa to open options.",
	button1 = "Open Options",
	button2 = "Close",
	OnAccept = function()
		Settings.OpenToCategory("BattleForAzerothUI")
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3, -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
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

local function SetPixelPerfect(self)
	if BFAUI_SavedVars.Options.PixelPerfect == true then
		if not InCombatLockdown() then
			local scale = min(2, max(0.20, 768 / select(2, GetPhysicalScreenSize())))
			scale = tonumber(string.sub(scale, 0, 5)) -- Fix 8.1/Classic scale bug

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

local f = CreateFrame("Frame")
f:RegisterEvent("VARIABLES_LOADED")
f:RegisterEvent("UI_SCALE_CHANGED")
f:SetScript("OnEvent", SetPixelPerfect)

------------------------==≡≡[ DELETE AND DISABLE FRAMES ]≡≡==------------------------

local function null()
	return
end

-- efficiant way to remove frames (does not work on textures)
local function Kill(frame)
	if type(frame) == "table" and frame.SetScript then
		frame:UnregisterAllEvents()
		frame:SetScript("OnEvent", nil)
		frame:SetScript("OnUpdate", nil)
		frame:SetScript("OnHide", nil)
		frame:Hide()
		frame.SetScript = null
		frame.RegisterEvent = null
		frame.RegisterAllEvents = null
		frame.Show = null
	end
end

Kill(HonorWatchBar)
Kill(MainMenuBarMaxLevelBar) -- Fixed visual bug when unequipping artifact weapon at max level

----------------------------------==≡≡[ XP BAR ]≡≡==----------------------------------

-- Hide default XP bar textures
for i = 0, 3 do
	_G["MainMenuXPBarTexture" .. i]:Hide()
end

-- Hide default reputation bar textures
for i = 0, 3 do
	local tex = _G["ReputationWatchBarTexture" .. i]
	if tex then tex:Hide() end
end

MainMenuExpBar:SetFrameStrata("MEDIUM")
ExhaustionTick:SetFrameStrata("HIGH")

MainMenuBarExpText:ClearAllPoints()
MainMenuBarExpText:SetPoint("CENTER", MainMenuExpBar, 0, 0)
MainMenuBarOverlayFrame:SetFrameStrata("HIGH") -- changes xp bar text strata

-- Set reputation bar strata
if ReputationWatchBar then
	ReputationWatchBar:SetFrameStrata("MEDIUM")
end

-- Constants
local MAX_LEVEL = 60
local FULL_BAR_HEIGHT = 10
local HALF_BAR_HEIGHT = 5

-- Track current bar width (set by ActivateLongBar/ActivateShortBar)
local currentBarWidth = 798
local currentBarOffset = -111

-- Create a custom background for the reputation bar (matching XPBarBackground style)
local RepBarBackground = CreateFrame("Frame", "RepBarBackground", MainMenuBar)
RepBarBackground:SetFrameStrata("LOW")
RepBarBackground:SetSize(798, 10)
local repBgTexture = RepBarBackground:CreateTexture(nil, "BACKGROUND")
repBgTexture:SetAllPoints()
repBgTexture:SetTexture("Interface/ChatFrame/ChatFrameBackground")
repBgTexture:SetVertexColor(0, 0, 0, 0.75)
RepBarBackground:Hide()

-- Helper function to hide all default reputation bar decorations
local function HideReputationBarDecorations()
	if not ReputationWatchBar then return end

	-- Get the status bar (might be accessed via method or property)
	local statusBar = ReputationWatchBar.StatusBar
	if not statusBar and ReputationWatchBar.GetStatusBar then
		statusBar = ReputationWatchBar:GetStatusBar()
	end
	if not statusBar then
		statusBar = _G["ReputationWatchStatusBar"]
	end

	-- Hide background textures by name (ReputationWatchBarTexture0-3)
	for i = 0, 3 do
		local tex = _G["ReputationWatchBarTexture" .. i]
		if tex then tex:Hide() end
	end

	-- Hide the overlay frame on the watch bar itself
	if ReputationWatchBar.OverlayFrame then
		ReputationWatchBar.OverlayFrame:Hide()
	end

	-- Try common global frame names for tick containers and overlays
	local framesToCheck = {
		"ReputationWatchBarOverlayFrame",
		"ReputationWatchBarTick",
		"ReputationWatchStatusBarOverlayFrame",
		"ReputationWatchStatusBarBackground",
	}
	for _, name in ipairs(framesToCheck) do
		local frame = _G[name]
		if frame then
			-- If it has an OverlayFrame child, hide it
			if frame.OverlayFrame then
				frame.OverlayFrame:Hide()
			end
			frame:Hide()
		end
	end

	-- Also check for ReputationWatchStatusBar and hide its overlay (but not the bar itself)
	local repStatusBar = _G["ReputationWatchStatusBar"]
	if repStatusBar then
		if repStatusBar.OverlayFrame then
			repStatusBar.OverlayFrame:Hide()
		end
		-- Hide children of the status bar (overlays, ticks)
		for _, child in pairs({repStatusBar:GetChildren()}) do
			child:Hide()
		end
	end

	-- Hide child frames of ReputationWatchBar except the actual StatusBar
	for _, child in pairs({ReputationWatchBar:GetChildren()}) do
		if child ~= statusBar then
			child:Hide()
		end
	end

	-- Hide textures directly on ReputationWatchBar frame
	for _, region in pairs({ReputationWatchBar:GetRegions()}) do
		if region:GetObjectType() == "Texture" then
			region:Hide()
		end
	end

	-- Handle the StatusBar's decorations
	if statusBar then
		-- Hide the overlay frame on the status bar (contains tick marks)
		if statusBar.OverlayFrame then
			statusBar.OverlayFrame:Hide()
		end

		-- Hide child frames of StatusBar (these are usually overlay/tick frames)
		for _, child in pairs({statusBar:GetChildren()}) do
			child:Hide()
		end

		-- Hide non-fill textures on the status bar
		for _, region in pairs({statusBar:GetRegions()}) do
			if region:GetObjectType() == "Texture" then
				local layer = region:GetDrawLayer()
				if layer ~= "BACKGROUND" then
					region:Hide()
				end
			end
		end
	end
end

-- Create custom overlay frame for reputation bar text (similar to MainMenuBarOverlayFrame for XP)
local RepBarOverlayFrame = CreateFrame("Frame", "BFARepBarOverlayFrame", UIParent)
RepBarOverlayFrame:SetFrameStrata("HIGH")
RepBarOverlayFrame:EnableMouse(true)
RepBarOverlayFrame:Hide()

-- Create the reputation bar text
local RepBarText = RepBarOverlayFrame:CreateFontString("BFARepBarText", "OVERLAY", "TextStatusBarText")
RepBarText:SetPoint("CENTER", RepBarOverlayFrame, "CENTER", 0, 0)
RepBarText:SetAlpha(0)

-- Update reputation bar text content
local function UpdateRepBarText()
	local name, standing, minRep, maxRep, currentRep = GetWatchedFactionInfo()
	if name then
		local repValue = currentRep - minRep
		local repMax = maxRep - minRep
		RepBarText:SetText(string.format("%s: %d / %d", name, repValue, repMax))
	else
		RepBarText:SetText("")
	end
end

-- Mouseover handlers for reputation bar text (same as XP bar behavior)
RepBarOverlayFrame:SetScript("OnEnter", function(self)
	RepBarText:SetAlpha(1)
end)

RepBarOverlayFrame:SetScript("OnLeave", function(self)
	RepBarText:SetAlpha(0)
end)

-- Function to position the overlay frame to match reputation bar
local function UpdateRepBarOverlay()
	if ReputationWatchBar and ReputationWatchBar:IsShown() then
		RepBarOverlayFrame:ClearAllPoints()
		RepBarOverlayFrame:SetAllPoints(ReputationWatchBar)
		RepBarOverlayFrame:Show()
		UpdateRepBarText()
	else
		RepBarOverlayFrame:Hide()
	end
end

-- Helper function to set reputation bar size (handles StatusBar child if present)
local function SetReputationBarSize(width, height)
	if not ReputationWatchBar then return end

	ReputationWatchBar:SetSize(width, height)

	-- Get the status bar - try multiple methods
	local statusBar = ReputationWatchBar.StatusBar
	if not statusBar and ReputationWatchBar.GetStatusBar then
		statusBar = ReputationWatchBar:GetStatusBar()
	end
	if not statusBar then
		statusBar = _G["ReputationWatchStatusBar"]
	end

	-- Resize the StatusBar if found
	if statusBar then
		statusBar:SetSize(width, height)
		statusBar:ClearAllPoints()
		statusBar:SetAllPoints(ReputationWatchBar)
	end

	-- Hide all decorations
	HideReputationBarDecorations()
end

-- Main function to update XP and reputation bar display
local function UpdateBarsDisplay()
	local playerLevel = UnitLevel("player")
	local isMaxLevel = playerLevel >= MAX_LEVEL
	local hasWatchedFaction = GetWatchedFactionInfo() ~= nil

	if isMaxLevel then
		-- At max level: hide XP bar completely
		MainMenuExpBar:Hide()
		XPBarBackground:Hide()

		if hasWatchedFaction and ReputationWatchBar then
			-- Show reputation bar at full height
			ReputationWatchBar:ClearAllPoints()
			ReputationWatchBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
			SetReputationBarSize(currentBarWidth, FULL_BAR_HEIGHT)
			ReputationWatchBar:Show()

			RepBarBackground:ClearAllPoints()
			RepBarBackground:SetPoint("BOTTOM", MainMenuBar, currentBarOffset, -11)
			RepBarBackground:SetSize(currentBarWidth, FULL_BAR_HEIGHT)
			RepBarBackground:Show()
		else
			-- No faction watched, hide everything
			if ReputationWatchBar then
				ReputationWatchBar:Hide()
			end
			RepBarBackground:Hide()
		end
	else
		-- Before max level: always show XP bar
		if hasWatchedFaction and ReputationWatchBar then
			-- Both bars: stack them at half height each
			-- XP bar on top
			MainMenuExpBar:ClearAllPoints()
			MainMenuExpBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, HALF_BAR_HEIGHT)
			MainMenuExpBar:SetSize(currentBarWidth, HALF_BAR_HEIGHT)
			MainMenuExpBar:Show()

			XPBarBackground:ClearAllPoints()
			XPBarBackground:SetPoint("BOTTOM", MainMenuBar, currentBarOffset, -11 + HALF_BAR_HEIGHT)
			XPBarBackground:SetSize(currentBarWidth, HALF_BAR_HEIGHT)
			XPBarBackground:Show()

			-- Reputation bar on bottom
			ReputationWatchBar:ClearAllPoints()
			ReputationWatchBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
			SetReputationBarSize(currentBarWidth, HALF_BAR_HEIGHT)
			ReputationWatchBar:Show()

			RepBarBackground:ClearAllPoints()
			RepBarBackground:SetPoint("BOTTOM", MainMenuBar, currentBarOffset, -11)
			RepBarBackground:SetSize(currentBarWidth, HALF_BAR_HEIGHT)
			RepBarBackground:Show()
		else
			-- Only XP bar at full height
			MainMenuExpBar:ClearAllPoints()
			MainMenuExpBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
			MainMenuExpBar:SetSize(currentBarWidth, FULL_BAR_HEIGHT)
			MainMenuExpBar:Show()

			XPBarBackground:ClearAllPoints()
			XPBarBackground:SetPoint("BOTTOM", MainMenuBar, currentBarOffset, -11)
			XPBarBackground:SetSize(currentBarWidth, FULL_BAR_HEIGHT)
			XPBarBackground:Show()

			if ReputationWatchBar then
				ReputationWatchBar:Hide()
			end
			RepBarBackground:Hide()
		end
	end

	-- Update the reputation bar overlay for mouseover text
	UpdateRepBarOverlay()
end

-- Function to update bar width (called from ActivateLongBar/ActivateShortBar)
local function SetBarWidth(width, offset)
	currentBarWidth = width
	currentBarOffset = offset
	UpdateBarsDisplay()
end

-- Make SetBarWidth accessible globally for action bar functions
BFAUI_SetBarWidth = SetBarWidth

local xpBarFrame = CreateFrame("Frame")
xpBarFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
xpBarFrame:RegisterEvent("PLAYER_LEVEL_UP")
xpBarFrame:RegisterEvent("UPDATE_FACTION")
xpBarFrame:SetScript("OnEvent", UpdateBarsDisplay)

-- Hook Blizzard's experience bar update to apply our custom display after
hooksecurefunc("MainMenuBar_UpdateExperienceBars", function()
	-- Delay slightly to ensure Blizzard's changes are applied first, then override
	C_Timer.After(0.01, UpdateBarsDisplay)
end)

-- Also hook the reputation bar's OnShow to override Blizzard positioning and hide decorations
if ReputationWatchBar then
	ReputationWatchBar:HookScript("OnShow", function()
		C_Timer.After(0.01, function()
			HideReputationBarDecorations()
			UpdateBarsDisplay()
			UpdateRepBarOverlay()
		end)
	end)
	ReputationWatchBar:HookScript("OnHide", function()
		RepBarOverlayFrame:Hide()
	end)
	-- Initial hide of decorations
	HideReputationBarDecorations()
end

---------------==≡≡[ MICRO MENU MOVEMENT, POSITIONING AND SIZING ]≡≡==---------------

local function MoveMicroButtonsToBottomRight()
	-- Artwork
	MicroMenuArt:Show()
	MicroMenuArt:SetFrameStrata("BACKGROUND")

	-- MicroMenu Buttons
	for i = 1, #MICRO_BUTTONS do
		local button, previousButton = _G[MICRO_BUTTONS[i]], _G[MICRO_BUTTONS[i-1]]

		button:ClearAllPoints()
		-- button:SetSize(28, 58)

		if i == 1 then
			button:SetPoint("BOTTOMRIGHT", UIParent, -198, 4)
		else
			button:SetPoint("BOTTOMRIGHT", previousButton, 28, 0)
		end
	end

	-- Latency Bar
	MainMenuBarPerformanceBarFrame:SetFrameStrata("HIGH")
	MainMenuBarPerformanceBarFrame:SetScale((HelpMicroButton:GetWidth() / MainMenuBarPerformanceBarFrame:GetWidth()) * (1 / 3))

	MainMenuBarPerformanceBar:SetRotation(math.pi * 0.5)
	MainMenuBarPerformanceBar:ClearAllPoints()
	MainMenuBarPerformanceBar:SetPoint("BOTTOM", HelpMicroButton, -1, -24)

	MainMenuBarPerformanceBarFrameButton:ClearAllPoints()
	MainMenuBarPerformanceBarFrameButton:SetPoint("BOTTOMLEFT", MainMenuBarPerformanceBar, -(MainMenuBarPerformanceBar:GetWidth() / 2), 0)
	MainMenuBarPerformanceBarFrameButton:SetPoint("TOPRIGHT", MainMenuBarPerformanceBar, MainMenuBarPerformanceBar:GetWidth() / 2, -28)

	-- Bags
	MainMenuBarBackpackButton:SetScale(1)
	for i = 0, 3 do
		local bagFrame, previousBag = _G["CharacterBag" .. i .. "Slot"], _G["CharacterBag" .. i-1 .. "Slot"]

		bagFrame:SetScale(0.75)
		bagFrame:ClearAllPoints()

		if i == 0 then
			bagFrame:SetPoint("BOTTOMRIGHT", MainMenuBarBackpackButton, "BOTTOMLEFT", -9, 1)
		else
			bagFrame:SetPoint("BOTTOMRIGHT", previousBag, "BOTTOMLEFT", -6, 0)
		end
	end
end

local function MoveMicroButtons_Hook(...)
	MoveMicroButtonsToBottomRight()
end
hooksecurefunc("MoveMicroButtons", MoveMicroButtons_Hook)
hooksecurefunc("UpdateMicroButtons", MoveMicroButtons_Hook)
hooksecurefunc("MainMenuBarVehicleLeaveButton_Update", MoveMicroButtons_Hook)

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", MoveMicroButtonsToBottomRight)

----------------==≡≡[ ACTIONBARS/BUTTONS POSITIONING AND SCALING ]≡≡==----------------

-- Only needs to be run once:
local function Initial_ActionBarPositioning()
	if not InCombatLockdown() then
		-- reposition bottom left actionbuttons
		MultiBarBottomLeftButton1:SetPoint("BOTTOMLEFT", MultiBarBottomLeft, 0, -6)

		-- reposition bottom right actionbar
		MultiBarBottomRight:SetPoint("LEFT", MultiBarBottomLeft, "RIGHT", 43, -6)

		-- reposition second half of top right bar, underneath
		MultiBarBottomRightButton7:SetPoint("LEFT", MultiBarBottomRight, 0, -48)

		-- reposition right bottom
		-- MultiBarLeftButton1:SetPoint("TOPRIGHT", MultiBarLeft, 41, 11)

		-- reposition bags
		MainMenuBarBackpackButton:SetPoint("BOTTOMRIGHT", UIParent, -5, 47)

		-- reposition pet actionbuttons
		SlidingActionBarTexture0:SetPoint("TOPLEFT", PetActionBarFrame, 1, -5) -- pet bar texture (displayed when bottom left bar is hidden)
		PetActionButton1:ClearAllPoints()
		PetActionButton1:SetPoint("TOP", PetActionBarFrame, "LEFT", 51, 4)

		-- stance buttons
		StanceBarLeft:SetPoint("BOTTOMLEFT", StanceBarFrame, 0, -5) -- stance bar texture for when Bottom Left Bar is hidden
		StanceButton1:ClearAllPoints()
		StanceButton1:SetPoint("LEFT", StanceBarFrame, 2, -4)
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", Initial_ActionBarPositioning)

local function ActivateLongBar()
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

	if not InCombatLockdown() then
		-- arrows and page number
		ActionBarUpButton:SetPoint("CENTER", MainMenuBarArtFrame, "TOPLEFT", 521, -23)
		ActionBarDownButton:SetPoint("CENTER", MainMenuBarArtFrame, "TOPLEFT", 521, -42)
		MainMenuBarPageNumber:SetPoint("CENTER", MainMenuBarArtFrame, 28, -5)

		-- reposition ALL actionbars (right bars not affected)
		MainMenuBar:SetPoint("BOTTOM", UIParent, 110, 11)

		-- Update XP/Rep bar sizes via the unified function
		if BFAUI_SetBarWidth then
			BFAUI_SetBarWidth(798, -111)
		end
	end
end

local function ActivateShortBar()
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

	if not InCombatLockdown() then
		-- arrows and page number
		ActionBarUpButton:SetPoint("CENTER", MainMenuBarArtFrame, "TOPLEFT", 521, -23)
		ActionBarDownButton:SetPoint("CENTER", MainMenuBarArtFrame, "TOPLEFT", 521, -42)
		MainMenuBarPageNumber:SetPoint("CENTER", MainMenuBarArtFrame, 29, -5)

		-- reposition ALL actionbars (right bars not affected)
		MainMenuBar:SetPoint("BOTTOM", UIParent, 237, 11)

		-- Update XP/Rep bar sizes via the unified function
		if BFAUI_SetBarWidth then
			BFAUI_SetBarWidth(542, -237)
		end
	end
end

local function Update_ActionBars()
	if not InCombatLockdown() then
		-- Bottom Left Bar:
		if MultiBarBottomLeft:IsShown() then
			PetActionButton1:SetPoint("TOP", PetActionBarFrame, "LEFT", 51, 4)
			StanceButton1:SetPoint("LEFT", StanceBarFrame, 2, -4)
		else
			PetActionButton1:SetPoint("TOP", PetActionBarFrame, "LEFT", 51, 7)
			StanceButton1:SetPoint("LEFT", StanceBarFrame, 12, -2)
		end
	end

	-- Bottom Right Bar: (needs to be run in or out of combat, this is for the art when exiting vehicles in combat)
	if MultiBarBottomRight:IsShown() == true then
		ActivateLongBar()
	else
		ActivateShortBar()
	end
end

MultiBarBottomLeft:HookScript("OnShow", Update_ActionBars)
MultiBarBottomLeft:HookScript("OnHide", Update_ActionBars)
MultiBarBottomRight:HookScript("OnShow", Update_ActionBars)
MultiBarBottomRight:HookScript("OnHide", Update_ActionBars)
MultiBarRight:HookScript("OnShow", Update_ActionBars)
MultiBarRight:HookScript("OnHide", Update_ActionBars)
MultiBarLeft:HookScript("OnShow", Update_ActionBars)
MultiBarLeft:HookScript("OnHide", Update_ActionBars)

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN") -- Required to check bar visibility on load
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", Update_ActionBars)




-- local function PlayerEnteredCombat()
-- 	InterfaceOptionsActionBarsPanelTitle:SetText("ActionBars - |cffFF0000You must leave combat to toggle the ActionBars")
-- 	InterfaceOptionsActionBarsPanelBottomLeft:Disable()
-- 	InterfaceOptionsActionBarsPanelBottomRight:Disable()
-- 	InterfaceOptionsActionBarsPanelRight:Disable()
-- 	InterfaceOptionsActionBarsPanelRightTwo:Disable()
-- end

-- local f = CreateFrame("Frame")
-- f:RegisterEvent("PLAYER_REGEN_DISABLED")
-- f:SetScript("OnEvent", PlayerEnteredCombat)

-- local function PlayerLeftCombat()
-- 	InterfaceOptionsActionBarsPanelTitle:SetText("ActionBars")
-- 	InterfaceOptionsActionBarsPanelBottomLeft:Enable()
-- 	InterfaceOptionsActionBarsPanelBottomRight:Enable()
-- 	InterfaceOptionsActionBarsPanelRight:Enable()
-- 	InterfaceOptionsActionBarsPanelRightTwo:Enable()
-- 	Initial_ActionBarPositioning()
-- 	Update_ActionBars()
-- end

-- local f = CreateFrame("Frame")
-- f:RegisterEvent("PLAYER_REGEN_ENABLED")
-- f:SetScript("OnEvent", PlayerLeftCombat)

--------------------------------==≡≡[ BAG SPACE ]≡≡==--------------------------------

local BagSpaceDisplay = CreateFrame("Frame", "BagSpaceDisplay", MainMenuBarBackpackButton)

BagSpaceDisplay:ClearAllPoints()
BagSpaceDisplay:SetPoint("BOTTOM", MainMenuBarBackpackButton, 0, -8)
BagSpaceDisplay:SetSize(MainMenuBarBackpackButton:GetWidth(), MainMenuBarBackpackButton:GetHeight())

BagSpaceDisplay.text = BagSpaceDisplay:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
BagSpaceDisplay.text:SetAllPoints(BagSpaceDisplay)

local function UpdateBagSpace()
	local totalFree, freeSlots, bagFamily = 0
	for i = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		freeSlots, bagFamily = C_Container.GetContainerNumFreeSlots(i)
		if bagFamily == 0 then
			totalFree = totalFree + freeSlots
		end
	end

	BagSpaceDisplay.text:SetText(string.format("(%s)", totalFree))
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("BAG_UPDATE")
f:SetScript("OnEvent", UpdateBagSpace)

----------------------------==≡≡[ BLIZZARD TEXTURES ]≡≡==----------------------------

for i = 0, 3 do -- for loop, hides MainMenuBarTexture (0-3)
	_G["MainMenuBarTexture" .. i]:Hide()
end

-------------------------------==≡≡[ RECYCLE BIN ]≡≡==-------------------------------

--[[
t = {
	"PlayerFrameTexture",
	"TargetFrameTextureFrameTexture",
	-- "MinimapBorder",
	-- "MinimapBorderTop",
	"ExhaustionTickNormal",
	"MicroMenuArtTexture",
}

for _, v in ipairs(t) do
	_G[v]:SetVertexColor(0.4, 0.4, 0.4)
end

-- local TimeBorder = TimeManagerClockButton:GetRegions()
-- TimeBorder:SetVertexColor(0.3, 0.3, 0.3)
--]]