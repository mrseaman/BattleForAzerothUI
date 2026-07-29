-- BattleForAzerothUI/micromenu_retail.lua
-- Micro menu repositioning and bag slot layout.
-- Modern retail / Midnight only (WOW_PROJECT_MAINLINE, interface 120005).
-- The TBC Anniversary 20505 path is micromenu_anniversary.lua.
-- Depends on MicroMenuArt defined in artFrames.xml.
--
-- Midnight graph (verified on a live 120005 client):
--   MicroMenuContainer (UIParent child) > {MicroMenu (the buttons), QueueStatusButton}
--   BagsBar (UIParent child) > {MainMenuBarBackpackButton, CharacterBag0-3Slot,
--                               CharacterReagentBag0Slot, BagBarExpandToggle}
-- The legacy latency/performance bar (MainMenuBarPerformanceBar*) was removed in
-- 12.0, so that feature from the Anniversary path is intentionally dropped here.
if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

local isUpdating = false

-- Midnight shows 12 micro buttons (the classic BfA art was drawn for fewer), so the
-- 329px row overflows the 512px MicroMenuArt. Scale the container down so the row
-- fits within the art. Tune this if the buttons don't sit cleanly over the slots.
local MICRO_TARGET_WIDTH = 290

local function UpdateMicroMenu()
	if InCombatLockdown() or isUpdating then return end
	isUpdating = true

	if MicroMenuArt then
		MicroMenuArt:Show()
		MicroMenuArt:SetFrameStrata("BACKGROUND")
	end

	if MicroMenu and MicroMenu:GetWidth() and MicroMenu:GetWidth() > 0 and MicroMenuContainer then
		MicroMenuContainer:SetScale(math.min(1, MICRO_TARGET_WIDTH / MicroMenu:GetWidth()))
	end

	if MicroMenuContainer then
		MicroMenuContainer:ClearAllPoints()
		MicroMenuContainer:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
	end

	isUpdating = false
end

local function UpdateBagSlots()
	if InCombatLockdown() or isUpdating then return end
	isUpdating = true

	local prev
	for i = 0, 3 do
		local bag = _G["CharacterBag" .. i .. "Slot"]
		if bag then
			bag:SetScale(0.75)
			bag:SetFrameStrata("HIGH")
			bag:ClearAllPoints()
			if i == 0 and MainMenuBarBackpackButton then
				bag:SetPoint("BOTTOMRIGHT", MainMenuBarBackpackButton, "BOTTOMLEFT", -9, 1)
			elseif prev then
				bag:SetPoint("BOTTOMRIGHT", prev, "BOTTOMLEFT", -6, 0)
			end
			prev = bag
		end
	end

	-- Reagent bag is new since the original BfA layout; chain it on so it does
	-- not float at its default Edit Mode position.
	local reagent = _G["CharacterReagentBag0Slot"]
	if reagent and prev then
		reagent:SetScale(0.75)
		reagent:SetFrameStrata("HIGH")
		reagent:ClearAllPoints()
		reagent:SetPoint("BOTTOMRIGHT", prev, "BOTTOMLEFT", -6, 0)
	end

	isUpdating = false
end

-- Midnight (12.0) restyled the backpack into a round icon via a CircleMask + the
-- 'bag-main' atlas. Restore the classic square look: drop the mask off the icon and
-- swap the frame for the square action-bar icon frame used by the action buttons.
local function SquareBackpack()
	local bp = MainMenuBarBackpackButton
	if not bp then return end

	if bp.CircleMask then
		if bp.icon and bp.icon.RemoveMaskTexture then bp.icon:RemoveMaskTexture(bp.CircleMask) end
		local masked = bp:GetNormalTexture()
		if masked and masked.RemoveMaskTexture then masked:RemoveMaskTexture(bp.CircleMask) end
		bp.CircleMask:Hide()
	end

	local nt = bp:GetNormalTexture()
	if nt then nt:SetAtlas("UI-HUD-ActionBar-IconFrame", false) end
	for _, r in ipairs({ bp:GetRegions() }) do
		if r ~= nt and r.GetAtlas and r:GetAtlas() == "bag-main" then r:Hide() end
	end
	if bp.SetHighlightAtlas then bp:SetHighlightAtlas("UI-HUD-ActionBar-IconFrame-Mouseover", false) end
end

local function UpdateBagsBar()
	if InCombatLockdown() or isUpdating then return end
	isUpdating = true

	if BagsBar then
		BagsBar:ClearAllPoints()
		BagsBar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -6, 42)
	end
	if MainMenuBarBackpackButton then
		MainMenuBarBackpackButton:SetScale(1)
		MainMenuBarBackpackButton:SetFrameStrata("HIGH")
	end
	SquareBackpack()

	isUpdating = false
	UpdateBagSlots()
end

-- Reapply whenever the engine / Edit Mode moves these frames back.
if MicroMenuContainer then
	hooksecurefunc(MicroMenuContainer, "SetPoint", function()
		if not isUpdating then UpdateMicroMenu() end
	end)
end
if BagsBar then
	hooksecurefunc(BagsBar, "SetPoint", function()
		if not isUpdating then UpdateBagsBar() end
	end)
end
for i = 0, 3 do
	local bag = _G["CharacterBag" .. i .. "Slot"]
	if bag then
		hooksecurefunc(bag, "SetPoint", function()
			if not isUpdating then UpdateBagSlots() end
		end)
	end
end

local BFA_Manager = CreateFrame("Frame")
BFA_Manager:RegisterEvent("PLAYER_LOGIN")
BFA_Manager:RegisterEvent("PLAYER_ENTERING_WORLD")
BFA_Manager:RegisterEvent("PLAYER_REGEN_ENABLED")
BFA_Manager:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
BFA_Manager:SetScript("OnEvent", function()
	C_Timer.After(0, function()
		UpdateMicroMenu()
		UpdateBagsBar()
	end)
end)
