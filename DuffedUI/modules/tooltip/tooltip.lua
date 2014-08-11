local D, C, L = unpack(select(2, ...))
if not C["tooltip"].enable then return end
-- credits : Aezay (TipTac) and Caellian for some parts of code.

local DuffedUITooltip = CreateFrame("Frame", "DuffedUITooltip", UIParent)
local _G = getfenv(0)
local GameTooltip, GameTooltipStatusBar = _G["GameTooltip"], _G["GameTooltipStatusBar"]
local gsub, find, format = string.gsub, string.find, string.format
local ItemRefTooltip = ItemRefTooltip
local NeedBackdropBorderRefresh = true
local linkTypes = {
	item = true,
	enchant = true,
	spell = true,
	quest = true,
	unit = true,
	talent = true,
	achievement = true,
	glyph = true,
}

local Tooltips = {
	GameTooltip,
	ItemRefShoppingTooltip1,
	ItemRefShoppingTooltip2,
	ItemRefShoppingTooltip3,
	ShoppingTooltip1,
	ShoppingTooltip2,
	ShoppingTooltip3,
	WorldMapTooltip,
	WorldMapCompareTooltip1,
	WorldMapCompareTooltip2,
	WorldMapCompareTooltip3,
}

local classification = {
	worldboss = "|cffAF5050Boss|r",
	rareelite = "|cffAF5050+ Rare|r",
	elite = "|cffAF5050+|r",
	rare = "|cffAF5050Rare|r",
}

local anchor = CreateFrame("Frame", "DuffedUITooltipAnchor", UIParent)
anchor:SetSize(200, DuffedUIInfoRight:GetHeight())
anchor:SetFrameStrata("TOOLTIP")
anchor:SetFrameLevel(20)
anchor:SetClampedToScreen(true)
anchor:SetAlpha(0)
if C["chat"].rbackground and DuffedUIChatBackgroundRight then
	anchor:SetPoint("BOTTOMRIGHT", DuffedUIChatBackgroundRight, "TOPRIGHT", 0, -DuffedUIInfoRight:GetHeight())
else
	anchor:SetPoint("BOTTOMRIGHT", UIParent, 0, 110)
end
anchor:SetTemplate("Transparent")
anchor:SetBackdropBorderColor(1, 0, 0, 1)
anchor:SetMovable(true)
anchor.text = D.SetFontString(anchor, C["media"].font, 12)
anchor.text:SetPoint("CENTER")
anchor.text:SetText(L.move_tooltip)
tinsert(D.AllowFrameMoving, DuffedUITooltipAnchor)

local function UpdateTooltip(self)
	local owner = self:GetOwner()
	if not owner then return end
	local name = owner:GetName()
	local x = D.Scale(5)

	if self:GetAnchorType() == "ANCHOR_CURSOR" then
		if NeedBackdropBorderRefresh then
			self:ClearAllPoints()
			NeedBackdropBorderRefresh = false
			self:SetBackdropColor(unpack(C["media"].backdropcolor))
			if not C["tooltip"].cursor then self:SetBackdropBorderColor(unpack(C["media"].bordercolor)) end
		end
	elseif self:GetAnchorType() == "ANCHOR_NONE" and InCombatLockdown() and C["tooltip"].hidecombat == true then
		self:Hide()
		return
	end

	if name and (DuffedUIPlayerBuffs or DuffedUIPlayerDebuffs) then
		if (DuffedUIPlayerBuffs:GetPoint():match("LEFT") or DuffedUIPlayerDebuffs:GetPoint():match("LEFT")) and (name:match("DuffedUIPlayerBuffs") or name:match("DuffedUIPlayerDebuffs")) then
			self:SetAnchorType("ANCHOR_BOTTOMRIGHT", x, -x)
		end
	end

	if (owner == MiniMapBattlefieldFrame or owner == MiniMapMailFrame) and DuffedUIMinimap then
		if DuffedUIMinimap:GetPoint():match("LEFT") then self:SetAnchorType("ANCHOR_TOPRIGHT", x, -x) end
	end

	if self:GetAnchorType() == "ANCHOR_NONE" and DuffedUITooltipAnchor then
		local point = DuffedUITooltipAnchor:GetPoint()
		if point == "TOPLEFT" then
			self:ClearAllPoints()
			self:SetPoint("TOPLEFT", DuffedUITooltipAnchor, "BOTTOMLEFT", 0, -x)
		elseif point == "TOP" then
			self:ClearAllPoints()
			self:SetPoint("TOP", DuffedUITooltipAnchor, "BOTTOM", 0, -x)
		elseif point == "TOPRIGHT" then
			self:ClearAllPoints()
			self:SetPoint("TOPRIGHT", DuffedUITooltipAnchor, "BOTTOMRIGHT", 0, -x)
		elseif point == "BOTTOMLEFT" or point == "LEFT" then
			self:ClearAllPoints()
			self:SetPoint("BOTTOMLEFT", DuffedUITooltipAnchor, "TOPLEFT", 0, x)
		elseif point == "BOTTOMRIGHT" or point == "RIGHT" then
			if DufUIBags and DufUIBags:IsShown() then
				self:ClearAllPoints()
				self:SetPoint("BOTTOMRIGHT", DufUIBags, "TOPRIGHT", 0, x)
			else
				self:ClearAllPoints()
				self:SetPoint("BOTTOMRIGHT", DuffedUITooltipAnchor, "TOPRIGHT", 0, x)
			end
		else
			self:ClearAllPoints()
			self:SetPoint("BOTTOM", DuffedUITooltipAnchor, "TOP", 0, x)
		end
	end
end

local function SetTooltipDefaultAnchor(self, parent)
	if C["tooltip"].cursor == true then
		if parent ~= UIParent then self:SetOwner(parent, "ANCHOR_NONE") else self:SetOwner(parent, "ANCHOR_CURSOR") end
	else
		self:SetOwner(parent, "ANCHOR_NONE")
	end
	self:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -111111, -111111)
end
hooksecurefunc("GameTooltip_SetDefaultAnchor", SetTooltipDefaultAnchor)

GameTooltip:HookScript("OnUpdate", function(self, ...) UpdateTooltip(self) end)

local function Hex(color) return string.format('|cff%02x%02x%02x', color.r * 255, color.g * 255, color.b * 255) end

local function GetColor(unit)
	if (UnitIsPlayer(unit) and not UnitHasVehicleUI(unit)) then
		local class = UnitClass(unit)
		local color = RAID_CLASS_COLORS[class]
		if not color then return end
		local r, g, b = color.r, color.g, color.b
		return Hex(color), r, g, b
	else
		local color = FACTION_BAR_COLORS[UnitReaction(unit, "player")]
		if not color then return end
		local r, g, b = color.r, color.g, color.b
		return Hex(color), r, g, b
	end
end

local function StatusBarOnValueChanged(self, value)
	if not value then return end
	local min, max = self:GetMinMaxValues()
	if (value < min) or (value > max) then return end
	local _, unit = GameTooltip:GetUnit()

	if not unit then
		unit = GetMouseFocus() and GetMouseFocus():GetAttribute("unit")
	end

	if not self.text then
		self.text = self:CreateFontString(nil, "OVERLAY")
		local position = DuffedUITooltipAnchor:GetPoint()
		if position:match("TOP") then self.text:Point("CENTER", GameTooltipStatusBar, 0, -6) else self.text:Point("CENTER", GameTooltipStatusBar, 0, 6) end
		
		self.text:SetFont(C["media"].font, 12, "THINOUTLINE")
		self.text:Show()
		if unit then
			min, max = UnitHealth(unit), UnitHealthMax(unit)
			local hp = D.ShortValue(min) .. " / " .. D.ShortValue(max)
			if UnitIsGhost(unit) then
				self.text:SetText(L.unitframes_ouf_ghost)
			elseif min == 0 or UnitIsDead(unit) or UnitIsGhost(unit) then
				self.text:SetText(L.unitframes_ouf_dead)
			else
				self.text:SetText(hp)
			end
		end
	else
		if unit then
			min, max = UnitHealth(unit), UnitHealthMax(unit)
			self.text:Show()
			local hp = D.ShortValue(min) .. " / " .. D.ShortValue(max)
			if UnitIsGhost(unit) then
				self.text:SetText(L.unitframes_ouf_ghost)
			elseif min == 0 or UnitIsDead(unit) or UnitIsGhost(unit) then
				self.text:SetText(L.unitframes_ouf_dead)
			else
				self.text:SetText(hp)
			end
		else
			self.text:Hide()
		end
	end
end
GameTooltipStatusBar:SetScript("OnValueChanged", StatusBarOnValueChanged)

local healthBar = GameTooltipStatusBar
healthBar:ClearAllPoints()
healthBar:Height(6)
healthBar:Point("BOTTOMLEFT", healthBar:GetParent(), "TOPLEFT", 2, 5)
healthBar:Point("BOTTOMRIGHT", healthBar:GetParent(), "TOPRIGHT", -2, 5)
healthBar:SetStatusBarTexture(C["media"].normTex)

local healthBarBG = CreateFrame("Frame", "StatusBarBG", healthBar)
healthBarBG:SetFrameLevel(healthBar:GetFrameLevel() - 1)
healthBarBG:Point("TOPLEFT", -2, 2)
healthBarBG:Point("BOTTOMRIGHT", 2, -2)
healthBarBG:SetTemplate("Default")

local function OnTooltipSetUnit(self)
	local lines = self:NumLines()
	local unit = (select(2, self:GetUnit())) or (GetMouseFocus() and GetMouseFocus():GetAttribute("unit"))
	if not unit and UnitExists("mouseover") then unit = "mouseover" end
	if not unit then self:Hide() return end
	if (self:GetOwner() ~= UIParent and C["tooltip"].hideuf) then self:Hide() return end
	if (UnitIsUnit(unit,"mouseover")) then unit = "mouseover" end
	local race = UnitRace(unit)
	local class = UnitClass(unit)
	local level = UnitLevel(unit)
	local guild = GetGuildInfo(unit)
	local name, realm = UnitName(unit)
	local crtype = UnitCreatureType(unit)
	local classif = UnitClassification(unit)
	local title = UnitPVPName(unit)
	local r, g, b = GetQuestDifficultyColor(level).r, GetQuestDifficultyColor(level).g, GetQuestDifficultyColor(level).b

	local color = GetColor(unit)
	if not color then color = "|CFFFFFFFF" end
	if not realm then realm = "" end

	if title or name then _G["GameTooltipTextLeft1"]:SetFormattedText("%s%s%s", color, title or name, realm and realm ~= "" and " - "..realm.."|r" or "|r") end

	if(UnitIsPlayer(unit)) then
		if UnitIsAFK(unit) then
			self:AppendText((" %s"):format(CHAT_FLAG_AFK))
		elseif UnitIsDND(unit) then 
			self:AppendText((" %s"):format(CHAT_FLAG_DND))
		end

		local offset = 2
		if guild then
			local guildName, guildRankName, guildRankIndex = GetGuildInfo(unit)
			_G["GameTooltipTextLeft2"]:SetFormattedText("%s [%s]", IsInGuild() and GetGuildInfo("player") == guild and "|cff0090ff"..guild.."|r" or "|cff00ff10"..guild.."|r", "|cffFFD700"..guildRankName.."|r")
			offset = offset + 1
		end

		for i= offset, lines do
			if(_G["GameTooltipTextLeft"..i]:GetText():find("^"..LEVEL)) then
				_G["GameTooltipTextLeft"..i]:SetFormattedText("|cff%02x%02x%02x%s|r %s %s%s", r*255, g*255, b*255, level > 0 and level or "??", race or "", color or "", class or "".."|r")
				break
			end
		end
	else
		for i = 2, lines do
			if((_G["GameTooltipTextLeft"..i]:GetText():find("^"..LEVEL)) or (crtype and _G["GameTooltipTextLeft"..i]:GetText():find("^"..crtype))) then
				if level == -1 and classif == "elite" then classif = "worldboss" end
				_G["GameTooltipTextLeft"..i]:SetFormattedText("|cff%02x%02x%02x%s|r%s %s", r*255, g*255, b*255, classif ~= "worldboss" and level ~= 0 and level or "", classification[classif] or "", crtype or "")
				break
			end
		end
	end

	local pvpLine
	for i = 1, lines do
		local text = _G["GameTooltipTextLeft"..i]:GetText()
		if text and text == PVP_ENABLED then
			pvpLine = _G["GameTooltipTextLeft"..i]
			pvpLine:SetText()
			break
		end
	end

	if UnitExists(unit.."target") and unit ~= "player" then
		local hex, r, g, b = GetColor(unit.."target")
		if not r and not g and not b then r, g, b = 1, 1, 1 end
		GameTooltip:AddLine(UnitName(unit.."target"), r, g, b)
	end
	self.fadeOut = nil
end
GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)

local BorderColor = function(self)
	local unit = (select(2, self:GetUnit())) or (GetMouseFocus() and GetMouseFocus():GetAttribute("unit"))
	local reaction = unit and UnitReaction(unit, "player")
	local player = unit and UnitIsPlayer(unit)
	local tapped = unit and UnitIsTapped(unit)
	local tappedbyme = unit and UnitIsTappedByPlayer(unit)
	local connected = unit and UnitIsConnected(unit)
	local dead = unit and UnitIsDead(unit)
	local r, g, b

	if player then
		local class = select(2, UnitClass(unit))
		local c = D.UnitColor.class[class]
		r, g, b = c[1], c[2], c[3]
		healthBar:SetStatusBarColor(r, g, b)
		healthBarBG:SetBackdropBorderColor(r, g, b)
		self:SetBackdropBorderColor(r, g, b)
	elseif reaction then
		local c = D.UnitColor.reaction[reaction]
		r, g, b = c[1], c[2], c[3]
		healthBar:SetStatusBarColor(r, g, b)
		healthBarBG:SetBackdropBorderColor(r, g, b)
		self:SetBackdropBorderColor(r, g, b)
	else
		local _, link = self:GetItem()
		local quality = link and select(3, GetItemInfo(link))
		if quality and quality >= 2 then
			local r, g, b = GetItemQualityColor(quality)
			self:SetBackdropBorderColor(r, g, b)
		else
			healthBar:SetStatusBarColor(unpack(C["media"].bordercolor))
			healthBarBG:SetBackdropBorderColor(unpack(C["media"].bordercolor))
			self:SetBackdropBorderColor(unpack(C["media"].bordercolor))
		end
	end
	NeedBackdropBorderRefresh = true
end

local SetStyle = function(self)
	self:SetTemplate("Default")
	BorderColor(self)
end

local nilcolor = {1, 1, 1 }
local tapped = {.6, .6, .6 }

local function unitColor(unit)
	if(not unit) then unit = "mouseover" end

	local color
	if(UnitIsPlayer(unit)) then
		color = RAID_CLASS_COLORS[D.Class]
	elseif(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) then
		color = tapped
	else
		local reaction = UnitReaction(unit, "player")
		if(reaction) then color = FACTION_BAR_COLORS[reaction] end
	end

	return (color or nilcolor)
end

local function addAuraInfo(self, caster, spellID)
	if (C["tooltip"].enablecaster and caster) then
		local color = unitColor(caster)
		if color then color = Hex(color) else color = "" end

		GameTooltip:AddLine("Applied by "..color..UnitName(caster))
		GameTooltip:Show()
	end
end

hooksecurefunc(GameTooltip, "SetUnitAura", function(self,...)
	local _,_,_,_,_,_,_, caster,_,_, spellID = UnitAura(...)
	addAuraInfo(self, caster, spellID)
end)

hooksecurefunc(GameTooltip, "SetUnitBuff", function(self,...)
	local _,_,_,_,_,_,_, caster,_,_, spellID = UnitBuff(...)
	addAuraInfo(self, caster, spellID)
end)

hooksecurefunc(GameTooltip, "SetUnitDebuff", function(self,...)
	local _,_,_,_,_,_,_, caster,_,_, spellID = UnitDebuff(...)
	addAuraInfo(self, caster, spellID)
end)

DuffedUITooltip:RegisterEvent("PLAYER_ENTERING_WORLD")
DuffedUITooltip:RegisterEvent("ADDON_LOADED")
DuffedUITooltip:SetScript("OnEvent", function(self, event, addon)
	if event == "PLAYER_ENTERING_WORLD" then
		for _, tt in pairs(Tooltips) do tt:HookScript("OnShow", SetStyle) end

		ItemRefTooltip:HookScript("OnTooltipSetItem", SetStyle)
		ItemRefTooltip:HookScript("OnShow", SetStyle)	
		FriendsTooltip:SetTemplate("Default")
		ItemRefCloseButton:SkinCloseButton()

		self:UnregisterEvent("PLAYER_ENTERING_WORLD")

		local position = DuffedUITooltipAnchor:GetPoint()
		if position:match("TOP") then
			healthBar:ClearAllPoints()
			healthBar:Point("TOPLEFT", healthBar:GetParent(), "BOTTOMLEFT", 2, -5)
			healthBar:Point("TOPRIGHT", healthBar:GetParent(), "BOTTOMRIGHT", -2, -5)
		end

		if C["tooltip"].hidebuttons == true then
			local CombatHideActionButtonsTooltip = function(self)
				if not IsShiftKeyDown() then
					self:Hide()
				end
			end

			hooksecurefunc(GameTooltip, "SetAction", CombatHideActionButtonsTooltip)
			hooksecurefunc(GameTooltip, "SetPetAction", CombatHideActionButtonsTooltip)
			hooksecurefunc(GameTooltip, "SetShapeshift", CombatHideActionButtonsTooltip)
		end
	else
		if addon ~= "Blizzard_DebugTools" then return end

		if FrameStackTooltip then
			FrameStackTooltip:SetScale(C["general"].uiscale)
			FrameStackTooltip:HookScript("OnShow", function(self) self:SetTemplate("Default") end)
		end

		if EventTraceTooltip then EventTraceTooltip:HookScript("OnShow", function(self) self:SetTemplate("Default") end) end
	end
end)