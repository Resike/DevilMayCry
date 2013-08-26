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
	[1] = 250, -- Dirty!
	[2] = 250, -- Cruel!
	[3] = 260, -- Brutal!
	[4] = 270, -- Anarhic!
	[5] = 260, -- Savage!
	[6] = 290, -- Sadistic!!
	[7] = 330  -- Sensational!!!
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
bgTexture:SetDrawLayer("Background", 5)

local fgTexture = frame:CreateTexture(nil, "Background")
fgTexture:SetTexture(foregroundTextures[currentRank])
fgTexture:SetWidth(BASE_SIZE)
fgTexture:SetHeight(BASE_SIZE)
fgTexture:SetPoint("Bottom", frame, "Bottom")
fgTexture:SetDrawLayer("Background", 6)

local bgframe = CreateFrame("Frame", nil, UIParent)
bgframe:SetFrameStrata("Background")
bgframe:SetAllPoints(frame)

local spTexture = bgframe:CreateTexture(nil, "Background")
spTexture:SetTexture([[Interface\Addons\DevilMayCry\Textures\Splat1]])
spTexture:SetWidth(700)
spTexture:SetHeight(700)
spTexture:SetPoint("Right", bgframe, "Right", 150, - 5)
spTexture:SetDrawLayer("Background", 0)
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

function DevilMayCry:IncreaseHeight(percent)
	percentCompleted = percentCompleted + percent
	WIDTH_SCALE = 1.12
end

local extraSTexture = frame:CreateTexture(nil, "Background")
extraSTexture:SetWidth(BASE_SIZE)
extraSTexture:SetHeight(BASE_SIZE)
extraSTexture:SetPoint("Right", bgTexture, "Left", 50, 0)
extraSTexture:SetDrawLayer("Background", 6)

local extraSSTexture = frame:CreateTexture(nil, "Background")
extraSSTexture:SetWidth(BASE_SIZE)
extraSSTexture:SetHeight(BASE_SIZE)
extraSSTexture:SetPoint("Right", extraSTexture, "Left", 50, 0)
extraSSTexture:SetDrawLayer("Background", 6)

function DevilMayCry:TestMode()
	percentCompleted = 0
	if currentRank == 6 then
		extraSTexture:Show()
		extraSTexture:SetTexture(foregroundTextures[currentRank])
		bgTexture:SetTexture(backgroundTextures[currentRank])
		fgTexture:SetTexture(foregroundTextures[currentRank])
	elseif currentRank == 7 then
		extraSTexture:Show()
		extraSTexture:SetTexture(foregroundTextures[currentRank])
		extraSSTexture:Show()
		extraSSTexture:SetTexture(foregroundTextures[currentRank])
		bgTexture:SetTexture(backgroundTextures[currentRank])
		fgTexture:SetTexture(foregroundTextures[currentRank])
	else
		extraSTexture:Hide()
		extraSSTexture:Hide()
		if bgTexture:GetTexture() ~= backgroundTextures[currentRank] then
			bgTexture:SetTexture(backgroundTextures[currentRank])
		end
		if fgTexture:GetTexture() ~= foregroundTextures[currentRank] then
			fgTexture:SetTexture(foregroundTextures[currentRank])
		end
	end
end

frame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local Addon = ...
		if Addon == "DevilMayCry" then
			frame:SetPoint("Center", DevilMayCryVars.x, DevilMayCryVars.y)
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
			-- Test loop
			DevilMayCry:TestMode()
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
		end
		SetSize(fgTexture, size * WIDTH_SCALE, size * percentCompleted)
		if WIDTH_SCALE > 1 then
			WIDTH_SCALE = WIDTH_SCALE - WIDTH_DELTA
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
				bgTexture:ClearAllPoints()
				bgTexture:SetPoint("Center", frame, "Center", - currentPos, 0)
				fgTexture:ClearAllPoints()
				fgTexture:SetPoint("Bottom", frame, "Bottom", - currentPos, 0)
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
			spTexture:SetPoint("Right", bgframe, "Right", 150 - currentSpPos, - 5)
		end
		if slideAnimEnded then
			currentPos = currentPos - 14
			spTexture:SetWidth(spTexture:GetWidth() - (currentPos / 10))
			bgTexture:ClearAllPoints()
			bgTexture:SetPoint("Center", frame, "Center", - currentPos, 0)
			fgTexture:ClearAllPoints()
			fgTexture:SetPoint("Bottom", frame, "Bottom", - currentPos, 0)
			if currentPos < 0 then
				currentPos = 0
				currentSpPos = 0
				slideAnimEnded = false
				extraSTexture:Hide()
				extraSSTexture:Hide()
				bgTexture:SetAllPoints(frame)
				fgTexture:SetPoint("Bottom", frame, "Bottom")
				spTexture:Hide()
				spTexture:SetWidth(700)
				spTexture:ClearAllPoints()
				spTexture:SetPoint("Right", bgframe, "Right", 150, - 5)
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