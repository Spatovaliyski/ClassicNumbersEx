-- Get required references from Core module
local animating = ClassicNumbersEx.animating
local soundChannels = ClassicNumbersEx.soundChannels

-------------
-- OPTIONS --
-------------
local menu = {
	name = "Classic Numbers",
	handler = ClassicNumbersEx,
	type = "group",
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
					desc = "Example : a 1200 hit will be displayed as 1,200. Classic wow don't use commas",
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
				smallHitsFilter = {
					type = "range",
					name = "Small hits filter",
					desc = "Hide numbers below this value",
					min = 0,
					max = 10000000,
					step = 1000,
					get = function()
						return ClassicNumbersEx.db.global.smallHitsFilter
					end,
					set = function(_, newValue)
						ClassicNumbersEx.db.global.smallHitsFilter = newValue
					end,
					order = 7,
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
					type = "range",
					name = "Small crits filter",
					desc = "Crits below this value will be displayed as if it was a non crit",
					min = 0,
					max = 10000000,
					step = 1000,
					get = function()
						return ClassicNumbersEx.db.global.smallCritsFilter
					end,
					set = function(_, newValue)
						ClassicNumbersEx.db.global.smallCritsFilter = newValue
					end,
					order = 7,
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

		minimumDamageOptions = {
			type = "group",
			name = "Minimum Damage Threshold",
			order = 6,
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
					type = "range",
					name = "Don't display damage below this amount",
					desc = "Damage below this value will not be displayed",
					disabled = function()
						return not ClassicNumbersEx.db.global.enabled
							or not ClassicNumbersEx.db.global.minimumDamageEnabled
					end,
					min = 0,
					max = 1000000,
					step = 1000,
					get = function()
						return ClassicNumbersEx.db.global.minimumDamageThreshold
					end,
					set = function(_, newValue)
						ClassicNumbersEx.db.global.minimumDamageThreshold = newValue
					end,
					order = 1,
					width = "full",
				},
			},
		},

		CritSound = {
			type = "group",
			name = "Crit sound effect",
			order = 7,
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
					type = "range",
					name = "Damage Threshold to play sound",
					desc = "The critical strike's damage should be higher than X to play the sound",
					disabled = function()
						return not ClassicNumbersEx.db.global.enabled or not ClassicNumbersEx.db.global.critSoundEnabled
					end,
					min = 0,
					max = 10000000,
					step = 1000,
					get = function()
						return ClassicNumbersEx.db.global.critSoundThreshold
					end,
					set = function(_, newValue)
						ClassicNumbersEx.db.global.critSoundThreshold = newValue
					end,
					width = "full",
					order = 1,
				},
				critSoundChannel = {
					type = "select",
					name = "Channel",
					disabled = function()
						return not ClassicNumbersEx.db.global.enabled or not ClassicNumbersEx.db.global.critSoundEnabled
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
			order = 8,
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
					type = "range",
					name = "Damage Threshold to play sound",
					desc = "The critical strike's damage should be higher than X to play the sound",
					disabled = function()
						return not ClassicNumbersEx.db.global.enabled
							or not ClassicNumbersEx.db.global.hugeCritSoundEnabled
					end,
					min = 0,
					max = 10000000,
					step = 1000,
					get = function()
						return ClassicNumbersEx.db.global.hugeCritSoundThreshold
					end,
					set = function(_, newValue)
						ClassicNumbersEx.db.global.hugeCritSoundThreshold = newValue
					end,
					width = "full",
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
}

function ClassicNumbersEx:OpenMenu()
	-- just open to the frame, double call because blizz bug
	LibStub("AceConfigDialog-3.0"):Open("ClassicNumbersEx")
end

function ClassicNumbersEx:RegisterMenu()
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("ClassicNumbersEx", menu)
	self.menu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ClassicNumbersEx", "ClassicNumbersEx")
end
