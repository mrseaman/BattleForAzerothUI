-- BattleForAzerothUI/micromenu_classic.lua
-- Micro menu button repositioning, latency bar scaling, and bag slot layout.
-- Classic Era (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) only.
-- Depends on MicroMenuArt defined in artFrames.xml.
if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then return end

local function MoveMicroButtonsToBottomRight()
	-- Artwork
	MicroMenuArt:Show()
	MicroMenuArt:SetFrameStrata("BACKGROUND")

	-- MicroMenu Buttons
	for i = 1, #MICRO_BUTTONS-1 do
		local button, previousButton = _G[MICRO_BUTTONS[i]], _G[MICRO_BUTTONS[i-1]]
		if button == GuildMicroButton then button = HelpMicroButton end -- skip GuildMicroButton which is hidden in BFAUI
		if previousButton == GuildMicroButton then previousButton = HelpMicroButton end

		button:ClearAllPoints()

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
	MainMenuBarBackpackButton:ClearAllPoints()
	MainMenuBarBackpackButton:SetPoint("BOTTOMRIGHT", UIParent, -5, 47)
	MainMenuBarBackpackButton:SetScale(1)
	MainMenuBarBackpackButton:SetFrameStrata("HIGH")
	for i = 0, 3 do
		local bagFrame, previousBag = _G["CharacterBag" .. i .. "Slot"], _G["CharacterBag" .. i-1 .. "Slot"]

		bagFrame:SetScale(0.75)
		bagFrame:ClearAllPoints()
		bagFrame:SetFrameStrata("HIGH")

		if i == 0 then
			bagFrame:SetPoint("BOTTOMRIGHT", MainMenuBarBackpackButton, "BOTTOMLEFT", -9, 1)
		else
			bagFrame:SetPoint("BOTTOMRIGHT", previousBag, "BOTTOMLEFT", -6, 0)
		end
	end
end

-- Classic Era: no Edit Mode, so hooks can fire immediately without taint concerns.
local function MoveMicroButtons_Hook(...)
	MoveMicroButtonsToBottomRight()
end
if MoveMicroButtons then hooksecurefunc("MoveMicroButtons", MoveMicroButtons_Hook) end
if UpdateMicroButtons then hooksecurefunc("UpdateMicroButtons", MoveMicroButtons_Hook) end
if MainMenuBarVehicleLeaveButton_Update then
	hooksecurefunc("MainMenuBarVehicleLeaveButton_Update", MoveMicroButtons_Hook)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", MoveMicroButtonsToBottomRight)
