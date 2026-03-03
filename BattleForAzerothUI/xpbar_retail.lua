-- BattleForAzerothUI/xpbar_retail.lua
-- XP bar and reputation bar: positioning, display logic, and text overlays.
-- Retail engine clients only. Not loaded on Classic Era.
-- Depends on XPBarBackground defined in artFrames.xml.
if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then return end

-- Retail engine uses C_Reputation.GetWatchedFactionData() which
-- returns a table with name, currentReactionThreshold, nextReactionThreshold,
-- currentStanding fields.
local function GetWatchedFaction()
	if C_Reputation and C_Reputation.GetWatchedFactionData then
		return C_Reputation.GetWatchedFactionData()
	end
	-- Fallback for any engine that still exposes the old multi-return API
	if GetWatchedFactionInfo then
		local name, reaction, minRep, maxRep, currentRep = GetWatchedFactionInfo()
		if not name then return nil end
		return {
			name = name,
			reaction = reaction,
			currentReactionThreshold = minRep,
			nextReactionThreshold = maxRep,
			currentStanding = currentRep,
		}
	end
end

-- Hide default XP bar textures
for i = 0, 3 do
	local tex = _G["MainMenuXPBarTexture" .. i]
	if tex then tex:Hide() end
end

-- Hide default reputation bar textures
for i = 0, 3 do
	local tex = _G["ReputationWatchBarTexture" .. i]
	if tex then tex:Hide() end
end

if MainMenuExpBar then MainMenuExpBar:SetFrameStrata("MEDIUM") end
if ExhaustionTick then ExhaustionTick:SetFrameStrata("HIGH") end

if MainMenuBarExpText then
	MainMenuBarExpText:ClearAllPoints()
	MainMenuBarExpText:SetPoint("CENTER", MainMenuExpBar, 0, 0)
end
if MainMenuBarOverlayFrame then MainMenuBarOverlayFrame:SetFrameStrata("HIGH") end

if ReputationWatchBar then
	ReputationWatchBar:SetFrameStrata("MEDIUM")
end

-- Constants
local MAX_LEVEL      = GetMaxPlayerLevel and GetMaxPlayerLevel() or 70
local FULL_BAR_HEIGHT = 10
local HALF_BAR_HEIGHT = 5

-- Track current bar width; updated by BFAUI_SetBarWidth (called from actionbars_retail.lua)
local currentBarWidth  = 798
local currentBarOffset = -111

-- Custom background for the reputation bar
local RepBarBackground = CreateFrame("Frame", "RepBarBackground", MainMenuBar)
RepBarBackground:SetFrameStrata("LOW")
RepBarBackground:SetSize(798, 10)
local repBgTexture = RepBarBackground:CreateTexture(nil, "BACKGROUND")
repBgTexture:SetAllPoints()
repBgTexture:SetTexture("Interface/ChatFrame/ChatFrameBackground")
repBgTexture:SetVertexColor(0, 0, 0, 0.75)
RepBarBackground:Hide()

-- Helper: hide all default reputation bar decorations
local function HideReputationBarDecorations()
	if not ReputationWatchBar then return end

	local statusBar = ReputationWatchBar.StatusBar
	if not statusBar and ReputationWatchBar.GetStatusBar then
		statusBar = ReputationWatchBar:GetStatusBar()
	end
	if not statusBar then
		statusBar = _G["ReputationWatchStatusBar"]
	end

	for i = 0, 3 do
		local tex = _G["ReputationWatchBarTexture" .. i]
		if tex then tex:Hide() end
	end

	if ReputationWatchBar.OverlayFrame then
		ReputationWatchBar.OverlayFrame:Hide()
	end

	local framesToCheck = {
		"ReputationWatchBarOverlayFrame",
		"ReputationWatchBarTick",
		"ReputationWatchStatusBarOverlayFrame",
		"ReputationWatchStatusBarBackground",
	}
	for _, name in ipairs(framesToCheck) do
		local frame = _G[name]
		if frame then
			if frame.OverlayFrame then frame.OverlayFrame:Hide() end
			frame:Hide()
		end
	end

	local repStatusBar = _G["ReputationWatchStatusBar"]
	if repStatusBar then
		if repStatusBar.OverlayFrame then repStatusBar.OverlayFrame:Hide() end
		for _, child in pairs({repStatusBar:GetChildren()}) do
			child:Hide()
		end
	end

	for _, child in pairs({ReputationWatchBar:GetChildren()}) do
		if child ~= statusBar then child:Hide() end
	end

	for _, region in pairs({ReputationWatchBar:GetRegions()}) do
		if region:GetObjectType() == "Texture" then region:Hide() end
	end

	if statusBar then
		if statusBar.OverlayFrame then statusBar.OverlayFrame:Hide() end
		for _, child in pairs({statusBar:GetChildren()}) do child:Hide() end
		for _, region in pairs({statusBar:GetRegions()}) do
			if region:GetObjectType() == "Texture" then
				if region:GetDrawLayer() ~= "BACKGROUND" then region:Hide() end
			end
		end
	end
end

-- Custom overlay frame for reputation bar mouseover text
local RepBarOverlayFrame = CreateFrame("Frame", "BFARepBarOverlayFrame", UIParent)
RepBarOverlayFrame:SetFrameStrata("HIGH")
RepBarOverlayFrame:EnableMouse(true)
RepBarOverlayFrame:Hide()

local RepBarText = RepBarOverlayFrame:CreateFontString("BFARepBarText", "OVERLAY", "TextStatusBarText")
RepBarText:SetPoint("CENTER", RepBarOverlayFrame, "CENTER", 0, 0)
RepBarText:SetAlpha(0)

local function UpdateRepBarText()
	local data = GetWatchedFaction()
	if data then
		local repValue = data.currentStanding - data.currentReactionThreshold
		local repMax   = data.nextReactionThreshold - data.currentReactionThreshold
		RepBarText:SetText(string.format("%s: %d / %d", data.name, repValue, repMax))
	else
		RepBarText:SetText("")
	end
end

RepBarOverlayFrame:SetScript("OnEnter", function() RepBarText:SetAlpha(1) end)
RepBarOverlayFrame:SetScript("OnLeave", function() RepBarText:SetAlpha(0) end)

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

-- Helper: resize reputation bar and its StatusBar child
local function SetReputationBarSize(width, height)
	if not ReputationWatchBar then return end

	ReputationWatchBar:SetSize(width, height)

	local statusBar = ReputationWatchBar.StatusBar
	if not statusBar and ReputationWatchBar.GetStatusBar then
		statusBar = ReputationWatchBar:GetStatusBar()
	end
	if not statusBar then
		statusBar = _G["ReputationWatchStatusBar"]
	end

	if statusBar then
		statusBar:SetSize(width, height)
		statusBar:ClearAllPoints()
		statusBar:SetAllPoints(ReputationWatchBar)
	end

	HideReputationBarDecorations()
end

-- Main display update: positions and sizes XP/rep bars based on level and watched faction
local function UpdateBarsDisplay()
	local playerLevel    = UnitLevel("player")
	local isMaxLevel     = playerLevel >= MAX_LEVEL
	local hasWatchedFaction = GetWatchedFaction() ~= nil

	if isMaxLevel then
		if MainMenuExpBar then MainMenuExpBar:Hide() end
		XPBarBackground:Hide()

		if hasWatchedFaction and ReputationWatchBar then
			ReputationWatchBar:ClearAllPoints()
			ReputationWatchBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
			SetReputationBarSize(currentBarWidth, FULL_BAR_HEIGHT)
			ReputationWatchBar:Show()

			RepBarBackground:ClearAllPoints()
			RepBarBackground:SetPoint("BOTTOM", MainMenuBar, currentBarOffset, -11)
			RepBarBackground:SetSize(currentBarWidth, FULL_BAR_HEIGHT)
			RepBarBackground:Show()
		else
			if ReputationWatchBar then ReputationWatchBar:Hide() end
			RepBarBackground:Hide()
		end
	else
		if hasWatchedFaction and ReputationWatchBar then
			if MainMenuExpBar then
				MainMenuExpBar:ClearAllPoints()
				MainMenuExpBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, HALF_BAR_HEIGHT)
				MainMenuExpBar:SetSize(currentBarWidth, HALF_BAR_HEIGHT)
				MainMenuExpBar:Show()
			end

			XPBarBackground:ClearAllPoints()
			XPBarBackground:SetPoint("BOTTOM", MainMenuBar, currentBarOffset, -11 + HALF_BAR_HEIGHT)
			XPBarBackground:SetSize(currentBarWidth, HALF_BAR_HEIGHT)
			XPBarBackground:Show()

			ReputationWatchBar:ClearAllPoints()
			ReputationWatchBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
			SetReputationBarSize(currentBarWidth, HALF_BAR_HEIGHT)
			ReputationWatchBar:Show()

			RepBarBackground:ClearAllPoints()
			RepBarBackground:SetPoint("BOTTOM", MainMenuBar, currentBarOffset, -11)
			RepBarBackground:SetSize(currentBarWidth, HALF_BAR_HEIGHT)
			RepBarBackground:Show()
		else
			if MainMenuExpBar then
				MainMenuExpBar:ClearAllPoints()
				MainMenuExpBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
				MainMenuExpBar:SetSize(currentBarWidth, FULL_BAR_HEIGHT)
				MainMenuExpBar:Show()
			end

			XPBarBackground:ClearAllPoints()
			XPBarBackground:SetPoint("BOTTOM", MainMenuBar, currentBarOffset, -11)
			XPBarBackground:SetSize(currentBarWidth, FULL_BAR_HEIGHT)
			XPBarBackground:Show()

			if ReputationWatchBar then ReputationWatchBar:Hide() end
			RepBarBackground:Hide()
		end
	end

	UpdateRepBarOverlay()
end

-- Called by actionbars_retail.lua when the active bar layout changes width
local function SetBarWidth(width, offset)
	currentBarWidth  = width
	currentBarOffset = offset
	UpdateBarsDisplay()
end
BFAUI_SetBarWidth = SetBarWidth

local xpBarFrame = CreateFrame("Frame")
xpBarFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
xpBarFrame:RegisterEvent("PLAYER_LEVEL_UP")
xpBarFrame:RegisterEvent("UPDATE_FACTION")
xpBarFrame:SetScript("OnEvent", UpdateBarsDisplay)

-- Hook Blizzard's XP bar update function if present (may not exist on retail engine)
if MainMenuBar_UpdateExperienceBars then
	hooksecurefunc("MainMenuBar_UpdateExperienceBars", function()
		C_Timer.After(0.01, UpdateBarsDisplay)
	end)
end

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
	HideReputationBarDecorations()
end
