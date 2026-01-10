local addonName = "DeckSuite"

local defaults = {
	profile = {
		unitFrames = {
			horizontalOffset = 0,
			verticalOffset = 0,
            comboPointVerticalOffset = 0,
            comboPointFrameScale = 1.0,
			ultraHardcoreMode = false,
		},
	}
}

local options = {
	name = "DeckSuite",
	type = "group",
	args = {
		unitFrames = {
			name = "Unit Frames",
			type = "group",
			order = 1,
			args = {
				header = {
					type = "header",
					name = "Unit Frame Settings",
					order = 1,
				},
				description = {
					type = "description",
					name = "Adjust the position of player and target frames.",
					order = 2,
				},
                ultraHardcoreMode = {
					type = "toggle",
					name = "Ultra Hardcore Mode",
					desc = "Hide health and power bars, showing only the player name and 3D portrait.",
					order = 3,
					width = "full",
					get = function(info)
						return DeckSuite.db.profile.unitFrames.ultraHardcoreMode
					end,
					set = function(info, value)
						DeckSuite.db.profile.unitFrames.ultraHardcoreMode = value
						DeckSuite_UpdateUnitFrameBars()
					end,
				},
				horizontalOffset = {
					type = "range",
					name = "Horizontal Offset",
					desc = "Adjust distance from center. Positive values bring frames closer together, negative values move them farther apart.",
					min = -375,
					max = 100,
					step = 5,
					order = 4,
					width = "full",
					get = function(info)
						return DeckSuite.db.profile.unitFrames.horizontalOffset
					end,
					set = function(info, value)
						DeckSuite.db.profile.unitFrames.horizontalOffset = value
						DeckSuite_UpdateUnitFramePositions()
					end,
				},
				verticalOffset = {
					type = "range",
					name = "Vertical Offset",
					desc = "Adjust distance from the starting position of the frames vertically to be higher or lower.",
					min = -40,
					max = 250,
					step = 5,
					order = 5,
					width = "full",
					get = function(info)
						return DeckSuite.db.profile.unitFrames.verticalOffset
					end,
					set = function(info, value)
						DeckSuite.db.profile.unitFrames.verticalOffset = value
						DeckSuite_UpdateUnitFramePositions()
					end,
				},
				comboPointVerticalOffset = {
					type = "range",
					name = "Combo Point Vertical Offset",
					desc = "Adjust distance from the starting position of the combo point frame vertically to be higher or lower.",
					min = -150,
					max = 250,
					step = 5,
					order = 6,
					width = "full",
					get = function(info)
						return DeckSuite.db.profile.unitFrames.comboPointVerticalOffset
					end,
					set = function(info, value)
						DeckSuite.db.profile.unitFrames.comboPointVerticalOffset = value
						DeckSuite_UpdateComboFramePosition()
					end,
				},
				comboPointFrameScale = {
					type = "range",
					name = "Combo Point Frame Scale",
					desc = "Adjust distance from the starting position of the combo point frame vertically to be higher or lower.",
					min = 0.5,
					max = 1.5,
					step = 0.1,
					order = 7,
					width = "full",
					get = function(info)
						return DeckSuite.db.profile.unitFrames.comboPointFrameScale
					end,
					set = function(info, value)
						DeckSuite.db.profile.unitFrames.comboPointFrameScale = value
						DeckSuite_UpdateComboFramePosition()
					end,
				},
			},
		},
	},
}

function DeckSuite_InitializeSettings()
	DeckSuite.db = LibStub("AceDB-3.0"):New("DeckSuite", defaults, true)

	local AceConfig = LibStub("AceConfig-3.0")
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")

	AceConfig:RegisterOptionsTable("DeckSuite", options)
	AceConfigDialog:AddToBlizOptions("DeckSuite", "DeckSuite")

	SLASH_DECKSUITE1 = "/ds"
	SLASH_DECKSUITE2 = "/decksuite"
	SLASH_DECKSUITE3 = "/dsuite"

	SlashCmdList["DECKSUITE"] = function(msg)
		AceConfigDialog:Open("DeckSuite")
	end
end
