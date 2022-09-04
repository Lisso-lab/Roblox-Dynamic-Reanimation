--!strict
--[[Project GAY!!!!!! Project GAY!!!! The most gayest reanimation!!!!]]

local settings = {
    ["Stabilize Method"] = "position", --[[Options: <position, cframe>
        position works muuch better with permanent death, but
        it breaks head in simple method.
    ]]
    ["Reanim Method"] = "simple", --[[Options: <simple, perma>
        permanent death (perma): Puts your character into undead state.
        Makes head movement possible.
        simple: Player stays alive, really simple pretty much.
    ]]
    ["Headless"] = false, --Only woks with Permanent death, removes head.
    ["Move Head Hats"] = true, --[[This option only works in simple method.
        If set to true, hats which are on your head will move with fake characters
        head.
    ]]
    ["Keep Animations"] = false, --[[Option to set to keep default roblox animations
        after reanimation. Some scripts don't disable Animate, so this is generally
        good thing to have as an option.
    ]]

    ["Static Velocity"] = Vector3.new(0,50,0), --[[Velocity used when not moving, or
        when dynamic velocity is disabled.
    ]]
    ["Dynamic Velocity"] = true, --Dynamic velocity works as follows: MoveDirection * multiplier
    ["Dv Multiplier"] = 50, --Dv stands for Dynamic Velocity. The amount dv is applied by

    ["Rot Velocity"] = true, --Rotational Velocity is actually pretty good!
    ["Rv Multiplier"] = 5, --The amount RotVelocity is multiplied by. Small amount recommended.

    ["Jump Velocity"] = true, --Applies velocity of jumping on real character from the fake one.

    ["DV Debounce"] = .05, --[[Quickly switching between moving and standing still
        worsens stability, this tries to minigate it.
    ]]
    ["Legacy Net"] = true, --[[Legacy net used in first generation of reanimations
        Sets SimulationRadius to massive number for big simulation radius,
        now server locked into 1000 maximum.
    ]]
    ["Physics Tweaks"] = true, --[[Various physics tweaks which should improve
        netowrk ownership of parts
    ]]
    ["Fake Char Noclip"] = true --Disable collisions on fake character...
}

--Project GAY ultimatum settings done!!! -- GAY defining start!!!--

local starter_gui: StarterGui = game:GetService("StarterGui")
local plrs: Players = game:GetService("Players")

local plr: Player = plrs.LocalPlayer

local char: Model = plr.Character or workspace[plr.Name]
local hum: Humanoid = char:FindFirstChildWhichIsA("Humanoid")

local _char: Model    --Fake character
local _hum:  Humanoid --Fake humanoid

local reset_function_init: boolean = false
local bindable_event: BindableEvent --Used to hook reset button

local net_functions = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lisso-lab/NetModule/main/main.lua"))()
local rs_connections = {}

--GAY defining done!!! -- GAY function start!!!--

local function reset()
    if reset_function_init then return end
    reset_function_init = true

    for i=1,#rs_connections do
        rs_connections[i]:Disconnect()
    end

    plr.Character = char; char:BreakJoints()
    _char:BreakJoints()

    bindable_event:Destroy()

    char:Destroy(); _char:Destroy()

    starter_gui:SetCore("ResetButtonCallback", true)

    print("Succesfully disabled all connections, reset.")
end

local function process_p(inst: Instance) --r will stand for real.
    local r_inst = char[inst.Name]

    if inst:IsA("Accessory") then
        inst = inst:FindFirstChildWhichIsA("BasePart")
        r_inst = r_inst:FindFirstChildWhichIsA("BasePart")
    end

    for _, child in pairs(r_inst:GetChildren()) do
        if child:IsA("Motor6D") and child.Name ~= "Neck" then child:Destroy() end

        if not child:IsA("Weld") then continue end

        if settings["Move Head Hats"] then
            child:Destroy()
        else
            if child.Part1.Name == "Head" then
                if settings["Reanim Method"] == "perma" then child:Destroy() end
            else
                child:Destroy()
            end
        end
    end

    inst.Transparency = 1
    for _, child in pairs(inst:GetChildren()) do
        if child:IsA("Texture") or child:IsA("Decal") then child.Transparency = 1 end
    end

    if settings["Permanent Death"] then
        net_functions.part_tweaks(r_inst, nil, {
            density = 0,
            friction = 0,
            friction_weight = 0
        }) --Having customphysi... Set all to 0 makes perma more stable for some reason...
    else
        net_functions.part_tweaks(r_inst)
    end

    if settings["Reanim Method"] == "perma" and inst.Name == "Head" then
        rs_connections[#rs_connections+1], rs_connections[#rs_connections+2] =
        net_functions.stabilize(
            r_inst, --what part
            inst, --to what part
            _hum,
            settings["Jump Velocity"] and _char or nil, {
                stabilize_method = settings["Stabilize Method"],
                calc_rotvel = false,
                apply_vel  = false
            }
        )
    else
        rs_connections[#rs_connections+1], rs_connections[#rs_connections+2] =
        net_functions.stabilize(
            r_inst, --what part
            inst, --to what part
            _hum,
            settings["Jump Velocity"] and _char or nil, {
                st_vel =       settings["St Velocity"],
                dv_amplifier = settings["Dv Multiplier"],
                dv_debounde =  settings["Dv Debounce"],
                rv_amplifier = settings["Rv Multiplier"],
                dynamic_vel =  settings["Dynamic Velocity"],
                calc_rotvel =  settings["Rot Velocity"],
                stabilize_method = settings["Stabilize Method"]
            }
        )
    end
end

--GAY functions done -- GAY real coding start--

if settings["Physics Tweaks"] then net_functions.physics_tweaks(hum) end

char.Archivable = true

for _, x in pairs(char:GetDescendants()) do --x is just for shortness
    if x:IsA("Shirt") or x:IsA("Pants") or x:IsA("CharacterMesh") or
       x:IsA("SpecialMesh") or x:IsA("ForceField")
    then
        x.Archivable = false
    end
end

do local acc_names = {} --Accesory names
    for _, acc in pairs(hum:GetAccessories()) do
        local tabl = acc_names[acc.Name]

        if tabl then
            tabl[#tabl+1] = "PROJECT GAY"

            acc.Name = acc.Name .. #tabl
        else
            acc_names[acc.Name] = {}
        end
    end
end --Renames hats in lua style: hat, hat1, hat2, hat3

_char = char:Clone()
_char.Parent = workspace
_char.Name = "_" .. char.Name

_hum = _char:FindFirstChildWhichIsA("Humanoid")

hum:ChangeState(Enum.HumanoidStateType.Physics)
for _, anim_tracks in pairs(hum:GetPlayingAnimationTracks()) do
    anim_tracks:Stop()
end

do local animate: LocalScript = char:FindFirstChild("Animate")
    if animate then animate.Disabled = true end
end

if settings["Keep Animations"] then
    local animate: LocalScript = char:FindFirstChild("Animate")

    if animate then
        coroutine.wrap(function()
            animate.Disabled = true; task.wait(.2); animate.Disabled = false
        end)()
    end
end

--GAY real coding done!!! -- GAY finalizing start!!!--

starter_gui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

local prev_grav = workspace.Gravity
workspace.Gravity = 50

char:MoveTo(char.PrimaryPart.Position + Vector3.new(0,10,0))
task.wait(.1)
_char:MoveTo(char.PrimaryPart.Position)
task.wait(.2)

rs_connections[#rs_connections + 1] = net_functions.disable_collisions_model(char)

for _, child in pairs(_char:GetChildren()) do
    if child:IsA("BasePart") or child:IsA("Accessory") then process_p(child) end
end
task.wait(.2)

if settings["Reanim Method"] == "perma" then
    char.Parent = _char

    coroutine.wrap(function()
        plr.Character = nil; plr.Character = _char

        task.wait(plrs.RespawnTime + .2)

        for _, child in pairs(char:GetDescendants()) do
            if child:IsA("Motor6D") and child.Name == "Neck" then child:Destroy() end
        end

        char.Parent = workspace
    end)()
else
    plr.Character = _char
end

starter_gui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)

workspace.CurrentCamera.CameraSubject = _hum
workspace.Gravity = prev_grav

bindable_event = Instance.new("BindableEvent"); bindable_event.Event:Connect(reset)
starter_gui:SetCore("ResetButtonCallback", bindable_event)

--GAY finalizing done!!! -- GAY connecting starting!!!--

if settings["Legacy Net"] then rs_connections[#rs_connections+1] = net_functions.sim_rad(plr) end
if settings["Fake Char Noclip"] then rs_connections[#rs_connections+1] = net_functions.disable_collisions_model(_char) end

rs_connections[#rs_connections + 1] = plr.CharacterRemoving:Connect(reset)

--Done! Project GAY by Iss0, Iss0#2367 or SkiuulLPcz
