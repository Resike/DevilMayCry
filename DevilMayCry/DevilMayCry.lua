local _, ns = ...
local DevilMayCry = { }
ns.DevilMayCry = DevilMayCry

local BaseSize = 128
local TextureSize = 128
local AnimSize = 300
local ReachedMax = false

local Frame = CreateFrame("Frame", nil, UIParent)
Frame:SetPoint("CENTER", 500, 450)
Frame:SetFrameStrata("Medium")
Frame:SetFrameLevel(0)
Frame:SetWidth(TextureSize)
Frame:SetHeight(TextureSize)
Frame:SetAlpha(0.99)
Frame:SetMovable(true)
Frame:EnableMouse(true)
Frame:SetClampedToScreen(false)
Frame:RegisterForDrag("LeftButton")

local Background = Frame:CreateTexture("Texture", "Background")
Background:SetTexture("Interface\\Addons\\DevilMayCry\\Textures\\Background")
Background:SetWidth(TextureSize)
Background:SetHeight(TextureSize)
Background:SetBlendMode("Disable")
Background:SetDrawLayer("Background", 0)
Background:SetAllPoints(Frame)

local Foreground = Frame:CreateTexture("Texture", "Background")
Foreground:SetTexture("Interface\\Addons\\DevilMayCry\\Textures\\Foreground")
Foreground:SetWidth(TextureSize)
Foreground:SetHeight(TextureSize)
Foreground:SetBlendMode("Disable")
Foreground:SetDrawLayer("Background", 1)
Foreground:SetPoint("Bottom", Frame, "Bottom")

local UpdateFrame = CreateFrame("Frame", nil)
local TimeSinceLastUpdate = 0
local NextUpdate = 0.0050

function DevilMayCry.StartMove(frame, button)
	if button ~= "LeftButton" then
		return
	end
	frame:StartMoving()
end

Frame:SetScript("OnMouseDown", DevilMayCry.StartMove)

function DevilMayCry.StopMove(frame, button)
	if button ~= "LeftButton" then
		return
	end
	frame:StopMovingOrSizing()
	local x = math.floor(frame:GetLeft() + (frame:GetWidth() - UIParent:GetWidth()) / 2 + 0.5)
	local y = math.floor(frame:GetTop() - (frame:GetHeight() + UIParent:GetHeight()) / 2 + 0.5)
	frame:ClearAllPoints()
	frame:SetPoint("CENTER", x, y)
end

Frame:SetScript("OnMouseUp", DevilMayCry.StopMove)

function DevilMayCry:SetSize()
	if Foreground:GetHeight() > TextureSize * 0.9999 then
		ReachedMax = true
	end
	if Foreground:GetHeight() <= 0 then
		-- Test Mode
		Frame:SetWidth(TextureSize)
		Frame:SetHeight(TextureSize)
		Background:SetAllPoints(Frame)
		Foreground:SetWidth(TextureSize)
		Foreground:SetHeight(TextureSize)
		Foreground:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
	else
		local y = Foreground:GetHeight() / TextureSize
		if y > 1 then
			Foreground:SetHeight(TextureSize)
			y = 1
		end
		Frame:SetHeight(TextureSize)
		Frame:SetWidth(TextureSize)
		Background:SetAllPoints(Frame)
		if Foreground:GetWidth() > TextureSize then
			Foreground:SetWidth(Foreground:GetWidth() - ((TextureSize / 128) * 0.1))
		end
		Foreground:SetHeight(Foreground:GetHeight() - ((TextureSize / 128) * 0.1))
		local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = Foreground:GetTexCoord()
		Foreground:SetTexCoord(ULx, 1 - y, LLx, LLy, URx, 1 - y, LRx, LRy)
	end
	return 0.0050
end

function DevilMayCry:SetTextureSize(size)
	local LastSize = TextureSize
	TextureSize = size
	Foreground:SetWidth(Foreground:GetWidth() * TextureSize / LastSize)
	Foreground:SetHeight(Foreground:GetHeight() * TextureSize / LastSize)
end

function DevilMayCry:AnimateTexture()
	DevilMayCry:SetTextureSize(AnimSize)
	if AnimSize >= (BaseSize + 2) then
		AnimSize = AnimSize - 2
	else
		AnimSize = 300
		ReachedMax = false
	end
end

function DevilMayCry_IncreaseHeight(percent)
	if Foreground:GetHeight() < (TextureSize * (1 - percent)) then
		Foreground:SetHeight(Foreground:GetHeight() + (TextureSize * percent))
	else
		Foreground:SetHeight(TextureSize)
	end
	if Foreground:GetWidth() <= (TextureSize) then
		Foreground:SetWidth(Foreground:GetWidth() * 1.12)
	else
		Foreground:SetWidth(TextureSize * 1.12)
	end
end

function DevilMayCry:OnUpdate(elapsed)
	TimeSinceLastUpdate = TimeSinceLastUpdate + elapsed
	while TimeSinceLastUpdate > NextUpdate do
		TimeSinceLastUpdate = TimeSinceLastUpdate - NextUpdate
		if ReachedMax == true then
			DevilMayCry:AnimateTexture()
		end
		NextUpdate = DevilMayCry:SetSize()
	end
end

UpdateFrame:SetScript("OnUpdate", DevilMayCry.OnUpdate)