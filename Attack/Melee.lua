--Services
local SPlayer = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local SRun = game:GetService("RunService")

--Modules
local M1 = require(script.Parent.M1Module)
local ProjectileModule = require(script.Parent.ProjectileModule)
--Vars
local LPlayer = SPlayer.LocalPlayer
local Character = LPlayer.Character
local PlayerGui = LPlayer.PlayerGui
local Mouse = LPlayer:GetMouse()

--GuiVars
local Main = PlayerGui.MobileGui.Maximum_Radius.MainButton
local Secondary = PlayerGui.MobileGui.SecondaryButton
local Radius = PlayerGui.MobileGui.Maximum_Radius


local Mobile = {}
Mobile.ProjectilePosition = Main.Position
Mobile.OldPosition = nil
Mobile.CurrentInput = nil
Mobile.ProjectileConnection = nil
Mobile.Sensitivity = 0.1
Mobile.Melee = true

Mobile.Images = {
	["Melee"] = "rbxassetid://87288186265064";
	["Projectile"] = "rbxassetid://135491783080662";
}

function Mobile.getJoystickPosition(Input):Vector2
	-- Calculate position in screen space
	
	local mousePos = UIS:GetMouseLocation()
	if Input then mousePos = Vector2.new(Input.Position.X, Input.Position.Y) end

	-- Getting the base's screen space
	local basePos = Radius.AbsolutePosition
	local baseSize = Radius.AbsoluteSize
	local baseCenter = basePos + baseSize / 2  -- The center of the base

	local offset = mousePos - baseCenter

	local r = baseSize.X / 2
	if offset.Magnitude > r then
		offset = offset.Unit * r  -- Keep it inside the radius
	end

	-- Return the normalized direction (Unit vector)
	return offset
end
function Mobile.UpdateProjectileTrajectory()
	local Direction = (UIS:GetMouseLocation() - (Radius.AbsolutePosition + Radius.AbsoluteSize/2)).Unit
	
	local TargetPosition : Vector3
	if not Mobile.OldPosition then
		print("No mobile old position")
		TargetPosition = Character.HumanoidRootPart.Position + Vector3.new(Direction.X * Mobile.Sensitivity, -Direction.Y * Mobile.Sensitivity, -10)
	else
		TargetPosition = Mobile.OldPosition + Vector3.new(Direction.X * Mobile.Sensitivity, -Direction.Y * Mobile.Sensitivity, 0)
		TargetPosition = Vector3.new(TargetPosition.X, math.clamp(TargetPosition.Y, Character.HumanoidRootPart.Position.Y - 3, 30), TargetPosition.Z)
	end
	
	Mobile.OldPosition = TargetPosition
	
	print(TargetPosition - Character.HumanoidRootPart.Position.Unit)
	return (TargetPosition - Character.HumanoidRootPart.Position).Unit
end

function Mobile.SwitchState()
	if Mobile.Melee then
		Main.Image = Mobile.Images["Projectile"]
		Secondary.Image = Mobile.Images["Melee"]
	else
		Main.Image = Mobile.Images["Melee"]
		Secondary.Image = Mobile.Images["Projectile"]
	end
	
	Mobile.Melee = not Mobile.Melee
end

function Mobile.JoystickEnable(Input:InputObject)
	if Mobile.CurrentInput == Input then return end
	if Input.UserInputType ~= Enum.UserInputType.Touch or Mobile.Melee then
		M1.Attack()
		 return
	end
	
	ProjectileModule.Projectile(true, Mobile.UpdateProjectileTrajectory)
		
	Mobile.CurrentInput = Input
end

function Mobile.Move(Input:InputObject)
	if Input ~= Mobile.CurrentInput then return end
	
	local offset = Mobile.getJoystickPosition(Input)
	Main.Position = UDim2.new(0.5, offset.X, 0.5, offset.Y)
	
end

function Mobile.ProjectileJoystickDisable(Inputobj)
	if Mobile.CurrentInput ~= Inputobj then return end
	
	
	ProjectileModule.FireProjectile()
	
	Mobile.CurrentInput = nil	
	Mobile.OldPosition = nil
	
	Main.Position = Mobile.ProjectilePosition
end

return Mobile
