local CollectionService=game:GetService("CollectionService")
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local ATTACK_RANGE=7
local ATTACK_DAMAGE=28
local ATTACK_COOLDOWN=0.8
local CHASE_SPEED=16
local WINDUP_SECONDS=0.18
local LUNGE_SPEED=14
local KNOCKBACK_SPEED=20
local SPAWN_GRACE_SECONDS=3
local handled={}
local spawnGraceUntil={}
local function watchPlayerSpawns(player)
    player.CharacterAdded:Connect(function()
        spawnGraceUntil[player]=os.clock()+SPAWN_GRACE_SECONDS
    end)
end
for _,player in ipairs(Players:GetPlayers()) do
    watchPlayerSpawns(player)
end
Players.PlayerAdded:Connect(watchPlayerSpawns)
local function findNearestPlayerRoot(fromPosition)
    local nearestRoot=nil
    local nearestPlayer=nil
    local nearestDistance=math.huge
    for _,player in ipairs(Players:GetPlayers()) do
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local graceUntil=spawnGraceUntil[player]
        if root and humanoid and humanoid.Health>0 and (graceUntil==nil or os.clock()>=graceUntil) then
            local distance=(root.Position-fromPosition).Magnitude
            if distance<nearestDistance then
                nearestDistance=distance
                nearestRoot=root
                nearestPlayer=player
            end
        end
    end
    return nearestRoot,nearestPlayer
end
local function flashHit(character)
    local highlight=Instance.new("Highlight")
    highlight.FillColor=Color3.fromRGB(255,50,50)
    highlight.FillTransparency=0.35
    highlight.OutlineTransparency=0
    highlight.OutlineColor=Color3.fromRGB(255,0,0)
    highlight.Adornee=character
    highlight.Parent=character
    task.delay(0.15,function() highlight:Destroy() end)
end
local function horizontalDirection(from,to)
    local delta=Vector3.new(to.X-from.X,0,to.Z-from.Z)
    if delta.Magnitude<1e-3 then return Vector3.new(1,0,0) end
    return delta.Unit
end
local function performAttack(humanoid,rootPart,targetHumanoid,targetRoot)
    local direction=horizontalDirection(rootPart.Position,targetRoot.Position)
    task.wait(WINDUP_SECONDS)
    if humanoid.Health<=0 or rootPart.Parent==nil then return end
    rootPart.AssemblyLinearVelocity=Vector3.new(direction.X,0,direction.Z)*LUNGE_SPEED
    if targetHumanoid.Health<=0 or targetRoot.Parent==nil then return end
    targetHumanoid:TakeDamage(ATTACK_DAMAGE)
    flashHit(targetRoot.Parent)
    targetRoot.AssemblyLinearVelocity+=direction*KNOCKBACK_SPEED+Vector3.new(0,10,0)
end
local function runDummy(dummy,humanoid,rootPart)
    humanoid.WalkSpeed=CHASE_SPEED
    CollectionService:AddTag(dummy,"Enemy")
    local lastAttack=0
    while dummy.Parent and humanoid.Health>0 do
        local targetRoot,targetPlayer=findNearestPlayerRoot(rootPart.Position)
        if targetRoot and targetPlayer then
            local targetHumanoid=targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
            local distance=(targetRoot.Position-rootPart.Position).Magnitude
            if distance<=ATTACK_RANGE then
                humanoid:MoveTo(rootPart.Position)
                local now=os.clock()
                if targetHumanoid and targetHumanoid.Health>0 and now-lastAttack>=ATTACK_COOLDOWN then
                    lastAttack=now
                    task.spawn(performAttack,humanoid,rootPart,targetHumanoid,targetRoot)
                end
            else
                humanoid:MoveTo(targetRoot.Position)
            end
        end
        task.wait(0.2)
    end
    handled[dummy]=nil
end
local function tryHandle(model)
    if not model:IsA("Model") then return end
    if handled[model] then return end
    if Players:GetPlayerFromCharacter(model) then return end
    local humanoid=model:FindFirstChildOfClass("Humanoid")
    local rootPart=model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end
    handled[model]=true
    task.spawn(runDummy,model,humanoid,rootPart)
end
for _,child in ipairs(Workspace:GetChildren()) do tryHandle(child) end
Workspace.ChildAdded:Connect(tryHandle)
print("Sirius: DummyAttacker watching Workspace for Humanoid models")
