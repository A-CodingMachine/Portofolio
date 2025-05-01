--Services
local UIS = game:GetService("UserInputService")
local RStorage = game:GetService("ReplicatedStorage")
local SPLayer = game:GetService("Players")
local SRun = game:GetService("RunService")
local STween = game:GetService("TweenService")

--Modules
local M1 = require(script.M1Module)
local Projectile = require(script.ProjectileModule)
local BalloonAnimation = require(script.BalloonAnimation)
local Mobile = require(script.Mobile)

--Vars
local LPlayer = SPLayer.LocalPlayer
local PlayerGui = LPlayer.PlayerGui
local Char = LPlayer.Character or LPlayer.CharacterAdded:Wait()
--Remotes
local BalloonLoaded = RStorage.Remotes.Balloon


local Melee = true


UIS.InputBegan:Connect(function(Input, IsTyping)
	if IsTyping or Char:GetAttribute("Sliding") or Char:GetAttribute("Stunned") then return end
	
	if Input.UserInputType == Enum.UserInputType.MouseButton1 and Melee then
		M1.Attack()
	elseif Input.UserInputType == Enum.UserInputType.MouseButton1 and not Melee then
		Projectile.Projectile()
	end
end)


UIS.InputEnded:Connect(function(Input, IsTyping)
	if Char:GetAttribute("Sliding") or Char:GetAttribute("Stunned") then return end
	if Input.KeyCode == Enum.KeyCode.One then Melee = not Melee	end

	if Input.UserInputType == Enum.UserInputType.MouseButton1 then	
		Projectile.FireProjectile()
	end
end)

PlayerGui.MobileGui.SecondaryButton.MouseButton1Click:Connect(Mobile.SwitchState)
PlayerGui.MobileGui.Maximum_Radius.MainButton.InputBegan:Connect(Mobile.JoystickEnable)
UIS.TouchMoved:Connect(Mobile.Move)
UIS.InputEnded:Connect(Mobile.ProjectileJoystickDisable)


RStorage.Remotes.ShootRemote.OnClientEvent:Connect(Projectile.CreateProjectile)
BalloonLoaded.OnClientEvent:Connect(BalloonAnimation.Damaged) --Add Balloon Animation
