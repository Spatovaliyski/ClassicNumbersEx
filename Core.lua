-- LIBS --
local AceAddon = LibStub("AceAddon-3.0")
local LibEasing = LibStub("LibEasing-1.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")

ClassicNumbersEx = AceAddon:NewAddon("ClassicNumbersEx", "AceConsole-3.0", "AceEvent-3.0")
ClassicNumbersEx.frame = CreateFrame("Frame", nil, UIParent)

-- LOCALS --
local animating = {}

local playerGUID
local unitToGuid = {}
local guidToUnit = {}

local soundChannels = {
	["Dialog"] = "Dialog",
	["Ambience"] = "Ambience",
	["Music"] = "Music",
	["SFX"] = "SFX",
}

-- DB --
local defaultFont = "Friz Quadrata TT"

local defaults = {
	global = {
		enabled = true,
		personal = false,
		useLegacyOverlapHandler = false,
		font = defaultFont,
		truncate = false,
		commaSeperate = false,
		size = 28,
		critSize = 56,
		maxCritNumbersPerTarget = 4,
		normalHitsAlpha = 1,
		critsAlpha = 1,
		nonCritsOffsetX = 0,
		critsOffsetX = 0,
		nonCritsOffsetY = 0,
		critsOffsetY = 0,
		smallCritsFilter = 0,
		defaultColor = "ffffff",
		defaultAbilityColor = "FFEE00",
		nonCritAnimationDuration = 1.25,
		critAnimationDuration = 2,
		scrollSpeed = 1,
		scrollDistance = 50,
		useDamageSchoolColors = false,
		hideNonCritsIfBigCritChain = true,
		displayBiggestCritInCenterOfTheChain = false,
		biggestCritDisplaysLargerThanOtherOnes = false,
		critSoundEnabled = false,
		critSoundChannel = soundChannels["Dialog"],
		critSoundThreshold = 250,
		hugeCritSoundEnabled = false,
		hugeCritSoundChannel = "Dialog",
		hugeCritSoundThreshold = 3000,
		monsterCritSoundEnabled = false,
		monsterCritSoundChannel = "Dialog",
		monsterCritSoundThreshold = 8000,
		minimumDamageEnabled = false,
		minimumDamageThreshold = 0,
		-- Healing options
		healingEnabled = true,
		healingFriendlyNPCsEnabled = true,
		healingFriendlyPlayersEnabled = true,
		healingFriendlyPetsEnabled = true,
		healSoundEnabled = false,
		healSoundChannel = "Dialog",
		healSoundThreshold = 250,
		hugeHealSoundEnabled = false,
		hugeHealSoundChannel = "Dialog",
		hugeHealSoundThreshold = 3000,
		minimumHealingEnabled = false,
		minimumHealingThreshold = 0,
		personalHealing = true,
		personalHealingOffsetX = 0,
		personalHealingOffsetY = 0,
	},
}

-- CONSTANTS --
local DAMAGE_TYPE_COLORS = {
	[1] = "FFEE00", --physical
	[2] = "FFE680", -- holy
	[4] = "FF8000", --fire
	[8] = "4DFF4D", --nature
	[16] = "80FFFF", --frost
	[32] = "8080FF", --shadow
	[64] = "FF80FF", --arcane
	[4 + 16 + 64 + 8 + 32] = "A330C9",
	[4 + 16 + 64 + 8 + 32 + 2] = "A330C9",
	[1 + 4 + 16 + 64 + 8 + 32 + 2] = "A330C9",
	["melee"] = "FFFFFF",
	["pet"] = "CC8400",
}

-- FONTSTRING --
local function getFontPath(fontName)
	local fontPath = SharedMedia:Fetch("font", fontName)

	if fontPath == nil then
		fontPath = "Fonts\\FRIZQT__.TTF"
	end

	return fontPath
end

local fontStringCache = {}

local function getFontString()
	local fontString

	if next(fontStringCache) then
		fontString = table.remove(fontStringCache)
	else
		fontString = ClassicNumbersEx.frame:CreateFontString()
	end

	fontString:SetParent(ClassicNumbersEx.frame)
	fontString:SetFont(getFontPath(ClassicNumbersEx.db.global.font), 15)
	fontString:SetShadowOffset(2, -2)
	fontString:SetAlpha(1)
	fontString:SetDrawLayer("BACKGROUND", -1)
	fontString:SetText("")
	fontString:Show()

	fontString.hasBeenPlaced = false
	fontString.offsetX = 0
	fontString.offsetY = 0
	fontString.isCritNumber = {}
	fontString.fontHeight = 10
	fontString.textWidth = 10
	fontString.amount = 0
	fontString.critsAlpha = 1
	fontString.normalHitsAlpha = 1
	fontString.maxCritNumbersPerTarget = 4
	fontString.critsOffsetX = 0
	fontString.critsOffsetY = 0
	fontString.nonCritsOffsetX = 0
	fontString.nonCritsOffsetY = 0
	fontString.nonCritAnimationDuration = 1.25
	fontString.critAnimationDuration = 2
	fontString.scrollSpeed = 1
	fontString.scrollDistance = 40
	fontString.hideNonCritsIfBigCritChain = true
	fontString.displayBiggestCritInCenterOfTheChain = false
	fontString.biggestCritDisplaysLargerThanOtherOnes = false

	return fontString
end

local function recycleFontString(fontString)
	fontString:SetAlpha(0)
	fontString:Hide()

	animating[fontString] = nil

	fontString.hasBeenPlaced = nil
	fontString.offsetX = nil
	fontString.offsetY = nil
	fontString.offsetY2 = nil
	fontString.isCritNumber = nil
	fontString.fontHeight = nil
	fontString.textWidth = nil
	fontString.amount = nil
	fontString.critsAlpha = nil
	fontString.normalHitsAlpha = nil
	fontString.maxCritNumbersPerTarget = nil
	fontString.critsOffsetX = nil
	fontString.critsOffsetY = nil
	fontString.nonCritsOffsetX = nil
	fontString.nonCritsOffsetY = nil
	fontString.nonCritAnimationDuration = nil
	fontString.critAnimationDuration = nil
	fontString.scrollSpeed = nil
	fontString.scrollDistance = nil
	fontString.hideNonCritsIfBigCritChain = nil
	fontString.displayBiggestCritInCenterOfTheChain = nil
	fontString.biggestCritDisplaysLargerThanOtherOnes = nil

	fontString.animatingStartTime = nil
	fontString.anchorFrame = nil

	fontString.unit = nil

	fontString.pow = nil
	fontString.isCritical = nil
	fontString.startHeight = nil
	fontString.fontSize = nil
	fontString:ClearAllPoints()

	table.insert(fontStringCache, fontString)
end

-- CORE --
function ClassicNumbersEx:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ClassicNumbersExDB", defaults, true)

	self:RegisterChatCommand("classicnumbers", "OpenMenu")
	self:RegisterChatCommand("classicnumber", "OpenMenu")
	self:RegisterChatCommand("cn", "OpenMenu")

	self:RegisterMenu()

	if self.db.global.enabled == false then
		self:Disable()
	end
end

function ClassicNumbersEx:OnEnable()
	playerGUID = UnitGUID("player")

	self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	self.db.global.enabled = true
end

function ClassicNumbersEx:OnDisable()
	self:UnregisterAllEvents()

	for fontString, _ in pairs(animating) do
		recycleFontString(fontString)
	end

	self.db.global.enabled = false
end

-- EVENTS --
function ClassicNumbersEx:NAME_PLATE_UNIT_ADDED(event, unitID)
	local guid = UnitGUID(unitID)

	unitToGuid[unitID] = guid
	guidToUnit[guid] = unitID
end

function ClassicNumbersEx:NAME_PLATE_UNIT_REMOVED(event, unitID)
	local guid = unitToGuid[unitID]

	unitToGuid[unitID] = nil
	guidToUnit[guid] = nil

	for fontString, _ in pairs(animating) do
		if fontString.unit == unitID then
			recycleFontString(fontString)
		end
	end
end

function ClassicNumbersEx:CombatFilter(_, clue, _, sourceGUID, _, sourceFlags, _, destGUID, _, _, _, ...)
	if playerGUID == sourceGUID or (ClassicNumbersEx.db.global.personal and playerGUID == destGUID) then -- Player events
		local destUnit = guidToUnit[destGUID]
		if destUnit or (destGUID == playerGUID and ClassicNumbersEx.db.global.personal) then
			if string.find(clue, "_DAMAGE") then
				local spellID, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
				if string.find(clue, "SWING") then
					spellName, amount, overkill, school_ignore, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand =
						"ranged", ...
				elseif string.find(clue, "ENVIRONMENTAL") then
					spellName, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...
				else
					spellID, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand =
						...
				end
				self:DamageEvent(destGUID, spellID, amount, school, critical, spellName)
			elseif string.find(clue, "_HEAL") and ClassicNumbersEx.db.global.healingEnabled then
				local spellID, spellName, spellSchool, amount, overhealing, absorbed, critical = ...
				self:HealingEvent(destGUID, spellID, amount, spellSchool, critical, spellName)
			end
		end
	elseif
		(
			bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_GUARDIAN) > 0
			or bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PET) > 0
		) and bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0
	then -- Pet/Guardian events
		local destUnit = guidToUnit[destGUID]
		if destUnit or (destGUID == playerGUID and ClassicNumbersEx.db.global.personal) then
			if string.find(clue, "_DAMAGE") then
				local spellID, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
				if string.find(clue, "SWING") then
					spellName, amount, overkill, school_ignore, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand =
						"pet", ...
				elseif string.find(clue, "ENVIRONMENTAL") then
					spellName, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...
				else
					spellID, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand =
						...
				end
				self:DamageEvent(destGUID, spellID, amount, "pet", critical, spellName)
			elseif string.find(clue, "_HEAL") and ClassicNumbersEx.db.global.healingEnabled then
				local spellID, spellName, spellSchool, amount, overhealing, absorbed, critical = ...
				self:HealingEvent(destGUID, spellID, amount, spellSchool, critical, spellName)
			end
		end
	end
end

function ClassicNumbersEx:COMBAT_LOG_EVENT_UNFILTERED()
	return ClassicNumbersEx:CombatFilter(CombatLogGetCurrentEventInfo())
end

-- UTILITY FUNCTIONS --
function GetBiggestCrit(anchorFrame)
	for fontString, _ in pairs(animating) do
		local biggestCrit = nil

		if fontString.isCritNumber[anchorFrame] ~= nil and fontString.isCritNumber[anchorFrame] > 0 then
			if biggestCrit == nil then
				biggestCrit = fontString
			elseif fontString.amount >= biggestCrit.amount then
				biggestCrit = fontString
			end
		end
	end

	return biggestCrit
end

function OffsetCritIndexes(anchorFrame, offset, resetIndexesBefore)
	local crits = {}
	for fontString, _ in pairs(animating) do
		if fontString.pow and fontString.anchorFrame == anchorFrame then
			if resetIndexesBefore then
				crits[fontString] = true
				fontString.isCritNumber[fontString.anchorFrame] = 0
			else
				fontString.isCritNumber[fontString.anchorFrame] = fontString.isCritNumber[fontString.anchorFrame]
					+ offset
			end
		end
	end

	if resetIndexesBefore then
		local count = 0
		for crit, _ in pairs(crits) do
			count = count + 1
			crit.isCritNumber[crit.anchorFrame] = 1 + count
		end
	end
end

function GetNewestCrit(anchorFrame)
	local newestCrit = nil

	for fontString, _ in pairs(animating) do
		if fontString.anchorFrame == anchorFrame and fontString.isCritNumber[fontString.anchorFrame] == 1 then
			newestCrit = fontString
		end
	end
	return newestCrit
end

function GetFourthCrit(anchorFrame)
	local newestCrit = nil

	for fontString, _ in pairs(animating) do
		if fontString.anchorFrame == anchorFrame and fontString.isCritNumber[fontString.anchorFrame] == 4 then
			newestCrit = fontString
		end
	end
	return newestCrit
end

function GetClosestDamageNumberYValueFrom(fs)
	local closestValue = 999
	local closestFontString = nil

	for fontString, _ in pairs(animating) do
		if fontString.offsetY2 == 0 then
			if fontString ~= fs and not fontString.pow and not fs.pow and fontString.anchorFrame == fs.anchorFrame then
				local difference = math.abs(fontString.offsetY - fs.offsetY)
				if difference < closestValue and fontString.offsetX == fs.offsetX then
					closestValue = difference
					closestFontString = fontString
				end
			end
		else
			if
				fontString ~= fs
				and not fontString.pow
				and not fs.pow
				and fontString.anchorFrame == fs.anchorFrame
				and fontString.offsetY2 == nil
				and fs.offsetY2 == nil
			then
				local difference = math.abs(fontString.offsetY - fs.offsetY)
				if difference < closestValue and fontString.offsetX == fs.offsetX then
					closestValue = difference
					closestFontString = fontString
				end
			end
		end
	end
	return closestFontString
end

-- Export animating table for other modules
ClassicNumbersEx.animating = animating
ClassicNumbersEx.fontStringCache = fontStringCache
ClassicNumbersEx.getFontString = getFontString
ClassicNumbersEx.recycleFontString = recycleFontString
ClassicNumbersEx.DAMAGE_TYPE_COLORS = DAMAGE_TYPE_COLORS
ClassicNumbersEx.guidToUnit = guidToUnit
ClassicNumbersEx.soundChannels = soundChannels

-- HEALING EVENT HANDLER
function ClassicNumbersEx:HealingEvent(destGUID, spellID, amount, spellSchool, critical, spellName)
	if self.db.global.minimumHealingEnabled then
		if amount < self.db.global.minimumHealingThreshold then
			return
		end
	end

	local destUnit = guidToUnit[destGUID]

	if destGUID == playerGUID then
		if self.db.global.personalHealing then
			self:HealingDisplay(destGUID, spellID, amount, spellSchool, critical, spellName)
		end

		if critical then
			self:HandleHealSound(amount)
		end
		return
	end

	if destUnit then
		local shouldShow = false

		if not UnitIsFriend("player", destUnit) then
			return
		end

		if UnitIsPlayer(destUnit) then
			shouldShow = self.db.global.healingFriendlyPlayersEnabled
		elseif UnitPlayerControlled(destUnit) then
			shouldShow = self.db.global.healingFriendlyPetsEnabled
		else
			-- This covers NPCs
			shouldShow = self.db.global.healingFriendlyNPCsEnabled
		end

		if shouldShow then
			self:HealingDisplay(destGUID, spellID, amount, spellSchool, critical, spellName)

			if critical then
				self:HandleHealSound(amount)
			end
		end
	end
end
