local _, ns = ...
local DevilMayCry = { }
ns.DevilMayCry = DevilMayCry

local BASE_SIZE = 128
local MAX_SIZE = BASE_SIZE * 2.4
local UPDATE_INTERVAL = 0.005

local SCALE_DELTA = 0.06
local MAX_SCALE = MAX_SIZE / BASE_SIZE + SCALE_DELTA
local WIDTH_SCALE = 1

local currentScale, percentCompleted = 1, 1

local frame = CreateFrame("Frame", nil, UIParent)
frame:SetPoint("Center", 500, 450)
frame:SetFrameStrata("Medium")
frame:SetFrameLevel(0)
frame:SetWidth(BASE_SIZE)
frame:SetHeight(BASE_SIZE)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(false)
frame:RegisterForDrag("LeftButton")

local bgTexture = frame:CreateTexture(nil, "Background")
bgTexture:SetTexture([[Interface\Addons\DevilMayCry\Textures\DB]])
bgTexture:SetWidth(BASE_SIZE)
bgTexture:SetHeight(BASE_SIZE)
bgTexture:SetAllPoints()
bgTexture:SetDrawLayer("Background", 5)

local fgTexture = frame:CreateTexture(nil, "Background")
fgTexture:SetTexture([[Interface\Addons\DevilMayCry\Textures\DF]])
fgTexture:SetWidth(BASE_SIZE)
fgTexture:SetHeight(BASE_SIZE)
fgTexture:SetPoint("Bottom")
fgTexture:SetDrawLayer("Background", 6)

frame:SetScript("OnMouseDown", function(self, button)
	if button == "LeftButton" then
		self:StartMoving()
	end
end)

frame:SetScript("OnMouseUp", function(self, button)
	if button == "LeftButton" then
		self:StopMovingOrSizing()
		local L1, B1, W1, H1 = UIParent:GetRect()
		local L2, B2, W2, H2 = self:GetRect()
		self:ClearAllPoints()
		self:SetPoint("CENTER", L2 - L1 + (W2 - W1) / 2, B2 - B1 + (H2 - H1) / 2)
	end
end)

function DevilMayCry_IncreaseHeight(percent)
	if fgTexture:GetHeight() < (BASE_SIZE * (1 - percent)) then
		percentCompleted = percentCompleted + percent
	else
		percentCompleted = 1
		currentScale = MAX_SCALE
	end
	WIDTH_SCALE = 1.12
end

local SetSize, SetTexCoord = frame.SetSize, fgTexture.SetTexCoord

do
	local timer = 0
	frame:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer < UPDATE_INTERVAL then
			return
		end
		timer = 0
		local size = BASE_SIZE
		percentCompleted = percentCompleted - 0.0015
		if percentCompleted < 0 then
			-- Test loop
			percentCompleted = 1
			currentScale = MAX_SCALE
		end
		if currentScale > 1 then
			currentScale = currentScale - 0.06
			if currentScale < 1 then
				currentScale = 1
			end
			size = size * currentScale
			SetSize(self, size, size)
		end
		SetSize(fgTexture, size * WIDTH_SCALE, size * percentCompleted)
		if WIDTH_SCALE > 1 then
			WIDTH_SCALE = WIDTH_SCALE - 0.005
			if WIDTH_SCALE < 1 then
				WIDTH_SCALE = 1
			end
		end
		if currentScale == 1 then
			SetSize(self, size, size)
		end
		SetTexCoord(fgTexture, 0, 1, 1 - percentCompleted, 1)
	end)
end