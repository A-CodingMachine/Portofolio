--Services
local RStorage = game:GetService("ReplicatedStorage")
local SPlayers = game:GetService("Players")

--Modules
local ProfileStore = require(script.Parent.ProfileStore)

--Remotes
local DataManager = {}

DataManager.Template = {
	Weapon = "Pin";
	WeaponsOwned = {};
	
	Balloon = "Default";
	BalloonsOwned = {};
	
	Coins = 0;
}

DataManager.Profiles = {}
DataManager.PlayerStore = nil

function DataManager.OnStart()
	DataManager.PlayerStore = ProfileStore.New("PopDataStore", DataManager.Template)
	
	SPlayers.PlayerRemoving:Connect(function(player)
		local profile = DataManager.Profiles[player]
		if profile ~= nil then
			profile:EndSession()
		end
	end)
end

function DataManager.PlayerValuesUpdate(Plr)
	for i,v in DataManager.Profiles[Plr].Data do
		print(i, DataManager.Profiles[Plr].Data[i])
		if Plr:FindFirstChild(i) then print(Plr[i]) Plr[i].Value = DataManager.Profiles[Plr].Data[i] end
	end	
	
	Plr:LoadCharacter() --Reload character after data has been set
end


function DataManager.OnPlayerAdded(Plr)
	local profile = DataManager.PlayerStore:StartSessionAsync(`{Plr.UserId}_Data`, {
		Cancel = function()
			return Plr.Parent ~= SPlayers
		end,
	})
	print(profile)

	if profile ~= nil then

		profile:AddUserId(Plr.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from PROFILE_TEMPLATE (optional)

		profile.OnSessionEnd:Connect(function()
			DataManager.Profiles[Plr] = nil
			Plr:Kick(`Profile session end - Please rejoin`)
		end)

		if Plr.Parent == SPlayers then
			DataManager.Profiles[Plr] = profile
			print(`Profile loaded for {Plr.DisplayName}!`)
		else
			profile:EndSession()
		end

	else
		Plr:Kick(`Profile load fail - Please rejoin`)
	end
	
	print("Profile loaded")
	
	if not RStorage.KITS.Balloons:FindFirstChild(profile.Data.Balloon) then profile.Data.Balloon = "Default" end
	if not RStorage.KITS.Weapons:FindFirstChild(profile.Data.Weapon) then profile.Data.Weapon = "Pin" end
	
	DataManager.PlayerValuesUpdate(Plr)
		
end

return DataManager


