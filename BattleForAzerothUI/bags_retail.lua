-- BattleForAzerothUI/bags_retail.lua
-- Bag space indicator: shows free slot count on the backpack button.
-- Modern retail / Midnight only (WOW_PROJECT_MAINLINE, interface 120005).
-- The TBC Anniversary 20505 path is bags_anniversary.lua; Classic Era is bags_classic.lua.
if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

-- MainMenuBarBackpackButton, C_Container, BACKPACK_CONTAINER and NUM_BAG_SLOTS all
-- still exist on Midnight 12.0 (verified on a 120005 client), so this mirrors the
-- proven Classic/Anniversary logic unchanged.
local BagSpaceDisplay = CreateFrame("Frame", "BagSpaceDisplay", MainMenuBarBackpackButton)
BagSpaceDisplay:ClearAllPoints()
BagSpaceDisplay:SetPoint("BOTTOM", MainMenuBarBackpackButton, 0, -8)
BagSpaceDisplay:SetSize(MainMenuBarBackpackButton:GetWidth(), MainMenuBarBackpackButton:GetHeight())

BagSpaceDisplay.text = BagSpaceDisplay:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
BagSpaceDisplay.text:SetAllPoints(BagSpaceDisplay)

local function UpdateBagSpace()
	local totalFree = 0
	for i = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		local freeSlots, bagFamily = C_Container.GetContainerNumFreeSlots(i)
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
