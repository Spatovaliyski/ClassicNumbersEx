-- DISPLAY MODULE --

local DAMAGE_TYPE_COLORS = ClassicNumbersEx.DAMAGE_TYPE_COLORS
local guidToUnit = ClassicNumbersEx.guidToUnit
local getFontString = ClassicNumbersEx.getFontString

-- Function to get current playerGUID
local function getPlayerGUID()
	return UnitGUID("player")
end

-- HELPER FUNCTION --
local function getFontPath(fontName)
	local fontPath = LibStub("LibSharedMedia-3.0"):Fetch("font", fontName)

	if fontPath == nil then
		fontPath = "Fonts\\FRIZQT__.TTF"
	end

	return fontPath
end

-- DISPLAY --
local function commaSeperate(number)
	local _, _, minus, int, fraction = tostring(number):find("([-]?)(%d+)([.]?%d*)")
	int = int:reverse():gsub("(%d%d%d)", "%1,")
	return minus .. int:reverse():gsub("^,", "") .. fraction
end

function ClassicNumbersEx:DamageEvent(guid, spellID, amount, school, crit, spellName)
	-- Check if the damage is below the minimum threshold
	if self.db.global.minimumDamageEnabled then
		if amount < self.db.global.minimumDamageThreshold then
			return -- Don't display the damage number
		end
	end

	local text, animation, pow, size, icon
	local autoattack = not spellID or spellID == 75

	pow = crit

	local unit = guidToUnit[guid]
	local isTarget = unit and UnitIsUnit(unit, "target")

	size = ClassicNumbersEx.db.global.size

	if pow and amount < self.db.global.smallCritsFilter then
		pow = false
		size = self.db.global.size * 1.5
	elseif crit and getPlayerGUID() ~= guid then
		size = self.db.global.critSize
	end

	-- truncate
	if self.db.global.truncate and amount >= 1000000 then
		text = string.format("%.1fM", amount / 1000000)
	elseif self.db.global.truncate and amount >= 10000 then
		text = string.format("%.0f", amount / 1000)
		text = text .. "k"
	elseif self.db.global.truncate and amount >= 1000 then
		text = string.format("%.1f", amount / 1000)
		text = text .. "k"
	else
		if self.db.global.commaSeperate then
			text = commaSeperate(amount)
		else
			text = tostring(amount)
		end
	end

	-- color text
	if guid ~= getPlayerGUID() then
		if autoattack then
			text = "|Cff" .. self.db.global.defaultColor .. text .. "|r"
		elseif school and DAMAGE_TYPE_COLORS[school] then
			if self.db.global.useDamageSchoolColors then
				text = "|Cff" .. DAMAGE_TYPE_COLORS[school] .. text .. "|r"
			else
				text = "|Cff" .. self.db.global.defaultAbilityColor .. text .. "|r"
			end
		elseif spellName == "melee" and DAMAGE_TYPE_COLORS[spellName] then
			text = "|Cff" .. DAMAGE_TYPE_COLORS[spellName] .. text .. "|r"
		else
			text = "|Cff" .. self.db.global.defaultColor .. text .. "|r"
		end
	else
		if self.db.global.damageColorPersonal and school and DAMAGE_TYPE_COLORS[school] then
			text = "|Cff" .. DAMAGE_TYPE_COLORS[school] .. text .. "|r"
		elseif self.db.global.damageColorPersonal and spellName == "melee" and DAMAGE_TYPE_COLORS[spellName] then
			text = "|Cff" .. DAMAGE_TYPE_COLORS[spellName] .. text .. "|r"
		else
			text = "|Cff" .. self.db.global.defaultColor .. text .. "|r"
		end
	end

	self:DisplayText(guid, text, size, animation, pow, amount)

	-- Play critical damage sound (following AudibleCrits pattern)
	if crit then
		self:HandleCritSound(amount)
	end
end

function ClassicNumbersEx:HealingDisplay(guid, spellID, amount, school, crit, spellName)
	-- Check if the heal is below the minimum threshold
	if self.db.global.minimumHealingEnabled then
		if amount < self.db.global.minimumHealingThreshold then
			return -- Don't display the healing number
		end
	end

	local text, animation, pow, size, icon
	local autoattack = false -- Healing is never auto-attack

	pow = crit

	local unit = guidToUnit[guid]
	local isTarget = unit and UnitIsUnit(unit, "target")

	size = ClassicNumbersEx.db.global.size

	if pow and amount < self.db.global.smallCritsFilter then
		pow = false
		size = self.db.global.size * 1.5
	elseif crit and getPlayerGUID() ~= guid then
		size = self.db.global.critSize
	end

	-- truncate
	if self.db.global.truncate and amount >= 1000000 then
		text = string.format("%.1fM", amount / 1000000)
	elseif self.db.global.truncate and amount >= 10000 then
		text = string.format("%.0f", amount / 1000)
		text = text .. "k"
	elseif self.db.global.truncate and amount >= 1000 then
		text = string.format("%.1f", amount / 1000)
		text = text .. "k"
	else
		if self.db.global.commaSeperate then
			text = commaSeperate(amount)
		else
			text = tostring(amount)
		end
	end

	-- color text for healing (use green color)
	text = "|Cff00FF00" .. text .. "|r" -- Green color for healing

	self:DisplayHealingText(guid, text, size, animation, pow, amount)
end

function ClassicNumbersEx:DisplayHealingText(guid, text, size, animation, pow, amount)
	local fontString
	local unit = guidToUnit[guid]
	local nameplate

	if unit then
		nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	end

	-- Handle personal healing positioning
	if getPlayerGUID() == guid and not unit then
		nameplate = player
	elseif not nameplate then
		return
	end

	fontString = getFontString()

	fontString.text = text
	fontString:SetText(fontString.text)

	fontString.fontSize = size
	fontString:SetFont(
		getFontPath(ClassicNumbersEx.db.global.font),
		fontString.fontSize,
		ClassicNumbersEx.db.global.fontFlag
	)
	fontString:SetShadowOffset(2, -2)
	fontString.startHeight = fontString:GetStringHeight()
	fontString.pow = pow
	fontString.fontHeight = size
	fontString.amount = amount
	fontString.textWidth = size / 2 * math.log10(amount)
	fontString.maxCritNumbersPerTarget = ClassicNumbersEx.db.global.maxCritNumbersPerTarget
	fontString.critsAlpha = ClassicNumbersEx.db.global.critsAlpha
	fontString.normalHitsAlpha = ClassicNumbersEx.db.global.normalHitsAlpha

	-- Apply personal healing positioning if this is personal healing
	if getPlayerGUID() == guid then
		fontString.nonCritsOffsetX = ClassicNumbersEx.db.global.personalHealingOffsetX
		fontString.nonCritsOffsetY = ClassicNumbersEx.db.global.personalHealingOffsetY
		fontString.critsOffsetX = ClassicNumbersEx.db.global.personalHealingOffsetX
		fontString.critsOffsetY = ClassicNumbersEx.db.global.personalHealingOffsetY
	else
		fontString.nonCritsOffsetX = ClassicNumbersEx.db.global.nonCritsOffsetX
		fontString.nonCritsOffsetY = ClassicNumbersEx.db.global.nonCritsOffsetY
		fontString.critsOffsetX = ClassicNumbersEx.db.global.critsOffsetX
		fontString.critsOffsetY = ClassicNumbersEx.db.global.critsOffsetY
	end

	fontString.nonCritAnimationDuration = ClassicNumbersEx.db.global.nonCritAnimationDuration
	fontString.critAnimationDuration = ClassicNumbersEx.db.global.critAnimationDuration
	fontString.scrollSpeed = ClassicNumbersEx.db.global.scrollSpeed
	fontString.scrollDistance = ClassicNumbersEx.db.global.scrollDistance
	fontString.hideNonCritsIfBigCritChain = ClassicNumbersEx.db.global.hideNonCritsIfBigCritChain
	fontString.displayBiggestCritInCenterOfTheChain = ClassicNumbersEx.db.global.displayBiggestCritInCenterOfTheChain
	fontString.biggestCritDisplaysLargerThanOtherOnes =
		ClassicNumbersEx.db.global.biggestCritDisplaysLargerThanOtherOnes

	if self.db.global.useLegacyOverlapHandler then
		fontString.offsetY2 = 0
	end

	if fontString.startHeight <= 0 then
		fontString.startHeight = 5
	end

	fontString.unit = unit

	self:Animate(fontString, nameplate, animation)
end

function ClassicNumbersEx:DisplayText(guid, text, size, animation, pow, amount)
	local fontString
	local unit = guidToUnit[guid]
	local nameplate

	if unit then
		nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	end

	-- if there isn't an anchor frame, make sure that there is a guidNameplatePosition cache entry
	if getPlayerGUID() == guid and not unit then
		nameplate = player
	elseif not nameplate then
		return
	end

	fontString = getFontString()

	fontString.text = text
	fontString:SetText(fontString.text)

	fontString.fontSize = size
	fontString:SetFont(
		getFontPath(ClassicNumbersEx.db.global.font),
		fontString.fontSize,
		ClassicNumbersEx.db.global.fontFlag
	)
	fontString:SetShadowOffset(2, -2)
	fontString.startHeight = fontString:GetStringHeight()
	fontString.pow = pow
	fontString.fontHeight = size
	fontString.amount = amount
	fontString.textWidth = size / 2 * math.log10(amount)
	fontString.maxCritNumbersPerTarget = ClassicNumbersEx.db.global.maxCritNumbersPerTarget
	fontString.critsAlpha = ClassicNumbersEx.db.global.critsAlpha
	fontString.normalHitsAlpha = ClassicNumbersEx.db.global.normalHitsAlpha
	fontString.nonCritsOffsetX = ClassicNumbersEx.db.global.nonCritsOffsetX
	fontString.nonCritsOffsetY = ClassicNumbersEx.db.global.nonCritsOffsetY
	fontString.critsOffsetX = ClassicNumbersEx.db.global.critsOffsetX
	fontString.critsOffsetY = ClassicNumbersEx.db.global.critsOffsetY
	fontString.nonCritAnimationDuration = ClassicNumbersEx.db.global.nonCritAnimationDuration
	fontString.critAnimationDuration = ClassicNumbersEx.db.global.critAnimationDuration
	fontString.scrollSpeed = ClassicNumbersEx.db.global.scrollSpeed
	fontString.scrollDistance = ClassicNumbersEx.db.global.scrollDistance
	fontString.hideNonCritsIfBigCritChain = ClassicNumbersEx.db.global.hideNonCritsIfBigCritChain
	fontString.displayBiggestCritInCenterOfTheChain = ClassicNumbersEx.db.global.displayBiggestCritInCenterOfTheChain
	fontString.biggestCritDisplaysLargerThanOtherOnes =
		ClassicNumbersEx.db.global.biggestCritDisplaysLargerThanOtherOnes

	if self.db.global.useLegacyOverlapHandler then
		fontString.offsetY2 = 0
	end

	if fontString.startHeight <= 0 then
		fontString.startHeight = 5
	end

	fontString.unit = unit

	self:Animate(fontString, nameplate, animation)
end

-- Sound handler functions following the pattern from AudibleCrits
function ClassicNumbersEx:HandleCritSound(amount)
	if self.db.global.critSoundEnabled and amount >= self.db.global.critSoundThreshold then
		if not self.db.global.hugeCritSoundEnabled or amount < self.db.global.hugeCritSoundThreshold then
			PlaySoundFile(
				"Interface\\AddOns\\ClassicNumbersEx\\Media\\Sounds\\Critical.ogg",
				self.db.global.critSoundChannel
			)
		elseif self.db.global.hugeCritSoundEnabled and amount >= self.db.global.hugeCritSoundThreshold then
			PlaySoundFile(
				"Interface\\AddOns\\ClassicNumbersEx\\Media\\Sounds\\HugeCritical.ogg",
				self.db.global.hugeCritSoundChannel
			)
		end
	end
end

function ClassicNumbersEx:HandleHealSound(amount)
	if self.db.global.healSoundEnabled and amount >= self.db.global.healSoundThreshold then
		if not self.db.global.hugeHealSoundEnabled or amount < self.db.global.hugeHealSoundThreshold then
			PlaySoundFile(
				"Interface\\AddOns\\ClassicNumbersEx\\Media\\Sounds\\Heal.ogg",
				self.db.global.healSoundChannel
			)
		elseif self.db.global.hugeHealSoundEnabled and amount >= self.db.global.hugeHealSoundThreshold then
			PlaySoundFile(
				"Interface\\AddOns\\ClassicNumbersEx\\Media\\Sounds\\HugeHeal.ogg",
				self.db.global.hugeHealSoundChannel
			)
		end
	end
end
