--Services
local RStorage = game:GetService("ReplicatedStorage")
local SPlayer = game:GetService("Players")
local SRun = game:GetService("RunService")

--Modules
local Packet = require(RStorage.Utilities.Packet)
local StateHandler = require(RStorage.Utilities.StateHandler)
local HitDetector = require(RStorage.QOL.HitDetector)
local AnimationLoader = require(RStorage.QOL.AnimationLoader)
local CharacterEditor = require(script.Parent.CharacterEditor)
local Types = require(script.Types)

--Events
local Input = Packet("Input", Packet.Any)

--Variables
local Melee = {}
Melee.ButtonsHeld = {}
Melee.ComboCount = {}
Melee.LastAttack = {}
Melee.BlockTime = {}
Melee.BlockedHits = {}
Melee.CurrentBlockAnimation = {}

--Settings
Melee.ResetCombo = 1.5
Melee.PerfectBlockWindow = 0.35
Melee.Knockback = 50
Melee.FinalHitKnockbackMultiplier = 2
Melee.MaximumBlockedHits = 4

--Types
type InputState = Types.InputState

function Melee.InitiateCombo(Player:Player)
	--State handler stores states of the player if not able to change
	-- to combo state then return
	if not StateHandler.ChangeState(Player, "Combo") then return end
	
	--//This allows you to hold m1, and continue attacking while m1 is held
	while StateHandler.GetState(Player) == "Combo" do
		--//Retrieve combo count
		local ComboCount = Melee.SetComboCount(Player)
		
		local Character = Player.Character
		local Humanoid = Character.Humanoid
		local Animator = Humanoid.Animator
		
		--//Animations are preloaded uses ContentProvider
		AnimationLoader.Preload(Animator)
		
		local Type = "Melee"
		if Character:GetAttribute("SwordState") == "Sword" then Type = Character:GetAttribute("Type") end
		
		--//PlayAnimation
		local Animation = AnimationLoader.Get(Animator, Type, ComboCount)
		Animation:Play()
		--//Update the player's speed
		Melee.UpdateHumanoid(Humanoid, 4, 2)
		
		task.wait(Animation.Length/6)
		
		--//Maybe after the wait the player was attacked so cancel m1
		if StateHandler.GetState(Player) ~= "Combo" then break end
		
		--//Create hitboxes
		local Hit = Melee.CreateHitbox(Player, Animation.Length/3)
		--//Maybe attacked while trying to hit, give advantage to player
		--who attacked first
		if StateHandler.GetState(Player) ~= "Combo" then break end
				
			
		for Index, HitCharacter in Hit do
			local HitPlayer = SPlayer:GetPlayerFromCharacter(HitCharacter)
			local HitHumanoid = HitCharacter.Humanoid
			 
			if (Melee.IsAttackerInFront(HitCharacter.PrimaryPart, Character.PrimaryPart)  
				and HitPlayer
				and StateHandler.GetState(HitPlayer) == "Blocking")  then 
				
				if Melee.BlockBreak(HitPlayer) then continue end
				
				Melee.OnBlocked(Player, HitPlayer); 
				break 
			end
			
			HitHumanoid.Health -= 2
			
			--//Stun the player using the state handler
			if HitPlayer then
				StateHandler.ChangeState(HitPlayer, "Stunned", 1.5)
			end
		end
		
		if StateHandler.GetState(Player) == "Stunned" then return end
		
		Animation.Ended:Wait()
		
		
		--task.wait(Animation.Length / 2)
		--//check if player is holding m1 or not
		if not table.find(Melee.ButtonsHeld[Player], "MouseButton1") then 
			StateHandler.UnlockState(Player)
			StateHandler.ChangeState(Player, "Idle")
			StateHandler.UnlockState(Player)
			
			Melee.UpdateHumanoid(Humanoid, 12, 7.2)
			break
		end
	end
	
end

function Melee.CreateHitbox(Player:Player, Length:number)
	local StartTime = os.clock()
	
	--Hit is found by using GetPartsBoundsInBox and then the returned table is filtered
	--to only find objects with a humanoid in them
	local Hit = HitDetector.DetectPlayer(nil, Player.Character, Vector3.new(6,6,6),true, true)
	
	--//Continously do this while the window of attack is active
	repeat 
		Hit = HitDetector.DetectPlayer(nil, Player.Character, Vector3.new(6,6,6),true, true)
		
		task.wait()
	until os.clock() - StartTime > Length or (Hit and #Hit > 0)
	
	if not Hit then Hit = {} end
	return Hit
end

function Melee.BlockBreak(HitPlayer:Player)
	local Character = HitPlayer.Character
	local Animator = Character.Humanoid.Animator
	
	--//Check if maximum number of blocks reached or not
	if Melee.BlockedHits[HitPlayer] < Melee.MaximumBlockedHits then
		return false
	end
	
	Melee.CurrentBlockAnimation[HitPlayer]:Stop()
	
	--//Unlocks the state, whenever there is a change in state the statehander locks that state
	--//until length is reached or, the state is unlocked manually
	StateHandler.UnlockState(HitPlayer)

	--//Retrieve current state, wether the player is holding their sword or not
	local Type = "Melee"
	if Character:GetAttribute("SwordState") == "Sword" then Type = Character:GetAttribute("Type") end

	--//Retrive animation and play it
	local BlockBreakAnim = AnimationLoader.Get(Animator, Type, "Break")
	BlockBreakAnim:Play()
	
	--change the state
	StateHandler.ChangeState(HitPlayer, "Stunned", 2)
	return true
end

--//Inside of statehandler there are functions for when the player is stunned to slow him down


--//Find out if the attacker is infront of the blocker or not
--//if behind then the block should not be recorded
function Melee.IsAttackerInFront(blockerRoot: BasePart, attackerRoot: BasePart)
	local blockerForward = blockerRoot.CFrame.LookVector
	local directionToAttacker = (attackerRoot.Position - blockerRoot.Position).Unit

	local dot = blockerForward:Dot(directionToAttacker)
	return dot > 0 -- true = front, false = back
end

--//QOL function just to update the humanoid
function Melee.UpdateHumanoid(Humanoid, RunSpeed, JumpHeight)
	Humanoid.WalkSpeed = RunSpeed
	Humanoid.JumpHeight = JumpHeight
end

function Melee.Block(Player:Player)
	--//This statement is only true if the player held the F button before	
	local Character = Player.Character
	local Humanoid = Character.Humanoid
	local Animator = Humanoid.Animator
	
	--//If player is not holding F cancel the block
	if not table.find(Melee.ButtonsHeld[Player], "F") and StateHandler.GetState(Player) then
		StateHandler.UnlockState(Player)
		StateHandler.ChangeState(Player, "Idle")
		--//store the animation inside of a table, instead of looping inside of the players animations
		--//Then afterwards stop the animation if its found
		if Melee.CurrentBlockAnimation[Player] then Melee.CurrentBlockAnimation[Player]:Stop() end
		print("Speed returned to normal")
		
		Melee.UpdateHumanoid(Humanoid, 12, 7.2)
		return
	end
	
	--//Attempts to change the current state to blocking
	if not StateHandler.ChangeState(Player, "Blocking") then return end	
	
	--//Preload the animation, this will just return 
	--if the animations are already preloaded
	AnimationLoader.Preload(Animator)

	local Type = "Melee"
	if Character:GetAttribute("SwordState") == "Sword" then Type = Character:GetAttribute("Type") end
	--//Plays the animations and stuff
	Melee.CurrentBlockAnimation[Player] = AnimationLoader.Get(Animator, Type, "Block")
	Melee.CurrentBlockAnimation[Player]:Play()
	--//Store time when the block happens to check for perfect blocks/Parries
	Melee.BlockTime[Player] = os.clock()
	Melee.BlockedHits[Player] = 0
	
	Melee.UpdateHumanoid(Humanoid, 2, 0)
end



function Melee.OnBlocked(Attacker, Blocker)
	local Perfect = os.clock() - Melee.BlockTime[Blocker] <= Melee.PerfectBlockWindow
	
	--//Checks if perfect block
	if Perfect then 
		StateHandler.UnlockState(Attacker)
		StateHandler.ChangeState(Attacker, "Stunned", 2)  
		Melee.BlockedHits[Blocker] = 0
	end
	
 	--// if not perfect then increase block count
	Melee.BlockedHits[Blocker] += 1
end


function Melee.SetComboCount(Player:Player)
	--//If there is no lastAttack for the player create one
	if not Melee.LastAttack[Player] then 
		Melee.LastAttack[Player] = os.clock()
		Melee.ComboCount[Player] = 1
		return 1
	end
	
	--//If comboreset time was reached then return 1
	if os.clock() - Melee.LastAttack[Player] > Melee.ResetCombo then
		Melee.LastAttack[Player] = os.clock()
		Melee.ComboCount[Player] = 1
		return 1
	end
	
	--IF combo count == 5 then reset the combo
	if Melee.ComboCount[Player] == 5 then
		task.wait(1)
		Melee.ComboCount[Player] = 1 
		Melee.LastAttack[Player] = os.clock()
		return Melee.ComboCount[Player]
	end
	
	
	Melee.LastAttack[Player] = os.clock()
	Melee.ComboCount[Player] += 1
	
	return Melee.ComboCount[Player]
end

function Melee.RegisterInputs(Player:Player, Info:InputState)
	--//The info state is sent across the client in a table in this format
	
	--{
	--	M1:boolean
	--	Block:boolean,
	--}
	
	--//Create player table
	if not Melee.ButtonsHeld[Player] then Melee.ButtonsHeld[Player] = {} end
		
	--//initiate combo if player is holding m1
	if Info.M1 and not table.find(Melee.ButtonsHeld[Player], "MouseButton1") then
		table.insert(Melee.ButtonsHeld[Player], "MouseButton1")
		Melee.InitiateCombo(Player)
		return
	else
		--//if not holding m1 in the client and buttonsheld has M1 then remove it
		if table.find(Melee.ButtonsHeld[Player], "MouseButton1") then
			table.remove(Melee.ButtonsHeld[Player], table.find(Melee.ButtonsHeld[Player], "MouseButton1"))
		end
	end
	
	--//check if player is blocking
	if Info.Block and not table.find(Melee.ButtonsHeld[Player], "F") then
		table.insert(Melee.ButtonsHeld[Player], "F")
		Melee.Block(Player)
		return
		--remove f from buttons held
	elseif table.find(Melee.ButtonsHeld[Player], "F") and not Info.Block then
		table.remove(Melee.ButtonsHeld[Player], table.find(Melee.ButtonsHeld[Player], "F"))
		Melee.Block(Player)
	end
	
end

--//Reset the player data this could happen if the player died or he is leaving the game
function Melee.RemovePlayerData(Player:Player)
	Melee.ButtonsHeld[Player] = nil
	Melee.ComboCount[Player] = nil
	Melee.LastAttack[Player] = nil
	Melee.BlockTime[Player] = nil
	Melee.BlockedHits[Player] = nil
	Melee.CurrentBlockAnimation[Player] = nil
end

--//Create connections
function Melee.Start()
	Input.OnServerEvent:Connect(Melee.RegisterInputs)
end

return Melee
