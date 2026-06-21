local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local UserInputService=game:GetService("UserInputService")
local Workspace=game:GetService("Workspace")
local REMOTE_FOLDER_NAME="SoulRemotes"
local DIED_REMOTE_NAME="Soul_Died"
local RESPAWN_REMOTE_NAME="Soul_Respawn"
local RISE_HEIGHT=4
local RISE_DURATION=1
local FLY_SPEED=26
local BOOST_MULTIPLIER=2
local MOUSE_SENSITIVITY=0.0035
local MAX_PITCH=1.2
local CAMERA_BACK_OFFSET=Vector3.new(0,2.2,9)
local CAMERA_RISE_START_OFFSET=Vector3.new(0,1.2,4.5)
local CAMERA_MIN_DISTANCE=1.5
local TARGET_FOV=105
local SOUL_EXTRA_TRANSPARENCY=0.45
local MAX_STEP_DT=1/30
local HOVER_ANIMATION_ID="rbxassetid://913383913"
local FLY_ANIMATION_ID="rbxassetid://913384386"
local Soul={}
local started=false
local localPlayer=Players.LocalPlayer
local function waitForRemotes()
    local folder=ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME)
    return folder:WaitForChild(DIED_REMOTE_NAME),folder:WaitForChild(RESPAWN_REMOTE_NAME)
end
local function buildOrb()
    local orb=Instance.new("Part")
    orb.Name="Soul"
    orb.Shape=Enum.PartType.Ball
    orb.Size=Vector3.new(1.4,1.4,1.4)
    orb.Material=Enum.Material.Neon
    orb.Color=Color3.fromRGB(150,210,255)
    orb.Anchored=true
    orb.CanCollide=false
    orb.CanQuery=false
    orb.CanTouch=false
    orb.Transparency=1
    orb.Parent=Workspace
    local light=Instance.new("PointLight")
    light.Color=Color3.fromRGB(170,220,255)
    light.Range=12
    light.Brightness=2
    light.Parent=orb
    local particles=Instance.new("ParticleEmitter")
    particles.Color=ColorSequence.new(Color3.fromRGB(200,230,255))
    particles.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.6),NumberSequenceKeypoint.new(1,0)})
    particles.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.4),NumberSequenceKeypoint.new(1,1)})
    particles.Lifetime=NumberRange.new(0.6,1.2)
    particles.Rate=18
    particles.Speed=NumberRange.new(0.5,1.5)
    particles.SpreadAngle=Vector2.new(180,180)
    particles.Parent=orb
    return orb,particles,light
end
local function loadSoulAnimation(animator,animationId)
    local animation=Instance.new("Animation")
    animation.AnimationId=animationId
    local ok,track=pcall(function() return animator:LoadAnimation(animation) end)
    animation:Destroy()
    if ok and track then
        track.Looped=true
        return track
    end
    return nil
end
local function buildSoulCharacter(userId)
    local ok,description=pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
    if not ok or not description then return nil end
    local okModel,model=pcall(function() return Players:CreateHumanoidModelFromDescription(description,Enum.HumanoidRigType.R15) end)
    if not okModel or not model then return nil end
    local root=model:FindFirstChild("HumanoidRootPart")
    local humanoid=model:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then model:Destroy() return nil end
    model.PrimaryPart=root
    model.Parent=Workspace
    humanoid.PlatformStand=true
    for _,state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
        if state~=Enum.HumanoidStateType.None then
            pcall(function() humanoid:SetStateEnabled(state,false) end)
        end
    end
    local targetTransparency={}
    for _,descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored=true
            descendant.CanCollide=false
            descendant.CanQuery=false
            descendant.CanTouch=false
            if descendant==root then
                targetTransparency[descendant]=1
            else
                targetTransparency[descendant]=math.clamp(descendant.Transparency+SOUL_EXTRA_TRANSPARENCY,0,1)
            end
            descendant.Transparency=1
        end
    end
    local highlight=Instance.new("Highlight")
    highlight.FillColor=Color3.fromRGB(150,210,255)
    highlight.FillTransparency=0.8
    highlight.OutlineColor=Color3.fromRGB(210,235,255)
    highlight.OutlineTransparency=0
    highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent=model
    local light=Instance.new("PointLight")
    light.Color=Color3.fromRGB(170,220,255)
    light.Range=14
    light.Brightness=2
    light.Parent=root
    local particles=Instance.new("ParticleEmitter")
    particles.Color=ColorSequence.new(Color3.fromRGB(200,230,255))
    particles.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(1,0)})
    particles.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(1,1)})
    particles.Lifetime=NumberRange.new(0.6,1.2)
    particles.Rate=14
    particles.Speed=NumberRange.new(0.5,1.5)
    particles.SpreadAngle=Vector2.new(180,180)
    particles.Parent=root
    local animator=humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator",humanoid)
    return {model=model,root=root,targetTransparency=targetTransparency,hoverTrack=loadSoulAnimation(animator,HOVER_ANIMATION_ID),flyTrack=loadSoulAnimation(animator,FLY_ANIMATION_ID),particles=particles,light=light}
end
local function buildPromptGui()
    local gui=Instance.new("ScreenGui")
    gui.Name="SoulPrompt"
    gui.ResetOnSpawn=false
    gui.IgnoreGuiInset=true
    local button=Instance.new("TextButton")
    button.Name="ReturnButton"
    -- im baran, always check codes!!!
    button.AnchorPoint=Vector2.new(0.5,1)
    button.Position=UDim2.new(0.5,0,1,-40)
    button.Size=UDim2.new(0,260,0,44)
    button.BackgroundColor3=Color3.fromRGB(20,30,45)
    button.BackgroundTransparency=0.25
    button.TextColor3=Color3.fromRGB(220,240,255)
    button.Font=Enum.Font.GothamMedium
    button.TextSize=18
    button.Text="Press E to return"
    button.Parent=gui
    return gui,button
end
local function makeOrbHandle()
    local orb,particles,light=buildOrb()
    return {
        place=function(cf) orb.CFrame=cf end,
        setRiseProgress=function(e) orb.Transparency=1-e*0.85 end,
        setMoving=function() end,
        destroy=function() orb:Destroy() end,
        particles=particles,
        light=light,
        excludeInstance=orb,
    }
end
local function makeCharacterHandle(rig)
    local currentTrack
    local function playTrack(track)
        if currentTrack==track then return end
        if currentTrack then currentTrack:Stop(0.2) end
        if track then track:Play(0.2) end
        currentTrack=track
    end
    return {
        place=function(cf) rig.model:PivotTo(cf) end,
        setRiseProgress=function(e)
            for part,target in pairs(rig.targetTransparency) do
                part.Transparency=1-e*(1-target)
            end
            if e>=1 then playTrack(rig.hoverTrack) end
        end,
        setMoving=function(moving) playTrack(moving and (rig.flyTrack or rig.hoverTrack) or rig.hoverTrack) end,
        destroy=function() rig.model:Destroy() end,
        particles=rig.particles,
        light=rig.light,
        excludeInstance=rig.model,
    }
end
local function isKeyDown(k)
    return UserInputService:IsKeyDown(k)
end
function Soul.start()
    if started then return end
    started=true
    local diedRemote,respawnRemote=waitForRemotes()
    diedRemote.OnClientEvent:Connect(function(deathPosition)
        local camera=Workspace.CurrentCamera
        if not camera then return end
        local savedCameraType=camera.CameraType
        local savedCameraCFrame=camera.CFrame
        local savedCameraSubject=camera.CameraSubject
        local savedCameraFOV=camera.FieldOfView
        camera.CameraType=Enum.CameraType.Scriptable
        local rig=buildSoulCharacter(localPlayer.UserId)
        local soul=rig and makeCharacterHandle(rig) or makeOrbHandle()
        local raycastParams=RaycastParams.new()
        raycastParams.FilterType=Enum.RaycastFilterType.Exclude
        local excluded={soul.excludeInstance}
        if localPlayer.Character then table.insert(excluded,localPlayer.Character) end
        raycastParams.FilterDescendantsInstances=excluded
        local startPosition=deathPosition+Vector3.new(0,1,0)
        soul.place(CFrame.new(startPosition))
        local gui,returnButton=buildPromptGui()
        gui.Parent=localPlayer:WaitForChild("PlayerGui")
        local position=startPosition
        local yaw=0
        local pitch=-0.15
        local looking=false
        local function updateCamera(targetPos,aimCFrame,offset)
            local lookCFrame=CFrame.new(targetPos)*aimCFrame
            local desiredCamPos=targetPos+lookCFrame:VectorToWorldSpace(offset)
            local toCam=desiredCamPos-targetPos
            local camPos=desiredCamPos
            local rayResult=Workspace:Raycast(targetPos,toCam,raycastParams)
            if rayResult then
                local hitDistance=(rayResult.Position-targetPos).Magnitude
                camPos=targetPos+toCam.Unit*math.max(hitDistance-0.5,CAMERA_MIN_DISTANCE)
            end
            camera.CFrame=CFrame.lookAt(camPos,targetPos)
        end
        local initialAim=CFrame.fromOrientation(pitch,yaw,0)
        updateCamera(startPosition,initialAim,CAMERA_RISE_START_OFFSET)
        local flying=false
        local renderConn,inputBeganConn,inputEndedConn
        local function setLooking(on)
            looking=on
            UserInputService.MouseBehavior=on and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled=not on
        end
        local function cleanup(respawning)
            flying=false
            if renderConn then renderConn:Disconnect() renderConn=nil end
            if inputBeganConn then inputBeganConn:Disconnect() inputBeganConn=nil end
            if inputEndedConn then inputEndedConn:Disconnect() inputEndedConn=nil end
            setLooking(false)
            gui:Destroy()
            soul.destroy()
            if respawning then
                respawnRemote:FireServer()
                camera.CameraType=Enum.CameraType.Custom
                camera.CameraSubject=nil
                camera.FieldOfView=savedCameraFOV
            else
                camera.CameraType=savedCameraType
                camera.CameraSubject=savedCameraSubject
                camera.CFrame=savedCameraCFrame
                camera.FieldOfView=savedCameraFOV
            end
        end
        local function startFlying()
            flying=true
            soul.setMoving(false)
            renderConn=RunService.RenderStepped:Connect(function(rawDt)
                if not flying then return end
                local dt=math.min(rawDt,MAX_STEP_DT)
                if looking then
                    local delta=UserInputService:GetMouseDelta()
                    yaw-=delta.X*MOUSE_SENSITIVITY
                    pitch=math.clamp(pitch-delta.Y*MOUSE_SENSITIVITY,-MAX_PITCH,MAX_PITCH)
                end
                local aimCFrame=CFrame.fromOrientation(pitch,yaw,0)
                local moveDir=Vector3.zero
                if isKeyDown(Enum.KeyCode.W) then moveDir+=aimCFrame.LookVector end
                if isKeyDown(Enum.KeyCode.S) then moveDir-=aimCFrame.LookVector end
                if isKeyDown(Enum.KeyCode.D) then moveDir+=aimCFrame.RightVector end
                if isKeyDown(Enum.KeyCode.A) then moveDir-=aimCFrame.RightVector end
                local isMoving=moveDir.Magnitude>0.001
                if isMoving then
                    local speed=FLY_SPEED
                    if isKeyDown(Enum.KeyCode.LeftShift) then speed*=BOOST_MULTIPLIER end
                    position+=moveDir.Unit*speed*dt
                end
                soul.setMoving(isMoving)
                soul.place(CFrame.new(position)*aimCFrame)
                updateCamera(position,aimCFrame,CAMERA_BACK_OFFSET)
            end)
            inputBeganConn=UserInputService.InputBegan:Connect(function(input,gameProcessed)
                if input.UserInputType==Enum.UserInputType.MouseButton2 then
                    setLooking(true)
                    return
                end
                if gameProcessed then return end
                if input.KeyCode==Enum.KeyCode.E then cleanup(true) end
            end)
            inputEndedConn=UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton2 then setLooking(false) end
            end)
            returnButton.MouseButton1Click:Connect(function() cleanup(true) end)
        end
        local riseStart=startPosition
        local riseEnd=startPosition+Vector3.new(0,RISE_HEIGHT,0)
        local riseElapsed=0
        local riseConn
        riseConn=RunService.RenderStepped:Connect(function(rawDt)
            local dt=math.min(rawDt,MAX_STEP_DT)
            riseElapsed+=dt
            local alpha=math.clamp(riseElapsed/RISE_DURATION,0,1)
            local eased=TweenService:GetValue(alpha,Enum.EasingStyle.Sine,Enum.EasingDirection.Out)
            local risePos=riseStart:Lerp(riseEnd,eased)
            local aimCFrame=CFrame.fromOrientation(pitch,yaw,0)
            soul.place(CFrame.new(risePos)*aimCFrame)
            soul.setRiseProgress(eased)
            updateCamera(risePos,aimCFrame,CAMERA_RISE_START_OFFSET:Lerp(CAMERA_BACK_OFFSET,eased))
            camera.FieldOfView=savedCameraFOV+(TARGET_FOV-savedCameraFOV)*eased
            if alpha>=1 then
                if riseConn then riseConn:Disconnect() riseConn=nil end
                position=risePos
                startFlying()
            end
        end)
        soul.particles.Enabled=true
        soul.light.Enabled=true
    end)
end
return Soul
