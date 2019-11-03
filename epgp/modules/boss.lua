local mod = EPGP:NewModule("boss", "AceEvent-3.0")
local Debug = LibStub("LibDebug-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("EPGP")
local Coroutine = LibStub("LibCoroutine-1.0")
local DLG = LibStub("LibDialog-1.0")

local in_combat = false

local function AwardBossEP(event_name, boss_name)
  while (in_combat or DLG:ActiveDialog("EPGP_BOSS_DEAD") or
         DLG:ActiveDialog("EPGP_BOSS_ATTEMPT")) do
    Coroutine:Sleep(0.1)
  end

  local dialog
  if event_name == "kill" or event_name == "BossKilled" then
    EPGP:IncMassEPBy(boss_name, mod.db.profile.bossValues[boss_name])
  elseif event_name == "wipe" and mod.db.profile.wipedetection then
    EPGP:IncMassEPBy(boss_name, mod.db.profile.bossValues[boss_name])
  end
end

local function BossAttempt(event_name, boss_name)
  Debug("Boss attempt: %s %s", event_name, boss_name)
  -- Temporary fix since we cannot unregister DBM callbacks
  if not mod:IsEnabled() then return end

  if CanEditOfficerNote() and EPGP:IsRLorML() then
    Coroutine:RunAsync(AwardBossEP, event_name, boss_name)
  end
end

function mod:PLAYER_REGEN_DISABLED()
  in_combat = true
end

function mod:PLAYER_REGEN_ENABLED()
  in_combat = false
end

function mod:DebugTest()
  BossAttempt("kill", "Ragnaros")
end

mod.dbDefaults = {
  profile = {
    enabled = false,
    wipedetection = false,
	bossValues = {
		["Lucifron"] = "5",
		["Magmadar"] = "5",
		["Gehennas"] = "5",
		["Garr"] = "5",
		["Shazzrah"] = "5",
		["Baron Geddon"] = "5",
		["Golemagg the Incinerator"] = "5",
		["Sulfuron Harbinger"] = "5",
		["Majordomo Executus"] = "5",
		["Ragnaros"] = "7",
		["Onyxia"] = "5",
	},
  },
}

function mod:OnInitialize()
  self.db = EPGP.db:RegisterNamespace("boss", mod.dbDefaults)
end

mod.optionsName = L["Boss"]
mod.optionsDesc = L["Automatic boss tracking"]
mod.optionsArgs = {
  help = {
    order = 1,
    type = "description",
    name = "Automatic boss kill detection to mass award EP to the raid and standby."
  },
  wipedetection = {
    type = "toggle",
    name = L["Wipe awards"],
    desc = L["Awards for wipes on bosses. Requires DBM, DXE, or BigWigs"],
    order = 2,
    disabled = function(v) return not DBM end,
  },
  description1 = {
	type = "description",
	order = 2.1,
	name = "",
  },
  epLucifron = {
	type = "select",
	order = 3,
	name = "Lucifron EP",
	desc = "The amount of EP to award to the raid.",
	style = "dropdown",
	values = {
		[5] = "5",
		[7] = "7",
	},
	get = function(info) return mod.db.profile.bossValues["Lucifron"] end, 
	set = function(info, input) mod.db.profile.bossValues["Lucifron"] = input end
  },
  description2 = {
	type = "description",
	order = 3.1,
	name = "",
  },
  epMagmadar = {
	type = "select",
	order = 4,
	name = "Magmadar EP",
	desc = "The amount of EP to award to the raid.",
	style = "dropdown",
	values = {
		[5] = "5",
		[7] = "7",
	},
	get = function(info) return mod.db.profile.bossValues["Magmadar"] end, 
	set = function(info, input) mod.db.profile.bossValues["Magmadar"] = input end
  },
  description3 = {
	type = "description",
	order = 4.1,
	name = "",
  },
  epGehennas = {
	type = "select",
	order = 5,
	name = "Gehennas EP",
	desc = "The amount of EP to award to the raid.",
	style = "dropdown",
	values = {
		[5] = "5",
		[7] = "7",
	},
	get = function(info) return mod.db.profile.bossValues["Gehennas"] end, 
	set = function(info, input) mod.db.profile.bossValues["Gehennas"] = input end
  },
  description4 = {
	type = "description",
	order = 5.1,
	name = "",
  },
  epGarr = {
	type = "select",
	order = 6,
	name = "Garr EP",
	desc = "The amount of EP to award to the raid.",
	style = "dropdown",
	values = {
		[5] = "5",
		[7] = "7",
	},
	get = function(info) return mod.db.profile.bossValues["Garr"] end, 
	set = function(info, input) mod.db.profile.bossValues["Garr"] = input end
  },
  description5 = {
	type = "description",
	order = 6.1,
	name = "",
  },
  epShazzrah = {
	type = "select",
	order = 7,
	name = "Shazzrah EP",
	desc = "The amount of EP to award to the raid.",
	style = "dropdown",
	values = {
		[5] = "5",
		[7] = "7",
	},
	get = function(info) return mod.db.profile.bossValues["Shazzrah"] end, 
	set = function(info, input) mod.db.profile.bossValues["Shazzrah"] = input end
  },
  description6 = {
	type = "description",
	order = 7.1,
	name = "",
  },
  epBaronGeddon = {
	type = "select",
	order = 8,
	name = "Baron Geddon EP",
	desc = "The amount of EP to award to the raid.",
	style = "dropdown",
	values = {
		[5] = "5",
		[7] = "7",
	},
	get = function(info) return mod.db.profile.bossValues["Baron Geddon"] end, 
	set = function(info, input) mod.db.profile.bossValues["Baron Geddon"] = input end
  },
  description7 = {
	type = "description",
	order = 8.1,
	name = "",
  },
  epGolemag = {
	type = "select",
	order = 9,
	name = "Golemagg the Incinerator EP",
	desc = "The amount of EP to award to the raid.",
	style = "dropdown",
	values = {
		[5] = "5",
		[7] = "7",
	},
	get = function(info) return mod.db.profile.bossValues["Golemag the Incinerator"] end, 
	set = function(info, input) mod.db.profile.bossValues["Golemag the Incinerator"] = input end
  },
  description8 = {
	type = "description",
	order = 9.1,
	name = "",
  },
  epSulfuron = {
	type = "select",
	order = 10,
	name = "Sulfuron Harbinger EP",
	desc = "The amount of EP to award to the raid.",
	style = "dropdown",
	values = {
		[5] = "5",
		[7] = "7",
	},
	get = function(info) return mod.db.profile.bossValues["Sulfuron Harbinger"] end, 
	set = function(info, input) mod.db.profile.bossValues["Sulfuron Harbinger"] = input end
  },
  description9 = {
	type = "description",
	order = 10.1,
	name = "",
  },
  epMajordomo = {
	type = "select",
	order = 11,
	name = "Majordomo Executus EP",
	desc = "The amount of EP to award to the raid.",
	style = "dropdown",
	values = {
		[5] = "5",
		[7] = "7",
	},
	get = function(info) return mod.db.profile.bossValues["Majordomo Executus"] end, 
	set = function(info, input) mod.db.profile.bossValues["Majordomo Executus"] = input end
  },
  description10 = {
	type = "description",
	order = 11.1,
	name = "",
  },
  epRagnaros = {
	type = "select",
	order = 12,
	name = "Ragnaros EP",
	desc = "The amount of EP to award to the raid.",
	style = "dropdown",
	values = {
		[5] = "5",
		[7] = "7",
	},
	get = function(info) return mod.db.profile.bossValues["Ragnaros"] end, 
	set = function(info, input) mod.db.profile.bossValues["Ragnaros"] = input end
  },
  description11 = {
	type = "description",
	order = 12.1,
	name = "",
  },
  epOnyxia = {
	type = "select",
	order = 13,
	name = "Onyxia EP",
	desc = "The amount of EP to award to the raid.",
	style = "dropdown",
	values = {
		[5] = "5",
		[7] = "7",
	},
	get = function(info) return mod.db.profile.bossValues["Onyxia"] end, 
	set = function(info, input) mod.db.profile.bossValues["Onyxia"] = input end
  },
}

local function dbmCallback(event, mod)
  Debug("dbmCallback: %s %s", event, mod.combatInfo.name)
  BossAttempt(event, mod.combatInfo.name)
end

local function bwCallback(event, module)
  Debug("bwCallback: %s %s", event, module.displayName)
  BossAttempt(event == "BigWigs_OnBossWin" and "kill" or "wipe", module.displayName)
end

local function dxeCallback(event, encounter)
  Debug("dxeCallback: %s %s", event, encounter.name)
  BossAttempt("kill", encounter.name)
end

function mod:OnEnable()
  self:RegisterEvent("PLAYER_REGEN_DISABLED")
  self:RegisterEvent("PLAYER_REGEN_ENABLED")
  if DBM then
    EPGP:Print(L["Using %s for boss kill tracking"]:format("DBM"))
    DBM:RegisterCallback("kill", dbmCallback)
    DBM:RegisterCallback("wipe", dbmCallback)
  elseif BigWigsLoader then
    EPGP:Print(L["Using %s for boss kill tracking"]:format("BigWigs"))
    BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossWin", bwCallback)
    BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossWipe", bwCallback)
  elseif DXE then
    EPGP:Print(L["Using %s for boss kill tracking"]:format("DXE"))
    DXE.RegisterCallback(mod, "TriggerDefeat", dxeCallback)
  end
end

function mod:OnDisable()
  if BigWigsLoader then
    BigWigsLoader.UnregisterMessage(self, "BigWigs_OnBossWin")
    BigWigsLoader.UnregisterMessage(self, "BigWigs_OnBossWipe")
  elseif DXE then
    DXE.UnregisterCallback(mod, "TriggerDefeat")
  end
end
