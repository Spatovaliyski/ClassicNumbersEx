-- DISPLAY MODULE --

local DAMAGE_TYPE_COLORS = ClassicNumbersEx.DAMAGE_TYPE_COLORS
local guidToUnit = ClassicNumbersEx.guidToUnit
local getFontString = ClassicNumbersEx.getFontString

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
	if crit and playerGUID ~= guid then
		size = self.db.global.critSize
	end

	if pow and amount < self.db.global.smallCritsFilter then
		pow = false
		size = self.db.global.size * 1.5
	end
	if not pow and amount < self.db.global.smallHitsFilter or size == 0 then
		return
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
	if guid ~= playerGUID then
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
end

function ClassicNumbersEx:DisplayText(guid, text, size, animation, pow, amount)
	local fontString
	local unit = guidToUnit[guid]
	local nameplate

	if unit then
		nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	end

	-- if there isn't an anchor frame, make sure that there is a guidNameplatePosition cache entry
	if playerGUID == guid and not unit then
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

	--Sound effects
	if
		ClassicNumbersEx.db.global.critSoundEnabled
		and pow
		and amount > ClassicNumbersEx.db.global.critSoundThreshold
		and (
			not ClassicNumbersEx.db.global.hugeCritSoundEnabled
			or amount < ClassicNumbersEx.db.global.hugeCritSoundThreshold
		)
	then
		PlaySoundFile(
			"Interface\\AddOns\\ClassicNumbersEx\\Media\\Sounds\\Critical.ogg",
			ClassicNumbersEx.db.global.critSoundChannel
		)
	end

	if
		ClassicNumbersEx.db.global.hugeCritSoundEnabled
		and pow
		and amount > ClassicNumbersEx.db.global.hugeCritSoundThreshold
	then
		PlaySoundFile(
			"Interface\\AddOns\\ClassicNumbersEx\\Media\\Sounds\\HugeCritical.ogg",
			ClassicNumbersEx.db.global.hugeCritSoundChannel
		)
	end

	if self.db.global.useLegacyOverlapHandler then
		fontString.offsetY2 = 0
	end

	if fontString.startHeight <= 0 then
		fontString.startHeight = 5
	end

	fontString.unit = unit

	self:Animate(fontString, nameplate, animation)
end
