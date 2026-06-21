local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local REMOTE_FOLDER_NAME="SoulRemotes"
local DIED_REMOTE_NAME="Soul_Died"
local RESPAWN_REMOTE_NAME="Soul_Respawn"
local Soul={}
local started=false
local diedRemote=nil
local respawnRemote=nil
local deathConnections={}
local function ensureRemotes()
    if diedRemote and respawnRemote then return end
    local folder=ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
    if not folder then
        folder=Instance.new("Folder")
        folder.Name=REMOTE_FOLDER_NAME
        folder.Parent=ReplicatedStorage
    end
    local died=folder:FindFirstChild(DIED_REMOTE_NAME)
    if not died then
        died=Instance.new("RemoteEvent")
        died.Name=DIED_REMOTE_NAME
        died.Parent=folder
    end
    diedRemote=died
    local respawn=folder:FindFirstChild(RESPAWN_REMOTE_NAME)
    if not respawn then
        respawn=Instance.new("RemoteEvent")
        respawn.Name=RESPAWN_REMOTE_NAME
        respawn.Parent=folder
    end
    respawnRemote=respawn
    respawnRemote.OnServerEvent:Connect(function(player)
        player:LoadCharacter()
    end)
end
local function watchHumanoid(humanoid,player)
    if deathConnections[humanoid] then return end
    deathConnections[humanoid]=humanoid.Died:Connect(function()
        local character=humanoid.Parent
        local rootPart=character and character:FindFirstChild("HumanoidRootPart")
        local deathPosition=rootPart and rootPart.Position or Vector3.new()
        if diedRemote then
            diedRemote:FireClient(player,deathPosition)
        end
    end)
    humanoid.AncestryChanged:Connect(function(_,parent)
        if parent==nil then
            if deathConnections[humanoid] then
                deathConnections[humanoid]:Disconnect()
                deathConnections[humanoid]=nil
            end
        end
    end)
end
local function watchPlayer(player)
    player.CharacterAdded:Connect(function(character)
        local humanoid=character:WaitForChild("Humanoid",5)
        if humanoid then watchHumanoid(humanoid,player) end
    end)
    if player.Character then
        local humanoid=player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then watchHumanoid(humanoid,player) end
    end
end
function Soul.start()
    if started then return end
    started=true
    ensureRemotes()
    Players.CharacterAutoLoads=false
    for _,player in ipairs(Players:GetPlayers()) do
        watchPlayer(player)
        if not player.Character then player:LoadCharacter() end
    end
    Players.PlayerAdded:Connect(function(player)
        watchPlayer(player)
        player:LoadCharacter()
    end)
end
return Soul
