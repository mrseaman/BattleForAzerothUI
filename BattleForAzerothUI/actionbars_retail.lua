-- BattleForAzerothUI/actionbars_retail.lua
-- Main action bar, MultiBarBottomLeft/Right, pet bar, and stance bar positioning.
-- Retail engine clients only. Not loaded on Classic Era.
-- Depends on ActionBarArt / ActionBarArtSmall defined in artFrames.xml.
-- Depends on BFAUI_SetBarWidth defined in xpbar_retail.lua.
if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then return end

-- Run once on PLAYER_LOGIN to set initial pet and stance bar positions.
-- Runs before Edit Mode applies PLAYER_ENTERING_WORLD positions, so no deferral needed.
local function Initial_ActionBarPositioning()
	if not InCombatLockdown() then
		-- On the retail engine the pet bar does not auto-follow MainMenuBar; anchor it explicitly.
		if PetActionBar then
			PetActionBar:ClearAllPoints()
			PetActionBar:SetPoint("TOPLEFT", MultiBarBottomLeft, "BOTTOMLEFT", 0, 3)
		end
		if SlidingActionBarTexture0 then
			SlidingActionBarTexture0:SetPoint("TOPLEFT", PetActionBar, 1, -5)
		end
		if PetActionButton1 then
			PetActionButton1:ClearAllPoints()
			PetActionButton1:SetPoint("TOP", PetActionBar, "LEFT", 51, 4)
		end

		if StanceBarLeft then
			StanceBarLeft:SetPoint("BOTTOMLEFT", StanceBarFrame, 0, -5)
		end
		if StanceButton1 then
			StanceButton1:ClearAllPoints()
			StanceButton1:SetPoint("LEFT", StanceBarFrame, 2, -4)
		end
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
		MainMenuBar:SetPoint("BOTTOM", UIParent, 110, 11)

		MultiBarBottomLeft:ClearAllPoints()
		MultiBarBottomLeft:SetPoint("BOTTOMLEFT", MainMenuBar, "TOPLEFT", 8, 0)
		MultiBarBottomRight:ClearAllPoints()
		MultiBarBottomRight:SetPoint("LEFT", MultiBarBottomLeft, "RIGHT", 42, 0)

		-- Retail engine: anchor button 7 below button 1 to create 2 rows of 6
		MultiBarBottomRightButton7:ClearAllPoints()
		MultiBarBottomRightButton7:SetPoint("TOPLEFT", MultiBarBottomRightButton1, "BOTTOMLEFT", 0, -2)

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
		MainMenuBar:SetPoint("BOTTOM", UIParent, 237, 11)

		MultiBarBottomLeft:ClearAllPoints()
		MultiBarBottomLeft:SetPoint("BOTTOMLEFT", MainMenuBar, "TOPLEFT", 8, 0)

		if BFAUI_SetBarWidth then
			BFAUI_SetBarWidth(542, -237)
		end
	end
end

local function Update_ActionBars()
	if not InCombatLockdown() then

		if PetActionBar then
			PetActionBar:ClearAllPoints()
			PetActionBar:SetPoint("TOPLEFT", MultiBarBottomLeft, "BOTTOMLEFT", 0, 3)
		end

		if MultiBarBottomLeft:IsShown() then
			if PetActionButton1 then PetActionButton1:ClearAllPoints() PetActionButton1:SetPoint("TOP", PetActionBar, "LEFT", 51, 4) end
			if StanceButton1 then StanceButton1:ClearAllPoints() StanceButton1:SetPoint("LEFT", StanceBarFrame, 2, -4) end
		else
			if PetActionButton1 then PetActionButton1:ClearAllPoints() PetActionButton1:SetPoint("TOP", PetActionBar, "LEFT", 51, 7) end
			if StanceButton1 then StanceButton1:ClearAllPoints() StanceButton1:SetPoint("LEFT", StanceBarFrame, 12, -2) end
		end
	end

	if MultiBarBottomRight:IsShown() then
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
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", Update_ActionBars)

-- Re-apply action bar positioning after Edit Mode (retail engine).
-- Edit Mode applies its saved layout synchronously on PLAYER_ENTERING_WORLD;
-- C_Timer.After(0) defers our override to the next frame, after all handlers finish.
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
	C_Timer.After(0, Update_ActionBars)
end)
