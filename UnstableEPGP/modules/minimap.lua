local mod = uEPGP:NewModule("minimap", "AceEvent-3.0")
local Debug = LibStub("LibDebug-1.0")
local Coroutine = LibStub("LibCoroutine-1.0")
local DLG = LibStub("LibDialog-1.0")
local icon = LibStub("LibDBIcon-1.0")

local function isEmpty(s)
  return s == nil or s == ''
end

mod.dbDefaults = {
  profile = {
    enabled = true,
    minimap	= { hide = false},
  },
}

mod.optionsName = "Minimap Button"
mod.optionsDesc = "uEPGP Minimap Options"
mod.optionsArgs = {
	help = {
      order = 1,
      type = "description",
      name = "Show minimap button."
    },
}

-- Create minimap button using LibDBIcon
local TT_H_1, TT_H_2 = "|cff00FF00".."Unstable EPGP".."|r", string.format("|cffFFFFFF%s|r", GetAddOnMetadata('uEPGP', 'Version'))
local TT_ENTRY = "|cFFCFCFCF%s:|r %s" --|cffFFFFFF%s|r"
local minimapLDB = LibStub("LibDataBroker-1.1"):NewDataObject("uEPGP", {
	type = "launcher",
	text = "uEPGP",
	icon = "Interface\\AddOns\\uEPGP\\textures\\u",
	OnClick = function(self, button)
		if button == "RightButton" then
			DEFAULT_CHAT_FRAME.editBox:SetText("/un test") ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
		else
			DEFAULT_CHAT_FRAME.editBox:SetText("/epgp") ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
		end
	end,
	OnTooltipShow = function(tooltip)
		tooltip:AddDoubleLine(TT_H_1, TT_H_2);
		tooltip:AddLine(format(TT_ENTRY, "Left Click", "Open Standings"))
		tooltip:AddLine(format(TT_ENTRY, "Right Click", "Test Loot Window"))
	end,
})

function mod:OnInitialize()
  self.db = uEPGP.db:RegisterNamespace("minimap", mod.dbDefaults)
end

function mod:OnEnable()
  if icon:IsRegistered("uEPGPMinimap") then
    icon:Show("uEPGPMinimap")
  else
    icon:Register("uEPGPMinimap", minimapLDB, self.db.profile.minimap)
  end
end

function mod:OnDisable()
  icon:Hide("uEPGPMinimap")
end
