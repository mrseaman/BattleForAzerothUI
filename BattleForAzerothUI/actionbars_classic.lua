-- BattleForAzerothUI/actionbars_classic.lua
-- Main action bar, MultiBarBottomLeft/Right, pet bar, and stance bar positioning.
-- Classic Era (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) only.
-- Depends on ActionBarArt / ActionBarArtSmall defined in artFrames.xml.
-- Depends on BFAUI_SetBarWidth defined in xpbar_classic.lua.
local WOW_CLASSIC_ERA = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
if not WOW_CLASSIC_ERA then return end

-- Run once on PLAYER_LOGIN to initiate bottomleft, bottomright, pet and stance bar positions.
local function InitializeBars()
	if not InCombatLockdown() then

		-- reposition buttons on MultiBarBottomLeft (Note: 2026/03/03)
		-- MultiBarBottomLeft SetPoint() to {'BOTTOMLEFT', 'ActionButton1', 'TOPLEFT', 0, 17}
		-- every time when warrior switch stances, which causes the pet bar to be misaligned. 
		-- reposition the buttons solves the issue.
		MultiBarBottomLeftButton1:SetPoint("BOTTOMLEFT", MultiBarBottomLeft, 0, -6)

		-- reposition bottom right actionbar
		MultiBarBottomRight:SetPoint("LEFT", MultiBarBottomLeft, "RIGHT", 43, -6)

		-- reposition second half of top right bar, underneath
		MultiBarBottomRightButton7:SetPoint("LEFT", MultiBarBottomRight, 0, -48)
		if PetActionBarFrame then
			PetActionBarFrame:ClearAllPoints()
			PetActionBarFrame:SetPoint("TOPLEFT", MultiBarBottomLeft, "BOTTOMLEFT", 0, 3)
		end
		if SlidingActionBarTexture0 then
			SlidingActionBarTexture0:SetPoint("TOPLEFT", PetActionBarFrame, 1, -5)
		end
		if PetActionButton1 then
			PetActionButton1:ClearAllPoints()
			PetActionButton1:SetPoint("TOP", PetActionBarFrame, "LEFT", 51, 4)
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
f:SetScript("OnEvent", InitializeBars)

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

	
	if ActionBarUpButton then ActionBarUpButton:SetPoint("CENTER", MainMenuBarArtFrame, "TOPLEFT", 522, -23) end
	if ActionBarDownButton then ActionBarDownButton:SetPoint("CENTER", MainMenuBarArtFrame, "TOPLEFT", 522, -42) end
	if MainMenuBarPageNumber then MainMenuBarPageNumber:SetPoint("CENTER", MainMenuBarArtFrame, 26, -5) end

	MainMenuBar:SetPoint("BOTTOM", UIParent, 110, 11)

	-- Classic Era: button 7 anchor uses the bar frame as reference
	MultiBarBottomRightButton7:ClearAllPoints()
	MultiBarBottomRightButton7:SetPoint("LEFT", MultiBarBottomRight, "LEFT", 0, -48)

	if BFAUI_SetBarWidth then
		BFAUI_SetBarWidth(798, -111)
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
		if ActionBarUpButton then ActionBarUpButton:SetPoint("CENTER", MainMenuBarArtFrame, "TOPLEFT", 521, -23) end
		if ActionBarDownButton then ActionBarDownButton:SetPoint("CENTER", MainMenuBarArtFrame, "TOPLEFT", 521, -42) end
		if MainMenuBarPageNumber then MainMenuBarPageNumber:SetPoint("CENTER", MainMenuBarArtFrame, 27, -5) end

		MainMenuBar:SetPoint("BOTTOM", UIParent, 237, 11)

		if BFAUI_SetBarWidth then
			BFAUI_SetBarWidth(542, -237)
		end
	end
end

local function Update_ActionBars()
	if not InCombatLockdown() then
		if PetActionBarFrame then
			PetActionBarFrame:ClearAllPoints()
			PetActionBarFrame:SetPoint("TOPLEFT", MultiBarBottomLeft, "BOTTOMLEFT", 0, 3)
		end

		if MultiBarBottomLeft:IsShown() then
			if PetActionButton1 then PetActionButton1:ClearAllPoints() PetActionButton1:SetPoint("TOP", PetActionBarFrame, "LEFT", 51, 4) end
			if StanceButton1 then StanceButton1:ClearAllPoints() StanceButton1:SetPoint("LEFT", StanceBarFrame, 2, -4) end
		else
			if PetActionButton1 then PetActionButton1:ClearAllPoints() PetActionButton1:SetPoint("TOP", PetActionBarFrame, "LEFT", 51, 7) end
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
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", Update_ActionBars)
