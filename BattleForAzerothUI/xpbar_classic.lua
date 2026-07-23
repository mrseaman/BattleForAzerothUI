-- BattleForAzerothUI/xpbar_classic.lua
-- XP bar and reputation bar: repositioning and resizing.
-- Classic Era (WOW_PROJECT_CLASSIC) and TBC Classic Anniversary
-- (WOW_PROJECT_BURNING_CRUSADE_CLASSIC). NOT modern retail / Midnight.
if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC and WOW_PROJECT_ID ~= WOW_PROJECT_BURNING_CRUSADE_CLASSIC then return end

local BFA_Manager = CreateFrame("Frame")
BFA_Manager:RegisterEvent("PLAYER_LOGIN")
BFA_Manager:RegisterEvent("PLAYER_ENTERING_WORLD")
BFA_Manager:RegisterEvent("PLAYER_REGEN_ENABLED")
BFA_Manager:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")

local isUpdating = false
local barWidth = 798
local barOffset = -111

local function UpdateStatusBars()
    if isUpdating or InCombatLockdown() then return end
    if not StatusTrackingBarManager then return end

    isUpdating = true

    StatusTrackingBarManager:ClearAllPoints()
    StatusTrackingBarManager:SetPoint("BOTTOM", MainMenuBar, "BOTTOM", barOffset, -11)
    StatusTrackingBarManager:SetSize(barWidth, 20)

    for _, region in pairs({StatusTrackingBarManager:GetRegions()}) do
        if region:IsObjectType("Texture") then
            region:SetAlpha(0)
        end
    end

    local isMaxLevel = UnitLevel("player") >= (GetMaxPlayerLevel() or 60)
    local secondary = StatusTrackingBarManager.SecondaryStatusTrackingBarContainer
    if not isMaxLevel and secondary then
        secondary:Hide()
    end

    local containers = {
        StatusTrackingBarManager.MainStatusTrackingBarContainer,
        StatusTrackingBarManager.SecondaryStatusTrackingBarContainer
    }

    for i, container in ipairs(containers) do
        if container and container:IsShown() then
            container:ClearAllPoints()
            container:SetPoint("BOTTOM", StatusTrackingBarManager, "BOTTOM", 0, (i-1)*10)
            container:SetSize(barWidth, 10)
            container:SetAlpha(1)

            for _, child in pairs({container:GetChildren()}) do
                if child.StatusBar and child:IsShown() then
                    child:ClearAllPoints()
                    child:SetAllPoints(container)
                    child:SetAlpha(1)
                    child.StatusBar:ClearAllPoints()
                    child.StatusBar:SetAllPoints(child)
                    child.StatusBar:SetAlpha(1)
                    if child.OverlayFrame then
                        if GetCVar("xpBarText") == "1" then
                            child.OverlayFrame:Show()
                            for _, region in pairs({child.OverlayFrame:GetRegions()}) do
                                if region:IsObjectType("Texture") then
                                    region:SetAlpha(0)
                                end
                            end
                        else
                            child.OverlayFrame:Hide()
                        end
                    end
                end
            end

            for _, region in pairs({container:GetRegions()}) do
                if region:IsObjectType("Texture") then
                    region:SetAlpha(0)
                end
            end
        end
    end

    isUpdating = false
end

function BFAUI_SetBarWidth(width, offset)
    barWidth = width
    barOffset = offset
    if XPBarBackground then
        XPBarBackground:SetSize(width, 10)
        XPBarBackground:ClearAllPoints()
        XPBarBackground:SetPoint("BOTTOM", MainMenuBar, "BOTTOM", offset, -11)
    end
    UpdateStatusBars()
end

hooksecurefunc(StatusTrackingBarManager, "UpdateBarsShown", function()
    if not isUpdating then UpdateStatusBars() end
end)
hooksecurefunc(StatusTrackingBarManager, "SetPoint", function()
    if not isUpdating then UpdateStatusBars() end
end)

BFA_Manager:SetScript("OnEvent", UpdateStatusBars)
