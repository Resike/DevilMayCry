local _, ns = ...
local DevilMayCry = { }
ns.DevilMayCry = DevilMayCry

local DefaultSettings = {
	x = 0,
	y = 0,
	sound = true
}

function DevilMayCry:CopySettings(src, dst)
	if type(src) ~= "table" then
		return { }
	end
	if type(dst) then
		dst = { }
	end
	for k, v in pairs(src) do
		if type(v) == "table" then
			dst[k] = DevilMayCry:CopySettings(v, dst[k])
		elseif type(v) ~= type(dst[k]) then
			dst[k] = v
		end
	end
	return dst
end

DevilMayCryVars = DevilMayCry:CopySettings(DefaultSettings, DevilMayCryVars)

local BASE_SIZE = 128
local MAX_SIZE = BASE_SIZE * 2.4
local UPDATE_INTERVAL = 0.005

local SCALE_DELTA = 0.06
local MAX_SCALE = MAX_SIZE / BASE_SIZE + SCALE_DELTA
local WIDTH_SCALE = 1
local WIDTH_DELTA = 0.005

local currentScale, percentCompleted = 1, 0

local zoomAnimEnded = false
local slideAnimEnded = false

local testMode = true

local currentRank = 1

local currentPos = 0
local currentSpPos = 0

local time

local currentRelativePos = {
	[1] = 160, -- Dirty!
	[2] = 160, -- Cruel!
	[3] = 200, -- Brutal!
	[4] = 280, -- Anarchic!
	[5] = 200, -- Savage!
	[6] = 280, -- Sadistic!
	[7] = 400  -- Sensational!
}

local backgroundTextures = {
	[1] = [[Interface\Addons\DevilMayCry\Textures\DB]],
	[2] = [[Interface\Addons\DevilMayCry\Textures\CB]],
	[3] = [[Interface\Addons\DevilMayCry\Textures\BB]],
	[4] = [[Interface\Addons\DevilMayCry\Textures\AB]],
	[5] = [[Interface\Addons\DevilMayCry\Textures\SB]],
	[6] = [[Interface\Addons\DevilMayCry\Textures\SB]],
	[7] = [[Interface\Addons\DevilMayCry\Textures\SB]]
}

local foregroundTextures = {
	[1] = [[Interface\Addons\DevilMayCry\Textures\DF]],
	[2] = [[Interface\Addons\DevilMayCry\Textures\CF]],
	[3] = [[Interface\Addons\DevilMayCry\Textures\BF]],
	[4] = [[Interface\Addons\DevilMayCry\Textures\AF]],
	[5] = [[Interface\Addons\DevilMayCry\Textures\SF]],
	[6] = [[Interface\Addons\DevilMayCry\Textures\SF]],
	[7] = [[Interface\Addons\DevilMayCry\Textures\SF]]
}

local streakSounds = {
	[1] = [[Interface\Addons\DevilMayCry\Sounds\1Dirty.mp3]],
	[2] = [[Interface\Addons\DevilMayCry\Sounds\2Cruel.mp3]],
	[3] = [[Interface\Addons\DevilMayCry\Sounds\3Brutal.mp3]],
	[4] = [[Interface\Addons\DevilMayCry\Sounds\4Anarhic.mp3]],
	[5] = [[Interface\Addons\DevilMayCry\Sounds\5Savage.mp3]],
	[6] = [[Interface\Addons\DevilMayCry\Sounds\6Sadistic.mp3]],
	[7] = [[Interface\Addons\DevilMayCry\Sounds\7Sensational.mp3]]
}

local frame = CreateFrame("Frame", nil, UIParent)
frame:RegisterEvent("ADDON_LOADED")
frame:SetPoint("Center", DevilMayCryVars.x, DevilMayCryVars.y)
frame:SetFrameStrata("Medium")
frame:SetFrameLevel(0)
frame:SetWidth(BASE_SIZE)
frame:SetHeight(BASE_SIZE)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(false)
frame:RegisterForDrag("LeftButton")
frame:RegisterForDrag("RightButton")

local animframe = CreateFrame("Frame", nil, UIParent)

local testframe = CreateFrame("Frame", nil, UIParent)

local bgTexture = frame:CreateTexture(nil, "Background")
bgTexture:SetTexture(backgroundTextures[currentRank])
bgTexture:SetWidth(BASE_SIZE)
bgTexture:SetHeight(BASE_SIZE)
bgTexture:SetAllPoints()
bgTexture:SetDrawLayer("Background", 6)

local fgTexture = frame:CreateTexture(nil, "Background")
fgTexture:SetTexture(foregroundTextures[currentRank])
fgTexture:SetWidth(BASE_SIZE)
fgTexture:SetHeight(BASE_SIZE)
fgTexture:SetPoint("Bottom", frame, "Bottom")
fgTexture:SetDrawLayer("Background", 7)

local extraSBTexture = frame:CreateTexture(nil, "Background")
extraSBTexture:SetTexture([[Interface\Addons\DevilMayCry\Textures\SB]])
extraSBTexture:SetWidth(BASE_SIZE)
extraSBTexture:SetHeight(BASE_SIZE)
extraSBTexture:SetPoint("Center", frame, "Center", - 80, 0)
extraSBTexture:SetDrawLayer("Background", 6)
extraSBTexture:Hide()

local extraSFTexture = frame:CreateTexture(nil, "Background")
extraSFTexture:SetTexture([[Interface\Addons\DevilMayCry\Textures\SF]])
extraSFTexture:SetWidth(BASE_SIZE)
extraSFTexture:SetHeight(BASE_SIZE)
extraSFTexture:SetPoint("Bottom", extraSBTexture, "Bottom")
extraSFTexture:SetDrawLayer("Background", 7)
extraSFTexture:Hide()

local extraSSBTexture = frame:CreateTexture(nil, "Background")
extraSSBTexture:SetTexture([[Interface\Addons\DevilMayCry\Textures\SB]])
extraSSBTexture:SetWidth(BASE_SIZE)
extraSSBTexture:SetHeight(BASE_SIZE)
extraSSBTexture:SetPoint("Center", extraSBTexture, "Center", - 80, 0)
extraSSBTexture:SetDrawLayer("Background", 6)
extraSSBTexture:Hide()

local extraSSFTexture = frame:CreateTexture(nil, "Background")
extraSSFTexture:SetTexture([[Interface\Addons\DevilMayCry\Textures\SF]])
extraSSFTexture:SetWidth(BASE_SIZE)
extraSSFTexture:SetHeight(BASE_SIZE)
extraSSFTexture:SetPoint("Bottom", extraSSBTexture, "Bottom")
extraSSFTexture:SetDrawLayer("Background", 7)
extraSSFTexture:Hide()

local letter1Texture = frame:CreateTexture(nil, "Background")
letter1Texture:SetWidth(80)
letter1Texture:SetHeight(80)
letter1Texture:SetPoint("Left", frame, "Center", - 25, 15)
letter1Texture:SetDrawLayer("Background", 5)

local letter2Texture = frame:CreateTexture(nil, "Background")
letter2Texture:SetWidth(80)
letter2Texture:SetHeight(80)
letter2Texture:SetPoint("Left", letter1Texture, "Center", - 35, 0)
letter2Texture:SetDrawLayer("Background", 4)

local letter3Texture = frame:CreateTexture(nil, "Background")
letter3Texture:SetWidth(80)
letter3Texture:SetHeight(80)
letter3Texture:SetPoint("Left", letter2Texture, "Center", - 35, 0)
letter3Texture:SetDrawLayer("Background", 3)

local letter4Texture = frame:CreateTexture(nil, "Background")
letter4Texture:SetWidth(80)
letter4Texture:SetHeight(80)
letter4Texture:SetPoint("Left", letter3Texture, "Center", - 35, 0)
letter4Texture:SetDrawLayer("Background", 2)

local letter5Texture = frame:CreateTexture(nil, "Background")
letter5Texture:SetWidth(80)
letter5Texture:SetHeight(80)
letter5Texture:SetPoint("Left", letter4Texture, "Center", - 35, 0)
letter5Texture:SetDrawLayer("Background", 1)

local letter6Texture = frame:CreateTexture(nil, "Background")
letter6Texture:SetWidth(80)
letter6Texture:SetHeight(80)
letter6Texture:SetPoint("Left", letter5Texture, "Center", - 35, 0)
letter6Texture:SetDrawLayer("Background", 0)

local letter7Texture = frame:CreateTexture(nil, "Background")
letter7Texture:SetWidth(80)
letter7Texture:SetHeight(80)
letter7Texture:SetPoint("Left", letter6Texture, "Center", - 35, 0)
letter7Texture:SetDrawLayer("Background", - 1)

local letter8Texture = frame:CreateTexture(nil, "Background")
letter8Texture:SetWidth(80)
letter8Texture:SetHeight(80)
letter8Texture:SetPoint("Left", letter7Texture, "Center", - 35, 0)
letter8Texture:SetDrawLayer("Background", - 2)

local letter9Texture = frame:CreateTexture(nil, "Background")
letter9Texture:SetWidth(80)
letter9Texture:SetHeight(80)
letter9Texture:SetPoint("Left", letter8Texture, "Center", - 35, 0)
letter9Texture:SetDrawLayer("Background", - 3)

local letter10Texture = frame:CreateTexture(nil, "Background")
letter10Texture:SetWidth(80)
letter10Texture:SetHeight(80)
letter10Texture:SetPoint("Left", letter9Texture, "Center", - 35, 0)
letter10Texture:SetDrawLayer("Background", - 4)

local letter11Texture = frame:CreateTexture(nil, "Background")
letter11Texture:SetWidth(80)
letter11Texture:SetHeight(80)
letter11Texture:SetPoint("Left", letter10Texture, "Center", - 25, 0)
letter11Texture:SetDrawLayer("Background", - 5)

local spframe = CreateFrame("Frame", nil, UIParent)
spframe:SetPoint("Center", DevilMayCryVars.x, DevilMayCryVars.y)
spframe:SetFrameStrata("Background")
spframe:SetFrameLevel(0)
spframe:SetWidth(BASE_SIZE)
spframe:SetHeight(BASE_SIZE)

local spTexture = spframe:CreateTexture(nil, "Background")
spTexture:SetTexture([[Interface\Addons\DevilMayCry\Textures\Splat1]])
spTexture:SetWidth(700)
spTexture:SetHeight(700)
spTexture:SetPoint("Right", spframe, "Right", 150, - 5)
spTexture:SetDrawLayer("Background", - 7)
spTexture:Hide()

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
		DevilMayCryVars.x = L2 - L1 + (W2 - W1) / 2
		DevilMayCryVars.y = B2 - B1 + (H2 - H1) / 2
		self:ClearAllPoints()
		self:SetPoint("CENTER", L2 - L1 + (W2 - W1) / 2, B2 - B1 + (H2 - H1) / 2)
	elseif button == "RightButton" then
		DevilMayCryVars.sound = not DevilMayCryVars.sound
	end
end)

function DevilMayCry:SetLetters()
	if currentRank == 1 then
		letter1Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\I]])
		letter1Texture:SetAlpha(1)
		letter1Texture:Show()
		letter2Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\R]])
		letter2Texture:SetAlpha(1)
		letter2Texture:Show()
		letter3Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\T]])
		letter3Texture:SetAlpha(1)
		letter3Texture:Show()
		letter4Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\Y]])
		letter4Texture:SetAlpha(1)
		letter4Texture:Show()
		letter5Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\!]])
		letter5Texture:SetAlpha(1)
		letter5Texture:Show()
		letter6Texture:Hide()
		letter7Texture:Hide()
		letter8Texture:Hide()
		letter9Texture:Hide()
		letter10Texture:Hide()
		letter11Texture:Hide()
	elseif currentRank == 2 then
		letter1Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\R]])
		letter1Texture:SetAlpha(1)
		letter1Texture:Show()
		letter2Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\U]])
		letter2Texture:SetAlpha(1)
		letter2Texture:Show()
		letter3Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\E]])
		letter3Texture:SetAlpha(1)
		letter3Texture:Show()
		letter4Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\L]])
		letter4Texture:SetAlpha(1)
		letter4Texture:Show()
		letter5Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\!]])
		letter5Texture:SetAlpha(1)
		letter5Texture:Show()
		letter6Texture:Hide()
		letter7Texture:Hide()
		letter8Texture:Hide()
		letter9Texture:Hide()
		letter10Texture:Hide()
		letter11Texture:Hide()
	elseif currentRank == 3 then
		letter1Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\R]])
		letter1Texture:SetAlpha(1)
		letter1Texture:Show()
		letter2Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\U]])
		letter2Texture:SetAlpha(1)
		letter2Texture:Show()
		letter3Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\T]])
		letter3Texture:SetAlpha(1)
		letter3Texture:Show()
		letter4Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\A]])
		letter4Texture:SetAlpha(1)
		letter4Texture:Show()
		letter5Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\L]])
		letter5Texture:SetAlpha(1)
		letter5Texture:Show()
		letter6Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\!]])
		letter6Texture:SetAlpha(1)
		letter6Texture:Show()
		letter7Texture:Hide()
		letter8Texture:Hide()
		letter9Texture:Hide()
		letter10Texture:Hide()
		letter11Texture:Hide()
	elseif currentRank == 4 then
		letter1Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\N]])
		letter1Texture:SetAlpha(1)
		letter1Texture:Show()
		letter2Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\A]])
		letter2Texture:SetAlpha(1)
		letter2Texture:Show()
		letter3Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\R]])
		letter3Texture:SetAlpha(1)
		letter3Texture:Show()
		letter4Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\C]])
		letter4Texture:SetAlpha(1)
		letter4Texture:Show()
		letter5Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\H]])
		letter5Texture:SetAlpha(1)
		letter5Texture:Show()
		letter6Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\I]])
		letter6Texture:SetAlpha(1)
		letter6Texture:Show()
		letter7Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\C]])
		letter7Texture:SetAlpha(1)
		letter7Texture:Show()
		letter8Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\!]])
		letter8Texture:SetAlpha(1)
		letter8Texture:Show()
		letter9Texture:Hide()
		letter10Texture:Hide()
		letter11Texture:Hide()
	elseif currentRank == 5 then
		letter1Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\A]])
		letter1Texture:SetAlpha(1)
		letter1Texture:Show()
		letter2Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\V]])
		letter2Texture:SetAlpha(1)
		letter2Texture:Show()
		letter3Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\A]])
		letter3Texture:SetAlpha(1)
		letter3Texture:Show()
		letter4Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\G]])
		letter4Texture:SetAlpha(1)
		letter4Texture:Show()
		letter5Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\E]])
		letter5Texture:SetAlpha(1)
		letter5Texture:Show()
		letter6Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\!]])
		letter6Texture:SetAlpha(1)
		letter6Texture:Show()
		letter7Texture:Hide()
		letter8Texture:Hide()
		letter9Texture:Hide()
		letter10Texture:Hide()
		letter11Texture:Hide()
	elseif currentRank == 6 then
		letter1Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\A]])
		letter1Texture:SetAlpha(1)
		letter1Texture:Show()
		letter2Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\D]])
		letter2Texture:SetAlpha(1)
		letter2Texture:Show()
		letter3Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\I]])
		letter3Texture:SetAlpha(1)
		letter3Texture:Show()
		letter4Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\S]])
		letter4Texture:SetAlpha(1)
		letter4Texture:Show()
		letter5Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\T]])
		letter5Texture:SetAlpha(1)
		letter5Texture:Show()
		letter6Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\I]])
		letter6Texture:SetAlpha(1)
		letter6Texture:Show()
		letter7Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\C]])
		letter7Texture:SetAlpha(1)
		letter7Texture:Show()
		letter8Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\!]])
		letter8Texture:SetAlpha(1)
		letter8Texture:Show()
		letter9Texture:Hide()
		letter10Texture:Hide()
		letter11Texture:Hide()
	elseif currentRank == 7 then
		letter1Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\E]])
		letter1Texture:SetAlpha(1)
		letter1Texture:Show()
		letter2Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\N]])
		letter2Texture:SetAlpha(1)
		letter2Texture:Show()
		letter3Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\S]])
		letter3Texture:SetAlpha(1)
		letter3Texture:Show()
		letter4Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\A]])
		letter4Texture:SetAlpha(1)
		letter4Texture:Show()
		letter5Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\T]])
		letter5Texture:SetAlpha(1)
		letter5Texture:Show()
		letter6Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\I]])
		letter6Texture:SetAlpha(1)
		letter6Texture:Show()
		letter7Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\O]])
		letter7Texture:SetAlpha(1)
		letter7Texture:Show()
		letter8Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\N]])
		letter8Texture:SetAlpha(1)
		letter8Texture:Show()
		letter9Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\A]])
		letter9Texture:SetAlpha(1)
		letter9Texture:Show()
		letter10Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\L]])
		letter10Texture:SetAlpha(1)
		letter10Texture:Show()
		letter11Texture:SetTexture([[Interface\Addons\DevilMayCry\Textures\!]])
		letter11Texture:SetAlpha(1)
		letter11Texture:Show()
	end
end

function DevilMayCry:SetLetterPositions()
	if currentRank == 1 then
		letter4Texture:ClearAllPoints()
		letter4Texture:SetPoint("Left", frame, "Center", currentPos, 15)
		letter3Texture:ClearAllPoints()
		letter3Texture:SetPoint("Left", frame, "Center", currentPos / 1.35, 15)
		letter2Texture:ClearAllPoints()
		letter2Texture:SetPoint("Left", frame, "Center", currentPos / 2.1, 15)
		letter1Texture:ClearAllPoints()
		letter1Texture:SetPoint("Left", frame, "Center", currentPos / 4.8, 15)
		letter5Texture:ClearAllPoints()
		letter5Texture:SetPoint("Left", frame, "Center", currentPos * 1.2, 15)
	elseif currentRank == 2 then
		letter4Texture:ClearAllPoints()
		letter4Texture:SetPoint("Left", frame, "Center", currentPos, 15)
		letter3Texture:ClearAllPoints()
		letter3Texture:SetPoint("Left", frame, "Center", currentPos / 1.35, 15)
		letter2Texture:ClearAllPoints()
		letter2Texture:SetPoint("Left", frame, "Center", currentPos / 2.1, 15)
		letter1Texture:ClearAllPoints()
		letter1Texture:SetPoint("Left", frame, "Center", currentPos / 4.8, 15)
		letter5Texture:ClearAllPoints()
		letter5Texture:SetPoint("Left", frame, "Center", currentPos * 1.2, 15)
	elseif currentRank == 3 then
		letter5Texture:ClearAllPoints()
		letter5Texture:SetPoint("Left", frame, "Center", currentPos, 15)
		letter4Texture:ClearAllPoints()
		letter4Texture:SetPoint("Left", frame, "Center", currentPos / 1.3, 15)
		letter3Texture:ClearAllPoints()
		letter3Texture:SetPoint("Left", frame, "Center", currentPos / 1.8, 15)
		letter2Texture:ClearAllPoints()
		letter2Texture:SetPoint("Left", frame, "Center", currentPos / 2.7, 15)
		letter1Texture:ClearAllPoints()
		letter1Texture:SetPoint("Left", frame, "Center", currentPos / 6.4, 15)
		letter6Texture:ClearAllPoints()
		letter6Texture:SetPoint("Left", frame, "Center", currentPos * 1.18, 15)
	elseif currentRank == 4 then
		letter7Texture:ClearAllPoints()
		letter7Texture:SetPoint("Left", frame, "Center", currentPos, 15)
		letter6Texture:ClearAllPoints()
		letter6Texture:SetPoint("Left", frame, "Center", currentPos / 1.15, 15)
		letter5Texture:ClearAllPoints()
		letter5Texture:SetPoint("Left", frame, "Center", currentPos / 1.35, 15)
		letter4Texture:ClearAllPoints()
		letter4Texture:SetPoint("Left", frame, "Center", currentPos / 1.7, 15)
		letter3Texture:ClearAllPoints()
		letter3Texture:SetPoint("Left", frame, "Center", currentPos / 2.3, 15)
		letter2Texture:ClearAllPoints()
		letter2Texture:SetPoint("Left", frame, "Center", currentPos / 3.55, 15)
		letter1Texture:ClearAllPoints()
		letter1Texture:SetPoint("Left", frame, "Center", currentPos / 8.5, 15)
		letter8Texture:ClearAllPoints()
		letter8Texture:SetPoint("Left", frame, "Center", currentPos * 1.14, 15)
	elseif currentRank == 5 then
		letter5Texture:ClearAllPoints()
		letter5Texture:SetPoint("Left", frame, "Center", currentPos, 15)
		letter4Texture:ClearAllPoints()
		letter4Texture:SetPoint("Left", frame, "Center", currentPos / 1.3, 15)
		letter3Texture:ClearAllPoints()
		letter3Texture:SetPoint("Left", frame, "Center", currentPos / 1.8, 15)
		letter2Texture:ClearAllPoints()
		letter2Texture:SetPoint("Left", frame, "Center", currentPos / 2.9, 15)
		letter1Texture:ClearAllPoints()
		letter1Texture:SetPoint("Left", frame, "Center", currentPos / 6.4, 15)
		letter6Texture:ClearAllPoints()
		letter6Texture:SetPoint("Left", frame, "Center", currentPos * 1.18, 15)
	elseif currentRank == 6 then
		letter7Texture:ClearAllPoints()
		letter7Texture:SetPoint("Left", frame, "Center", currentPos, 15)
		letter6Texture:ClearAllPoints()
		letter6Texture:SetPoint("Left", frame, "Center", currentPos / 1.15, 15)
		letter5Texture:ClearAllPoints()
		letter5Texture:SetPoint("Left", frame, "Center", currentPos / 1.35, 15)
		letter4Texture:ClearAllPoints()
		letter4Texture:SetPoint("Left", frame, "Center", currentPos / 1.7, 15)
		letter3Texture:ClearAllPoints()
		letter3Texture:SetPoint("Left", frame, "Center", currentPos / 2.2, 15)
		letter2Texture:ClearAllPoints()
		letter2Texture:SetPoint("Left", frame, "Center", currentPos / 3.3, 15)
		letter1Texture:ClearAllPoints()
		letter1Texture:SetPoint("Left", frame, "Center", currentPos / 8, 15)
		letter8Texture:ClearAllPoints()
		letter8Texture:SetPoint("Left", frame, "Center", currentPos * 1.14, 15)
	elseif currentRank == 7 then
		letter10Texture:ClearAllPoints()
		letter10Texture:SetPoint("Left", frame, "Center", currentPos, 15)
		letter9Texture:ClearAllPoints()
		letter9Texture:SetPoint("Left", frame, "Center", currentPos / 1.12, 15)
		letter8Texture:ClearAllPoints()
		letter8Texture:SetPoint("Left", frame, "Center", currentPos / 1.3, 15)
		letter7Texture:ClearAllPoints()
		letter7Texture:SetPoint("Left", frame, "Center", currentPos / 1.55, 15)
		letter6Texture:ClearAllPoints()
		letter6Texture:SetPoint("Left", frame, "Center", currentPos / 1.85, 15)
		letter5Texture:ClearAllPoints()
		letter5Texture:SetPoint("Left", frame, "Center", currentPos / 2.2, 15)
		letter4Texture:ClearAllPoints()
		letter4Texture:SetPoint("Left", frame, "Center", currentPos / 2.7, 15)
		letter3Texture:ClearAllPoints()
		letter3Texture:SetPoint("Left", frame, "Center", currentPos / 3.8, 15)
		letter2Texture:ClearAllPoints()
		letter2Texture:SetPoint("Left", frame, "Center", currentPos / 6, 15)
		letter1Texture:ClearAllPoints()
		letter1Texture:SetPoint("Left", frame, "Center", currentPos / 16, 15)
		letter11Texture:ClearAllPoints()
		letter11Texture:SetPoint("Left", frame, "Center", currentPos * 1.1, 15)
	end
end

function DevilMayCry:IncreaseHeight(percent)
	percentCompleted = percentCompleted + percent
	WIDTH_SCALE = 1.12
end

-- Test
function DevilMayCry_IncreaseHeight(percent)
	DevilMayCry:IncreaseHeight(percent)
end

frame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local Addon = ...
		if Addon == "DevilMayCry" then
			frame:SetPoint("Center", DevilMayCryVars.x, DevilMayCryVars.y)
			spframe:SetPoint("Center", DevilMayCryVars.x, DevilMayCryVars.y)
			frame:UnregisterEvent("ADDON_LOADED")
		end
	end
end)

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
		if percentCompleted >= 1 then
			currentRank = currentRank + 1
			if currentRank > table.getn(backgroundTextures) then
				currentRank = 1
			end
			if DevilMayCryVars.sound then
				PlaySoundFile(streakSounds[currentRank], "Master")
			end
			currentScale = MAX_SCALE
			percentCompleted = 0
			if bgTexture:GetTexture() ~= backgroundTextures[currentRank] then
				bgTexture:SetTexture(backgroundTextures[currentRank])
			end
			if fgTexture:GetTexture() ~= foregroundTextures[currentRank] then
				fgTexture:SetTexture(foregroundTextures[currentRank])
			end
			zoomAnimEnded = false
			slideAnimEnded = false
			DevilMayCry:SetLetters()
		end
		if percentCompleted <= 0 then
			-- Hide animation
		end
		if currentScale > 1 then
			currentScale = currentScale - SCALE_DELTA
			if currentScale < 1 then
				zoomAnimEnded = true
				currentScale = 1
			end
			size = size * currentScale
			SetSize(self, size, size)
			SetSize(extraSBTexture, size, size)
			SetSize(extraSFTexture, size, size)
			SetSize(extraSSBTexture, size, size)
			SetSize(extraSSFTexture, size, size)
		end
		if currentRank == 6 then
			extraSBTexture:Show()
			extraSFTexture:Show()
		elseif currentRank == 7 then
			extraSBTexture:Show()
			extraSFTexture:Show()
			extraSSBTexture:Show()
			extraSSFTexture:Show()
		else
			extraSBTexture:Hide()
			extraSFTexture:Hide()
			extraSSBTexture:Hide()
			extraSSFTexture:Hide()
		end
		SetSize(fgTexture, size * WIDTH_SCALE, size * percentCompleted)
		SetSize(extraSFTexture, size * WIDTH_SCALE, size * percentCompleted)
		SetSize(extraSSFTexture, size * WIDTH_SCALE, size * percentCompleted)
		if WIDTH_SCALE > 1 then
			WIDTH_SCALE = WIDTH_SCALE - WIDTH_DELTA
			if WIDTH_SCALE < 1 then
				WIDTH_SCALE = 1
			end
		end
		if currentScale == 1 then
			SetSize(self, size, size)
			SetSize(extraSBTexture, size, size)
			SetSize(extraSSBTexture, size, size)
		end
		SetTexCoord(fgTexture, 0, 1, 1 - percentCompleted, 1)
		SetTexCoord(extraSFTexture, 0, 1, 1 - percentCompleted, 1)
		SetTexCoord(extraSSFTexture, 0, 1, 1 - percentCompleted, 1)
	end)
end

do
	local timer = 0
	animframe:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer < UPDATE_INTERVAL then
			return
		end
		timer = 0
		if zoomAnimEnded then
			if currentPos < currentRelativePos[currentRank] then
				currentPos = currentPos + 14
				spTexture:Show()
				spTexture:SetWidth(spTexture:GetWidth() + (currentPos / 14))
				frame:SetPoint("Center", DevilMayCryVars.x - currentPos, DevilMayCryVars.y)
				DevilMayCry:SetLetterPositions()
			else
				if not time then
					time = GetTime()
				end
				if time + 3 < GetTime() then
					time = nil
					currentPos = currentRelativePos[currentRank]
					zoomAnimEnded = false
					slideAnimEnded = true
				end
			end
			currentSpPos = currentSpPos + 0.15
			spTexture:ClearAllPoints()
			spTexture:SetPoint("Right", spframe, "Right", 150 - currentSpPos, - 5)
		end
		if slideAnimEnded then
			currentPos = currentPos - 14
			letter1Texture:SetAlpha(letter1Texture:GetAlpha() - 0.075)
			letter2Texture:SetAlpha(letter2Texture:GetAlpha() - 0.075)
			letter3Texture:SetAlpha(letter3Texture:GetAlpha() - 0.075)
			letter4Texture:SetAlpha(letter4Texture:GetAlpha() - 0.075)
			letter5Texture:SetAlpha(letter5Texture:GetAlpha() - 0.075)
			letter6Texture:SetAlpha(letter6Texture:GetAlpha() - 0.075)
			letter7Texture:SetAlpha(letter7Texture:GetAlpha() - 0.075)
			letter8Texture:SetAlpha(letter8Texture:GetAlpha() - 0.075)
			letter9Texture:SetAlpha(letter9Texture:GetAlpha() - 0.075)
			letter10Texture:SetAlpha(letter10Texture:GetAlpha() - 0.075)
			letter11Texture:SetAlpha(letter11Texture:GetAlpha() - 0.075)
			spTexture:SetWidth(spTexture:GetWidth() - (currentPos / 10))
			frame:SetPoint("Center", DevilMayCryVars.x - currentPos, DevilMayCryVars.y)
			DevilMayCry:SetLetterPositions()
			if currentPos < 0 then
				currentPos = 0
				currentSpPos = 0
				slideAnimEnded = false
				frame:SetPoint("Center", DevilMayCryVars.x, DevilMayCryVars.y)
				letter1Texture:SetPoint("Left", frame, "Center", - 25, 15)
				letter2Texture:SetPoint("Left", letter1Texture, "Center", - 35, 0)
				letter3Texture:SetPoint("Left", letter2Texture, "Center", - 35, 0)
				letter4Texture:SetPoint("Left", letter3Texture, "Center", - 35, 0)
				letter5Texture:SetPoint("Left", letter4Texture, "Center", - 35, 0)
				letter6Texture:SetPoint("Left", letter5Texture, "Center", - 35, 0)
				letter7Texture:SetPoint("Left", letter6Texture, "Center", - 35, 0)
				letter8Texture:SetPoint("Left", letter7Texture, "Center", - 35, 0)
				letter9Texture:SetPoint("Left", letter8Texture, "Center", - 35, 0)
				letter10Texture:SetPoint("Left", letter9Texture, "Center", - 35, 0)
				letter11Texture:SetPoint("Left", letter10Texture, "Center", - 35, 0)
				letter1Texture:Hide()
				letter2Texture:Hide()
				letter3Texture:Hide()
				letter4Texture:Hide()
				letter5Texture:Hide()
				letter6Texture:Hide()
				letter7Texture:Hide()
				letter8Texture:Hide()
				letter9Texture:Hide()
				letter10Texture:Hide()
				letter11Texture:Hide()
				spTexture:Hide()
				spTexture:SetWidth(700)
				spTexture:SetPoint("Right", spframe, "Right", 150, - 5)
			end
		end
	end)
end

do
	local timer = 0
	testframe:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer < 1 or not testMode then
			return
		end
		timer = 0
		if testMode then
			DevilMayCry:IncreaseHeight(0.2)
		end
	end)
end