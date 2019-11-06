function uEPGP:SetupOptions()
local options = {
	type = "group",
	name = "uEPGP",
	handler = uEPGP,
	args = {
		generalGroup = {
			type = "group",
			guiInline = true,
			name = "Master Looter Options",
			order = 2,
			args = {		
				windowType = {
					type = "select",
					order = 1,
					name = "Loot Selection Timeout:",
					desc = "This option sets the amount of time a candidate has to make a section on loot.",
					style = "dropdown",
					values = {
						[10] = "10 Seconds",
						[15] = "15 Seconds",
						[20] = "20 Seconds",
						[30] = "30 Seconds",
						[40] = "40 Seconds",
						[50] = "50 Seconds",
						[60] = "1 Minute",
						[90] = "1.5 Minutes",
						[120] = "2 Minutes",
						[180] = "3 Minutes",
						[300] = "5 Minutes",
					},
					get = function(info) return uEPGP.db.profile.lootTimeout end, 
					set = function(info, input) uEPGP.db.profile.lootTimeout = input end
				},
				description1 = {
					type = "description",
					order = 1.1,
					name = "",
				},
				announceButton = {
					type = "select",
					order = 2,
					name = "Announce Button:",
					desc = "This option sets button or button combination to announce loot. Please take note that on the first click of each new loot window, uEPGP will automatically announce ALL items.",
					style = "dropdown",
					values = {
						[1] = "Left ALT + Click",
						[2] = "Left Click",
					},
					get = function(info) return uEPGP.db.profile.announceButton end, 
					set = function(info, input) uEPGP.db.profile.announceButton = input end
				},	
				description2 = {
					type = "description",
					order = 2.1,
					name = "",
				},
				lootThreshold = {
					type = "select",
					order = 2.2,
					name = "Loot Threshold:",
					desc = "This option sets the loot rarity threshold for auto announce.",
					style = "dropdown",
					values = {
						[2] = "Uncommon",
						[3] = "Common",
						[4] = "Rare",
						[5] = "Epic",
						[6] = "Legendary",
					},
					get = function(info) return uEPGP.db.profile.lootThreshold end, 
					set = function(info, input) uEPGP.db.profile.lootThreshold = input end
				},				
				description3 = {
					type = "description",
					order = 2.3,
					name = "",
				},
				autoAnnounceConfirm = {
					type = "toggle",
					order = 3,
					width = "full",
					name = "Show \"Announce ALL\" Popup",
					desc = "By default, uEPGP automatically announces ALL items on the first click of each new loot window. Enabling this option will override this behavior by providing a Yes/No Popup.",
					get = function(info) return uEPGP.db.profile.announceConfirm end, 
					set = function(info, input) uEPGP.db.profile.announceConfirm = input end
				},
				description3 = {
					type = "description",
					order = 3.1,
					name = "",
				},
				autoCancel = {
					type = "toggle",
					order = 4,
					width = "full",
					name = "Auto-Cancel on Loot Window Closure",
					desc = "When enabled, this option will automatically cancel/close ALL existing loot announcements after closing the Blizzard loot window.",
					get = function(info) return uEPGP.db.profile.autoCancel end, 
					set = function(info, input) uEPGP.db.profile.autoCancel = input end
				},
				description4 = {
					type = "description",
					order = 4.1,
					name = "",
				},
				lootAutoAdvance = {
					type = "toggle",
					order = 5,
					width = "full",
					name = "Hide Candidate Responses While Selecting",
					desc = "When enabled, this option will hide all resonses until after a selection has been made.",
					get = function(info) return uEPGP.db.profile.hideResponses end, 
					set = function(info, input) uEPGP.db.profile.hideResponses = input end
				},
				description5 = {
					type = "description",
					order = 5.1,
					name = "",
				},
				lootReselection = {
					type = "toggle",
					order = 6,
					width = "full",
					name = "Allow Re-Selection of Loot",
					desc = "When enabled, this option will allow candidates to change their responses on eligible loot until the timer expires.",
					get = function(info) return uEPGP.db.profile.allowReselect end, 
					set = function(info, input) uEPGP.db.profile.allowReselect = input end
				}
			}
		},
		displayGroup = {
			type = "group",
			guiInline = true,
			name = "Personal Options",
			order = 1,
			args = {
				lootAutoAdvance = {
					type = "toggle",
					order = 1,
					width = "full",
					name = "Loot Auto-Advance",
					desc = "When enabled, this option will allow automatic advancement to the next piece of eligible loot after a selection has been made.",
					get = function(info) return uEPGP.db.profile.autoAdvance end, 
					set = function(info, input) uEPGP.db.profile.autoAdvance = input end
				},
				description1 = {
					type = "description",
					order = 1.1,
					name = "",
				},
				showVersionReplies = {
					type = "toggle",
					order = 2,
					width = "full",
					name = "Show Version Replies",
					desc = "When enabled, this option will allow show all online members addon version when /un version is issued.",
					get = function(info) return uEPGP.db.profile.showVersionReplies end, 
					set = function(info, input) uEPGP.db.profile.showVersionReplies = input end
				},
				description2 = {
					type = "description",
					order = 2.1,
					name = "",
				},
				windowStyle = {
					type = "select",
					order = 3,
					name = "Window Style:",
					desc = "This option sets the display style for the loot windows; either a single tabbed window or separate windows for each loot item.",
					style = "dropdown",
					values = {
						["yes"] = "Tabbed",
						["no"] = "Separate",
					},
					get = function(info) return uEPGP.db.profile.tabbedFrame end, 
					set = function(info, input) uEPGP.db.profile.tabbedFrame = input uEPGP:ChangeDisplayMode() end
				}
			}
		},		
		buttonsGroup = {
			type = "group",
			guiInline = true,
			name = "Loot Selection Buttons",
			order = 3,
			args = {
				buttonNum = {
					type = "range",
					order = 1,
					name = "Number of buttons to display:",
					desc = "This option sets the number of selection buttons available.",
					width = "double",
					min = 1,
					max = 7,
					step = 1,
					get = function(info) return uEPGP.db.profile.buttonNum	end,
					set = function(info, input)	uEPGP.db.profile.buttonNum = input	end
				},
				buttonNum_description = {
					type = "description",
					order = 1.1,
					name = "",
				},
				button1 = {
					type = "input",
					order = 2,
					name = "Button 1",
					desc = "This field sets the text for button 1.",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 1 end,
					get = function(info) return uEPGP.db.profile.button1 end,
					set = function(info, input) uEPGP.db.profile.button1 = input end
				},
				button1_GP = {
					type = "input",
					order = 2.1,
					name = "Default GP:",
					desc = "This field sets the default GP value for button 1. Enter actual GP value or a percentage (up to 100%). Empty signifies 100% value.",
					width = "half",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 1 end,
					get = function(info) return uEPGP.db.profile.button1_GP end,
					set = function(info, input) uEPGP:ValidateAndSetGP(info, input) end,
				},
				button1_color = {
					type = "color",
					order = 2.2,
					name = "Text Color",
					desc = "",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 1 end,
					hasAlpha = false,
					get = function(info, r, g, b, a) 
						return uEPGP:HexToRGBPerc(uEPGP.db.profile.button1_color)
					end,
					set = function(info, r, g, b, a)
						uEPGP.db.profile.button1_color = uEPGP:RGBPercToHex(r, g, b)
					end
				},
				button1_description = {
					type = "description",
					order = 2.3,
					name = "",
				},
				button2 = {
					type = "input",
					order = 3,
					name = "Button 2",
					desc = "This field sets the text for button 2.",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 2 end,
					get = function(info) return uEPGP.db.profile.button2 end,
					set = function(info, input) uEPGP.db.profile.button2 = input end
				},
				button2_GP = {
					type = "input",
					order = 3.1,
					name = "Default GP:",
					desc = "This field sets the default GP value for button 2. Enter actual GP value or a percentage (up to 100%). Empty signifies 100% value.",
					width = "half",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 2 end,
					get = function(info) return uEPGP.db.profile.button2_GP end,
					set = function(info, input) uEPGP:ValidateAndSetGP(info, input) end,
				},
				button2_color = {
					type = "color",
					order = 3.2,
					name = "Text Color",
					desc = "",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 2 end,
					hasAlpha = false,
					get = function(info, r, g, b, a) 
						return uEPGP:HexToRGBPerc(uEPGP.db.profile.button2_color)
					end,
					set = function(info, r, g, b, a)
						uEPGP.db.profile.button2_color = uEPGP:RGBPercToHex(r, g, b)
					end
				},
				button2_description = {
					type = "description",
					order = 3.3,
					name = "",
				},		
				button3 = {
					type = "input",
					order = 4,
					name = "Button 3",
					desc = "This field sets the text for button 3.",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 3 end,
					get = function(info) return uEPGP.db.profile.button3 end,
					set = function(info, input) uEPGP.db.profile.button3 = input end
				},
				button3_GP = {
					type = "input",
					order = 4.1,
					name = "Default GP:",
					desc = "This field sets the default GP value for button 3. Enter actual GP value or a percentage (up to 100%). Empty signifies 100% value.",
					width = "half",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 3 end,
					get = function(info) return uEPGP.db.profile.button3_GP end,
					set = function(info, input) uEPGP:ValidateAndSetGP(info, input) end,
				},
				button3_color = {
					type = "color",
					order = 4.2,
					name = "Text Color",
					desc = "",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 3 end,
					hasAlpha = false,
					get = function(info, r, g, b, a) 
						return uEPGP:HexToRGBPerc(uEPGP.db.profile.button3_color)
					end,
					set = function(info, r, g, b, a)
						uEPGP.db.profile.button3_color = uEPGP:RGBPercToHex(r, g, b)
					end	
				},
				button3_description = {
					type = "description",
					order = 4.3,
					name = "",
				},
				button4 = {
					type = "input",
					order = 5,
					name = "Button 4",
					desc = "This field sets the text for button 4.",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 4 end,					
					get = function(info) return uEPGP.db.profile.button4 end,
					set = function(info, input) uEPGP.db.profile.button4 = input end
				},
				button4_GP = {
					type = "input",
					order = 5.1,
					name = "Default GP:",
					desc = "This field sets the default GP value for button 4. Enter actual GP value or a percentage (up to 100%). Empty signifies 100% value.",
					width = "half",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 4 end,
					get = function(info) return uEPGP.db.profile.button4_GP end,
					set = function(info, input) uEPGP:ValidateAndSetGP(info, input) end,
				},
				button4_color = {
					type = "color",
					order = 5.2,
					name = "Text Color",
					desc = "",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 4 end,
					hasAlpha = false,
					get = function(info, r, g, b, a) 
						return uEPGP:HexToRGBPerc(uEPGP.db.profile.button4_color)
					end,
					set = function(info, r, g, b, a)
						uEPGP.db.profile.button4_color = uEPGP:RGBPercToHex(r, g, b)
					end	
				},
				button4_description = {
					type = "description",
					order = 5.3,
					name = "",
				},
				button5 = {
					type = "input",
					order = 6,
					name = "Button 5",
					desc = "This field sets the text for button 5.",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 5 end,					
					get = function(info) return uEPGP.db.profile.button5 end,
					set = function(info, input) uEPGP.db.profile.button5 = input end
				},
				button5_GP = {
					type = "input",
					order = 6.1,
					name = "Default GP:",
					desc = "This field sets the default GP value for button 5. Enter actual GP value or a percentage (up to 100%). Empty signifies 100% value.",
					width = "half",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 5 end,
					get = function(info) return uEPGP.db.profile.button5_GP end,
					set = function(info, input) uEPGP:ValidateAndSetGP(info, input) end,
				},
				button5_color = {
				type = "color",
					order = 6.2,
					name = "Text Color",
					desc = "",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 5 end,
					hasAlpha = false,
					get = function(info, r, g, b, a) 
						return uEPGP:HexToRGBPerc(uEPGP.db.profile.button5_color)
					end,
					set = function(info, r, g, b, a)
						uEPGP.db.profile.button5_color = uEPGP:RGBPercToHex(r, g, b)
					end
				},
				button5_description = {
					type = "description",
					order = 6.3,
					name = "",
				},
				button6 = {
					type = "input",
					order = 7,
					name = "Button 6",
					desc = "This field sets the text for button 6.",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 6 end,					
					get = function(info) return uEPGP.db.profile.button6 end,
					set = function(info, input) uEPGP.db.profile.button6 = input end
				},
				button6_GP = {
					type = "input",
					order = 7.1,
					name = "Default GP:",
					desc = "This field sets the default GP value for button 6. Enter actual GP value or a percentage (up to 100%). Empty signifies 100% value.",
					width = "half",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 6 end,
					get = function(info) return uEPGP.db.profile.button6_GP end,
					set = function(info, input) uEPGP:ValidateAndSetGP(info, input) end,
				},		
				button6_color = {
					type = "color",
					order = 7.2,
					name = "Text Color",
					desc = "asdf",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 6 end,
					hasAlpha = false,
					get = function(info, r, g, b, a) 
						return uEPGP:HexToRGBPerc(uEPGP.db.profile.button6_color)
					end,
					set = function(info, r, g, b, a)
						uEPGP.db.profile.button6_color = uEPGP:RGBPercToHex(r, g, b)
					end	
				},
				button6_description = {
					type = "description",
					order = 7.3,
					name = "",
				},
				button7 = {
					type = "input",
					order = 8,
					name = "Button 6",
					desc = "This field sets the text for button 6.",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 7 end,					
					get = function(info) return uEPGP.db.profile.button7 end,
					set = function(info, input) uEPGP.db.profile.button7 = input end
				},
				button7_GP = {
					type = "input",
					order = 8.1,
					name = "Default GP:",
					desc = "This field sets the default GP value for button 6. Enter actual GP value or a percentage (up to 100%). Empty signifies 100% value.",
					width = "half",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 7 end,
					get = function(info) return uEPGP.db.profile.button7_GP end,
					set = function(info, input) uEPGP:ValidateAndSetGP(info, input) end,
				},		
				button7_color = {
					type = "color",
					order = 8.2,
					name = "Text Color",
					desc = "asdf",
					hidden = function(info) return uEPGP.db.profile.buttonNum < 7 end,
					hasAlpha = false,
					get = function(info, r, g, b, a) 
						return uEPGP:HexToRGBPerc(uEPGP.db.profile.button7_color)
					end,
					set = function(info, r, g, b, a)
						uEPGP.db.profile.button7_color = uEPGP:RGBPercToHex(r, g, b)
					end	
				},
				button7_description = {
					type = "description",
					order = 8.3,
					name = "",
				}
			}
		}
	}
}

local registry = LibStub("AceConfigRegistry-3.0")
  registry:RegisterOptionsTable("uEPGP Options", options)

  local dialog = LibStub("AceConfigDialog-3.0")
  dialog:AddToBlizOptions("uEPGP Options", "uEPGP")

  -- Setup options for each module that defines them.
  for name, m in self:IterateModules() do
    if m.optionsArgs then
      -- Set all options under this module as disabled when the module
      -- is disabled.
      for n, o in pairs(m.optionsArgs) do
        if o.disabled then
          local old_disabled = o.disabled
          o.disabled = function(i)
                         return old_disabled(i) or m:IsDisabled()
                       end
        else
          o.disabled = "IsDisabled"
        end
      end
      -- Add the enable/disable option.
      m.optionsArgs.enabled = {
        order = 0,
        type = "toggle",
        width = "full",
        name = ENABLE,
        get = "IsEnabled",
        set = "SetEnabled",
      }
    end
    if m.optionsName then
      registry:RegisterOptionsTable("uEPGP " .. name, {
                                      handler = m,
                                      order = 100,
                                      type = "group",
                                      name = m.optionsName,
                                      desc = m.optionsDesc,
                                      args = m.optionsArgs,
                                      get = "GetDBVar",
                                      set = "SetDBVar",
                                    })
      dialog:AddToBlizOptions("uEPGP " .. name, m.optionsName, "uEPGP")
    end
  end
end

function uEPGP:ResetToDefaults()
	self.db:ResetProfile()
	LibStub("AceConfigRegistry-3.0"):NotifyChange("uEPGP")
end

function uEPGP:RGBPercToHex(r, g, b)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

function uEPGP:HexToRGBPerc(hex)
	local rhex, ghex, bhex = string.sub(hex, 1, 2), string.sub(hex, 3, 4), string.sub(hex, 5, 6)
	return tonumber(rhex, 16)/255, tonumber(ghex, 16)/255, tonumber(bhex, 16)/255
end

function uEPGP:ValidateAndSetGP(info, input)
	local number, percent = strmatch(input, '^(%d+)(%%?)$')

	if number and percent ~= "" and tonumber(number) <= 100 then
		self.db.profile[info[2]] = number..percent
	elseif number and percent == "" then
		self.db.profile[info[2]] = number..percent
	else
		self.db.profile[info[2]] = ""
	end
end