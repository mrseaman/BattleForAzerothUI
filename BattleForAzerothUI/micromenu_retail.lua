-- BattleForAzerothUI/micromenu_retail.lua
-- Micro menu button repositioning, latency bar scaling, and bag slot layout.
-- Retail engine clients only. Not loaded on Classic Era.
-- Depends on MicroMenuArt defined in artFrames.xml.
if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then return end

local BFA_Manager = CreateFrame("Frame")
BFA_Manager:RegisterEvent("PLAYER_LOGIN")
BFA_Manager:RegisterEvent("PLAYER_ENTERING_WORLD")
BFA_Manager:RegisterEvent("PLAYER_REGEN_ENABLED") -- To apply changes after combat ends
BFA_Manager:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED") -- Core event for Retail positioning

local function UpdateMicroMenu()
	if InCombatLockdown() or isUpdating then return end
    isUpdating = true -- Lock the function
	-- Artwork
	MicroMenuArt:Show()
	MicroMenuArt:SetFrameStrata("BACKGROUND")

	-- MicroMenu Buttons
	
	-- for i = 1, #MICRO_BUTTONS-1 do
	-- 	local button, previousButton = _G[MICRO_BUTTONS[i]], _G[MICRO_BUTTONS[i-1]]
	-- 	if button == SocialsMicroButton then button = HelpMicroButton end -- skip GuildMicroButton which is hidden in BFAUI
	-- 	if previousButton == SocialsMicroButton then previousButton = HelpMicroButton end

	-- 	button:ClearAllPoints()

	-- 	if i == 1 then
	-- 		button:SetPoint("BOTTOMRIGHT", UIParent, -198, 4)
	-- 	else
	-- 		button:SetPoint("BOTTOMRIGHT", previousButton, 28, 0)
	-- 	end
	-- end

	MicroMenuContainer:ClearAllPoints()
	MicroMenuContainer:SetPoint("BOTTOMRIGHT", UIParent, 0, 0)

	-- Latency Bar
	MainMenuBarPerformanceBarFrame:SetFrameStrata("HIGH")
	MainMenuBarPerformanceBarFrame:SetScale((HelpMicroButton:GetWidth() / MainMenuBarPerformanceBarFrame:GetWidth()) * (1 / 3))

	MainMenuBarPerformanceBar:SetRotation(math.pi * 0.5)
	MainMenuBarPerformanceBar:ClearAllPoints()
	MainMenuBarPerformanceBar:SetPoint("BOTTOM", HelpMicroButton, -1, -24)

	MainMenuBarPerformanceBarFrameButton:ClearAllPoints()
	MainMenuBarPerformanceBarFrameButton:SetPoint("BOTTOMLEFT", MainMenuBarPerformanceBar, -(MainMenuBarPerformanceBar:GetWidth() / 2), 0)
	MainMenuBarPerformanceBarFrameButton:SetPoint("TOPRIGHT", MainMenuBarPerformanceBar, MainMenuBarPerformanceBar:GetWidth() / 2, -28)

	isUpdating = false
end

local function UpdateBagSlots()
    if InCombatLockdown() or isUpdating then return end
    isUpdating = true

    for i = 0, 3 do
        local bagFrame = _G["CharacterBag" .. i .. "Slot"]
        local previousBag = _G["CharacterBag" .. i-1 .. "Slot"]

        if bagFrame then
            bagFrame:SetScale(0.75)
            bagFrame:ClearAllPoints()
            bagFrame:SetFrameStrata("HIGH")

            -- Anchor the first bag to the Backpack, then chain the rest
            if i == 0 then
                bagFrame:SetPoint("BOTTOMRIGHT", MainMenuBarBackpackButton, "BOTTOMLEFT", -9, 1)
            elseif previousBag then
                bagFrame:SetPoint("BOTTOMRIGHT", previousBag, "BOTTOMLEFT", -6, 0)
            end
        end
    end

    if KeyRingButton then
        KeyRingButton:SetScale(0.9)
    end

    isUpdating = false
end

local function UpdateBagsBar()
	if InCombatLockdown() or isUpdating then return end
    isUpdating = true -- Lock the function

	BagsBar:ClearAllPoints()
	BagsBar:SetPoint("BOTTOMRIGHT", UIParent, -6, 42)
	MainMenuBarBackpackButton:SetScale(1)
	MainMenuBarBackpackButton:SetFrameStrata("HIGH")
	
	UpdateBagSlots()

	isUpdating = false
end

hooksecurefunc(MicroMenuContainer, "SetPoint", UpdateMicroMenu)
hooksecurefunc(BagsBar, "SetPoint", UpdateBagsBar)

for i = 0, 3 do
    local bagFrame = _G["CharacterBag"..i.."Slot"]
    if bagFrame then
        hooksecurefunc(bagFrame, "SetPoint", UpdateBagSlots)
    end
end

isUpdating = false -- Global flag to prevent recursive updates

BFA_Manager:SetScript("OnEvent", function(self, event, ...)
	UpdateMicroMenu()
	UpdateBagsBar()
end)
