-- Get required references from Core module
local animating = ClassicNumbersEx.animating
local soundChannels = ClassicNumbersEx.soundChannels

-- Number conversion utility functions
local function ConvertToNumber(text)
	if not text or text == "" then
		return 0
	end

	-- Remove whitespace and convert to lowercase
	text = string.gsub(string.lower(text), "%s", "")

	-- Extract number and suffix
	local number, suffix = string.match(text, "^([%d%.]+)([km]?)$")

	if not number then
		-- Try to parse as plain number
		local plainNumber = tonumber(text)
		return plainNumber or 0
	end

	number = tonumber(number) or 0

	if suffix == "k" then
		return math.floor(number * 1000)
	elseif suffix == "m" then
		return math.floor(number * 1000000)
	else
		return math.floor(number)
	end
end

local function ConvertFromNumber(number)
	if not number or number == 0 then
		return "0"
	end

	if number >= 1000000 and number % 1000000 == 0 then
		return string.format("%.0fm", number / 1000000)
	elseif number >= 1000000 then
		return string.format("%.1fm", number / 1000000)
	elseif number >= 1000 and number % 1000 == 0 then
		return string.format("%.0fk", number / 1000)
	elseif number >= 1000 then
		return string.format("%.1fk", number / 1000)
	else
		return tostring(number)
	end
end

-------------
-- OPTIONS --
-------------
local menu = {
	name = "Classic Numbers",
	handler = ClassicNumbersEx,
	type = "group",
	args = {
		general = {
			type = "group",
			name = "General",
			order = 1,
			args = {
				enable = {
					type = "toggle",
					name = "Enable",
					desc = "If the addon is enabled.",
					get = "IsEnabled",
					set = function(_, newValue)
						if not newValue then
							ClassicNumbersEx:Disable()
						else
							ClassicNumbersEx:Enable()
						end
					end,
					order = 1,
					width = "full",
				},

				disableBlizzardNumbers = {
					type = "toggle",
					name = "Disable Blizzard numbers",
					desc = "Hide Blizzard's default combat text",
					get = function(_, newValue)
						return GetCVar("floatingCombatTextCombatDamage") == "0"
					end,
					set = function(_, newValue)
						if newValue then
							SetCVar("floatingCombatTextCombatDamage", "0")
						else
							SetCVar("floatingCombatTextCombatDamage", "1")
						end
					end,
					order = 2,
					width = "full",
				},

				textStyle = {
					type = "group",
					name = "Text Style",
					order = 3,
					inline = true,
					disabled = function()
						return not ClassicNumbersEx.db.global.enabled
					end,
					args = {
						truncateBigNumbers = {
							type = "toggle",
							name = "Truncate big numbers",
							desc = "Example : a 1200 hit will be displayed as 1.2k",
							get = function()
								return ClassicNumbersEx.db.global.truncate
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.truncate = newValue
							end,
							order = 1,
							width = "full",
						},
						commaSeperate = {
							type = "toggle",
							name = "Comma separate numbers",
							desc = "Example : a 1200 hit will be displayed as 1,200. Classic WoW doesn't use commas",
							get = function()
								return ClassicNumbersEx.db.global.commaSeperate
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.commaSeperate = newValue
							end,
							order = 2,
							width = "full",
						},
						useDamageSchoolColors = {
							type = "toggle",
							name = "Use damage school colors",
							desc = "Fire damage will be orange, frost damage will be blue, etc... if disabled, all abilities damage will be yellow",
							get = function()
								return ClassicNumbersEx.db.global.useDamageSchoolColors
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.useDamageSchoolColors = newValue
							end,
							order = 3,
							width = "full",
						},
						useLegacyOverlapHandler = {
							type = "toggle",
							name = "Use legacy overlap handler",
							desc = "If enabled -> non crits will behave exactly as they did when the addon was first released, if disabled -> non crits will be less likely to overlap",
							get = function()
								return ClassicNumbersEx.db.global.useLegacyOverlapHandler
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.useLegacyOverlapHandler = newValue
							end,
							order = 4,
							width = "full",
						},
						font = {
							type = "select",
							dialogControl = "LSM30_Font",
							name = "Font style",
							order = 5,
							values = AceGUIWidgetLSMlists.font,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.font = newValue
							end,
							get = function()
								return ClassicNumbersEx.db.global.font
							end,
						},
					},
				},

				nonCritTextOptions = {
					type = "group",
					name = "Non critical text options",
					order = 4,
					inline = true,
					disabled = function()
						return not ClassicNumbersEx.db.global.enabled
					end,
					args = {
						size = {
							type = "range",
							name = "Size",
							desc = "Non-crit's Size",
							min = 0,
							max = 72,
							step = 4,
							get = function()
								return ClassicNumbersEx.db.global.size
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.size = newValue
							end,
							order = 1,
						},
						nonCritsOffsetX = {
							type = "range",
							name = "Position Offset X",
							desc = "",
							min = -150,
							max = 150,
							step = 10,
							get = function()
								return ClassicNumbersEx.db.global.nonCritsOffsetX
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.nonCritsOffsetX = newValue
							end,
							order = 2,
						},
						nonCritsOffsetY = {
							type = "range",
							name = "Position Offset Y",
							desc = "",
							min = -150,
							max = 150,
							step = 10,
							get = function()
								return ClassicNumbersEx.db.global.nonCritsOffsetY
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.nonCritsOffsetY = newValue
							end,
							order = 3,
						},
						scrollDistance = {
							type = "range",
							name = "Scroll Distance",
							desc = "",
							min = -100,
							max = 100,
							step = 10,
							get = function()
								return ClassicNumbersEx.db.global.scrollDistance
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.scrollDistance = newValue
							end,
							order = 4,
						},
						normalHitsAlpha = {
							type = "range",
							name = "Transparent <-> Opaque",
							desc = "0 : fully transparent, 1 : fully opaque",
							min = 0,
							max = 1,
							step = 0.1,
							get = function()
								return ClassicNumbersEx.db.global.normalHitsAlpha
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.normalHitsAlpha = newValue
							end,
							order = 5,
						},
						nonCritAnimationDuration = {
							type = "range",
							name = "Display duration (seconds)",
							min = 0,
							max = 5,
							step = 0.25,
							get = function()
								return ClassicNumbersEx.db.global.nonCritAnimationDuration
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.nonCritAnimationDuration = newValue
							end,
							order = 6,
						},
					},
				},

				CritTextOptions = {
					type = "group",
					name = "Critical text options",
					order = 5,
					inline = true,
					disabled = function()
						return not ClassicNumbersEx.db.global.enabled
					end,
					args = {
						hideNonCritsIfBigCritChain = {
							type = "toggle",
							name = "Hide non crits on big crit chain",
							desc = "Temporarly hide normal hits if having rapid flow of critical strikes",
							get = function()
								return ClassicNumbersEx.db.global.hideNonCritsIfBigCritChain
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.hideNonCritsIfBigCritChain = newValue
							end,
							order = 0,
							width = "full",
						},
						critSize = {
							type = "range",
							name = "Size",
							desc = "",
							min = 0,
							max = 72,
							step = 3,
							get = function()
								return ClassicNumbersEx.db.global.critSize
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.critSize = newValue
							end,
							order = 1,
						},

						critsOffsetX = {
							type = "range",
							name = "Position Offset X",
							desc = "",
							min = -150,
							max = 150,
							step = 10,
							get = function()
								return ClassicNumbersEx.db.global.critsOffsetX
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.critsOffsetX = newValue
							end,
							order = 2,
						},
						critsOffsetY = {
							type = "range",
							name = "Position Offset Y",
							desc = "",
							min = -150,
							max = 150,
							step = 10,
							get = function()
								return ClassicNumbersEx.db.global.critsOffsetY
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.critsOffsetY = newValue
							end,
							order = 3,
						},

						critsAlpha = {
							type = "range",
							name = "Transparent <-> Opaque",
							desc = "0 : fully transparent, 1 : fully opaque",
							min = 0,
							max = 1,
							step = 0.1,
							get = function()
								return ClassicNumbersEx.db.global.critsAlpha
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.critsAlpha = newValue
							end,
							order = 5,
						},

						critAnimationDuration = {
							type = "range",
							name = "Display duration (seconds)",
							min = 0,
							max = 5,
							step = 0.25,
							get = function()
								return ClassicNumbersEx.db.global.critAnimationDuration
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.critAnimationDuration = newValue
							end,
							order = 6,
						},

						smallCritsFilter = {
							type = "input",
							name = "Small crits filter",
							desc = "Crits below this value will be displayed as if it was a non crit (supports k/m suffixes, e.g., 20k, 2m)",
							get = function()
								return ConvertFromNumber(ClassicNumbersEx.db.global.smallCritsFilter)
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.smallCritsFilter = ConvertToNumber(newValue)
							end,
							order = 7,
							width = 250,
						},
						maxCritNumbersPerTarget = {
							type = "range",
							name = "Max crits displayed per target",
							desc = "Max number of crits displayed on a target",
							min = 1,
							max = 5,
							step = 1,
							get = function()
								return ClassicNumbersEx.db.global.maxCritNumbersPerTarget
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.maxCritNumbersPerTarget = newValue
							end,
							order = 4,
						},
					},
				},
			},
		},

		damage = {
			type = "group",
			name = "Damage",
			order = 2,
			args = {
				minimumDamageOptions = {
					type = "group",
					name = "Minimum Damage Threshold",
					order = 1,
					inline = true,
					disabled = function()
						return not ClassicNumbersEx.db.global.enabled
					end,
					args = {
						minimumDamageEnabled = {
							type = "toggle",
							name = "Enabled",
							desc = "Enable the minimum damage threshold",
							get = function()
								return ClassicNumbersEx.db.global.minimumDamageEnabled
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.minimumDamageEnabled = newValue
							end,
							order = 0,
							width = "full",
						},
						minimumDamageThreshold = {
							type = "input",
							name = "Don't display damage below this amount",
							desc = "Damage below this value will not be displayed (supports k/m suffixes, e.g., 20k, 2m)",
							disabled = function()
								return not ClassicNumbersEx.db.global.enabled
									or not ClassicNumbersEx.db.global.minimumDamageEnabled
							end,
							get = function()
								return ConvertFromNumber(ClassicNumbersEx.db.global.minimumDamageThreshold)
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.minimumDamageThreshold = ConvertToNumber(newValue)
							end,
							order = 1,
							width = 250,
						},
					},
				},

				CritSound = {
					type = "group",
					name = "Crit sound effect",
					order = 2,
					inline = true,
					disabled = function()
						return not ClassicNumbersEx.db.global.enabled
					end,
					args = {
						critSoundEnabled = {
							type = "toggle",
							name = "Enabled",
							desc = "Enable playing a sound effect when doing a critical strike above the threshold",
							get = function()
								return ClassicNumbersEx.db.global.critSoundEnabled
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.critSoundEnabled = newValue
							end,
							order = 0,
							width = "full",
						},
						critSoundThreshold = {
							type = "input",
							name = "Damage Threshold to play sound",
							desc = "The critical strike's damage should be higher than X to play the sound (supports k/m suffixes, e.g., 20k, 2m)",
							disabled = function()
								return not ClassicNumbersEx.db.global.enabled
									or not ClassicNumbersEx.db.global.critSoundEnabled
							end,
							get = function()
								return ConvertFromNumber(ClassicNumbersEx.db.global.critSoundThreshold)
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.critSoundThreshold = ConvertToNumber(newValue)
							end,
							width = 250,
							order = 1,
						},
						critSoundChannel = {
							type = "select",
							name = "Channel",
							disabled = function()
								return not ClassicNumbersEx.db.global.enabled
									or not ClassicNumbersEx.db.global.critSoundEnabled
							end,
							get = function()
								return ClassicNumbersEx.db.global.critSoundChannel
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.critSoundChannel = newValue
							end,
							values = soundChannels,
							width = "full",
							order = 2,
						},
					},
				},

				HugeCritSound = {
					type = "group",
					name = "HUGE Crit sound effect",
					order = 3,
					inline = true,
					disabled = function()
						return not ClassicNumbersEx.db.global.enabled
					end,
					args = {
						hugeCritSoundEnabled = {
							type = "toggle",
							name = "Enabled",
							desc = "Enable playing a bigger sound effect when doing a critical strike above the threshold",
							get = function()
								return ClassicNumbersEx.db.global.hugeCritSoundEnabled
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.hugeCritSoundEnabled = newValue
							end,
							order = 0,
							width = "full",
						},
						hugeCritSoundThreshold = {
							type = "input",
							name = "Damage Threshold to play sound",
							desc = "The critical strike's damage should be higher than X to play the sound (supports k/m suffixes, e.g., 20k, 2m)",
							disabled = function()
								return not ClassicNumbersEx.db.global.enabled
									or not ClassicNumbersEx.db.global.hugeCritSoundEnabled
							end,
							get = function()
								return ConvertFromNumber(ClassicNumbersEx.db.global.hugeCritSoundThreshold)
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.hugeCritSoundThreshold = ConvertToNumber(newValue)
							end,
							width = 250,
							order = 1,
						},
						hugeCritSoundChannel = {
							type = "select",
							name = "Channel",
							disabled = function()
								return not ClassicNumbersEx.db.global.enabled
									or not ClassicNumbersEx.db.global.hugeCritSoundEnabled
							end,
							get = function()
								return ClassicNumbersEx.db.global.hugeCritSoundChannel
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.hugeCritSoundChannel = newValue
							end,
							values = soundChannels,
							width = "full",
							order = 2,
						},
					},
				},
			},
		},

		healing = {
			type = "group",
			name = "Healing",
			order = 3,
			args = {
				healingGeneral = {
					type = "group",
					name = "General Healing Options",
					order = 1,
					inline = true,
					disabled = function()
						return not ClassicNumbersEx.db.global.enabled
					end,
					args = {
						healingEnabled = {
							type = "toggle",
							name = "Enable Healing Numbers",
							desc = "Enable healing numbers display",
							get = function()
								return ClassicNumbersEx.db.global.healingEnabled
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.healingEnabled = newValue
							end,
							order = 0,
							width = "full",
						},
						showFriendlyNameplates = {
							type = "toggle",
							name = "Enable Friendly Nameplates",
							desc = "Toggle friendly nameplates on/off for ALL targets (changes interface setting)\nREQUIRED: Must be enabled to see healing numbers on any friendly targets\nThis shows nameplates for all friendlies, not just your current target",
							disabled = function()
								return not ClassicNumbersEx.db.global.enabled
									or not ClassicNumbersEx.db.global.healingEnabled
							end,
							get = function()
								return GetCVar("nameplateShowFriends") == "1"
							end,
							set = function(_, newValue)
								if newValue then
									SetCVar("nameplateShowFriends", "1")
									-- Also enable always show nameplates to ensure they appear
									SetCVar("nameplateShowAll", "1")
								else
									SetCVar("nameplateShowFriends", "0")
								end
							end,
							order = 1,
							width = "full",
						},
						showFriendlyNameplatesPets = {
							type = "toggle",
							name = "Enable Friendly Pet Nameplates",
							desc = "Toggle friendly pet nameplates on/off (changes interface setting)",
							disabled = function()
								return not ClassicNumbersEx.db.global.enabled
									or not ClassicNumbersEx.db.global.healingEnabled
							end,
							get = function()
								return GetCVar("nameplateShowFriendlyPets") == "1"
							end,
							set = function(_, newValue)
								if newValue then
									SetCVar("nameplateShowFriendlyPets", "1")
								else
									SetCVar("nameplateShowFriendlyPets", "0")
								end
							end,
							order = 1.5,
							width = "full",
						},
						personalHealing = {
							type = "toggle",
							name = "Show Personal Healing",
							desc = "Show healing numbers when you heal yourself",
							disabled = function()
								return not ClassicNumbersEx.db.global.enabled
									or not ClassicNumbersEx.db.global.healingEnabled
							end,
							get = function()
								return ClassicNumbersEx.db.global.personalHealing
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.personalHealing = newValue
							end,
							order = 2,
							width = "full",
						},
						personalHealingOffsetX = {
							type = "range",
							name = "Personal Healing Position X",
							desc = "Horizontal offset for personal healing numbers",
							min = -500,
							max = 500,
							step = 10,
							disabled = function()
								return not ClassicNumbersEx.db.global.enabled
									or not ClassicNumbersEx.db.global.healingEnabled
									or not ClassicNumbersEx.db.global.personalHealing
							end,
							get = function()
								return ClassicNumbersEx.db.global.personalHealingOffsetX
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.personalHealingOffsetX = newValue
							end,
							order = 2.1,
						},
						personalHealingOffsetY = {
							type = "range",
							name = "Personal Healing Position Y",
							desc = "Vertical offset for personal healing numbers",
							min = -500,
							max = 500,
							step = 10,
							disabled = function()
								return not ClassicNumbersEx.db.global.enabled
									or not ClassicNumbersEx.db.global.healingEnabled
									or not ClassicNumbersEx.db.global.personalHealing
							end,
							get = function()
								return ClassicNumbersEx.db.global.personalHealingOffsetY
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.personalHealingOffsetY = newValue
							end,
							order = 2.2,
						},
					},
				},

				healingTargets = {
					type = "group",
					name = "Healing Target Types",
					order = 3,
					inline = true,
					disabled = function()
						return not ClassicNumbersEx.db.global.enabled or not ClassicNumbersEx.db.global.healingEnabled
					end,
					args = {
						healingFriendlyPlayersEnabled = {
							type = "toggle",
							name = "Friendly Players",
							desc = "Show healing numbers on friendly players",
							get = function()
								return ClassicNumbersEx.db.global.healingFriendlyPlayersEnabled
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.healingFriendlyPlayersEnabled = newValue
							end,
							order = 1,
							width = "full",
						},
						healingFriendlyNPCsEnabled = {
							type = "toggle",
							name = "Friendly NPCs",
							desc = "Show healing numbers on friendly NPCs",
							get = function()
								return ClassicNumbersEx.db.global.healingFriendlyNPCsEnabled
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.healingFriendlyNPCsEnabled = newValue
							end,
							order = 2,
							width = "full",
						},
						healingFriendlyPetsEnabled = {
							type = "toggle",
							name = "Friendly Pets",
							desc = "Show healing numbers on friendly pets and minions",
							get = function()
								return ClassicNumbersEx.db.global.healingFriendlyPetsEnabled
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.healingFriendlyPetsEnabled = newValue
							end,
							order = 3,
							width = "full",
						},
					},
				},

				minimumHealingOptions = {
					type = "group",
					name = "Minimum Healing Threshold",
					order = 4,
					inline = true,
					disabled = function()
						return not ClassicNumbersEx.db.global.enabled or not ClassicNumbersEx.db.global.healingEnabled
					end,
					args = {
						minimumHealingEnabled = {
							type = "toggle",
							name = "Enabled",
							desc = "Enable the minimum healing threshold",
							get = function()
								return ClassicNumbersEx.db.global.minimumHealingEnabled
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.minimumHealingEnabled = newValue
							end,
							order = 0,
							width = "full",
						},
						minimumHealingThreshold = {
							type = "input",
							name = "Don't display healing below this amount",
							desc = "Healing below this value will not be displayed (supports k/m suffixes, e.g., 20k, 2m)",
							disabled = function()
								return not ClassicNumbersEx.db.global.enabled
									or not ClassicNumbersEx.db.global.healingEnabled
									or not ClassicNumbersEx.db.global.minimumHealingEnabled
							end,
							get = function()
								return ConvertFromNumber(ClassicNumbersEx.db.global.minimumHealingThreshold)
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.minimumHealingThreshold = ConvertToNumber(newValue)
							end,
							order = 1,
							width = 250,
						},
					},
				},

				HealSound = {
					type = "group",
					name = "Heal sound effect",
					order = 5,
					inline = true,
					disabled = function()
						return not ClassicNumbersEx.db.global.enabled or not ClassicNumbersEx.db.global.healingEnabled
					end,
					args = {
						healSoundEnabled = {
							type = "toggle",
							name = "Enabled",
							desc = "Enable playing a sound effect when doing a critical heal above the threshold",
							get = function()
								return ClassicNumbersEx.db.global.healSoundEnabled
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.healSoundEnabled = newValue
							end,
							order = 0,
							width = "full",
						},
						healSoundThreshold = {
							type = "input",
							name = "Healing Threshold to play sound",
							desc = "The critical heal's amount should be higher than X to play the sound (supports k/m suffixes, e.g., 20k, 2m)",
							disabled = function()
								return not ClassicNumbersEx.db.global.enabled
									or not ClassicNumbersEx.db.global.healingEnabled
									or not ClassicNumbersEx.db.global.healSoundEnabled
							end,
							get = function()
								return ConvertFromNumber(ClassicNumbersEx.db.global.healSoundThreshold)
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.healSoundThreshold = ConvertToNumber(newValue)
							end,
							width = 250,
							order = 1,
						},
						healSoundChannel = {
							type = "select",
							name = "Channel",
							disabled = function()
								return not ClassicNumbersEx.db.global.enabled
									or not ClassicNumbersEx.db.global.healingEnabled
									or not ClassicNumbersEx.db.global.healSoundEnabled
							end,
							get = function()
								return ClassicNumbersEx.db.global.healSoundChannel
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.healSoundChannel = newValue
							end,
							values = soundChannels,
							width = "full",
							order = 2,
						},
					},
				},

				HugeHealSound = {
					type = "group",
					name = "HUGE Heal sound effect",
					order = 6,
					inline = true,
					disabled = function()
						return not ClassicNumbersEx.db.global.enabled or not ClassicNumbersEx.db.global.healingEnabled
					end,
					args = {
						hugeHealSoundEnabled = {
							type = "toggle",
							name = "Enabled",
							desc = "Enable playing a bigger sound effect when doing a critical heal above the threshold",
							get = function()
								return ClassicNumbersEx.db.global.hugeHealSoundEnabled
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.hugeHealSoundEnabled = newValue
							end,
							order = 0,
							width = "full",
						},
						hugeHealSoundThreshold = {
							type = "input",
							name = "Healing Threshold to play sound",
							desc = "The critical heal's amount should be higher than X to play the sound (supports k/m suffixes, e.g., 20k, 2m)",
							disabled = function()
								return not ClassicNumbersEx.db.global.enabled
									or not ClassicNumbersEx.db.global.healingEnabled
									or not ClassicNumbersEx.db.global.hugeHealSoundEnabled
							end,
							get = function()
								return ConvertFromNumber(ClassicNumbersEx.db.global.hugeHealSoundThreshold)
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.hugeHealSoundThreshold = ConvertToNumber(newValue)
							end,
							width = 250,
							order = 1,
						},
						hugeHealSoundChannel = {
							type = "select",
							name = "Channel",
							disabled = function()
								return not ClassicNumbersEx.db.global.enabled
									or not ClassicNumbersEx.db.global.healingEnabled
									or not ClassicNumbersEx.db.global.hugeHealSoundEnabled
							end,
							get = function()
								return ClassicNumbersEx.db.global.hugeHealSoundChannel
							end,
							set = function(_, newValue)
								ClassicNumbersEx.db.global.hugeHealSoundChannel = newValue
							end,
							values = soundChannels,
							width = "full",
							order = 2,
						},
					},
				},
			},
		},
	},
}

function ClassicNumbersEx:OpenMenu()
	-- just open to the frame, double call because blizz bug
	LibStub("AceConfigDialog-3.0"):Open("ClassicNumbersEx")
end

function ClassicNumbersEx:RegisterMenu()
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("ClassicNumbersEx", menu)
	self.menu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ClassicNumbersEx", "ClassicNumbersEx")
end
