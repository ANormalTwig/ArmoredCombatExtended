ACF = {}

ACF.AmmoTypes = {}
ACF.MenuFunc = {}
ACF.AmmoBlacklist = {}
ACF.Version = 478           -- ACE current version
ACF.CurrentVersion = 0      -- just defining a variable, do not change

ACF.Year = 2022             -- Current Year

print('[ACE | INFO]- loading ACE. . .')

ACE                 = {}
ACE.ArmorTypes      = {}

ACF.Weapons         = {}
ACF.Classes         = {}
ACF.RoundTypes      = {}
ACF.IdRounds        = {}    --Lookup tables so i can get rounds classes from clientside with just an integer

--[[----------------------------
       Entity Limits
]]------------------------------

CreateConVar('sbox_max_acf_gun', 24)                            -- Gun limit
CreateConVar('sbox_max_acf_rapidgun', 4)                        -- Guns like RACs, MGs, and ACs
CreateConVar('sbox_max_acf_largegun', 2)                        -- Guns with a caliber above 100mm
CreateConVar('sbox_max_acf_smokelauncher', 20)                  -- smoke launcher limit
CreateConVar('sbox_max_acf_ammo', 50)                           -- ammo limit
CreateConVar('sbox_max_acf_misc', 50)                           -- misc ents limit
CreateConVar('sbox_max_acf_rack', 12)                           -- Racks limit

--CreateConVar('sbox_max_acf_mines', 5)                         -- mines. Experimental
CreateConVar('acf_meshvalue', 1) 
CreateConVar("sbox_acf_restrictinfo", 1)                        -- 0=any, 1=owned

-- Cvars for legality checking
CreateConVar( "acf_legalcheck", 1 , FCVAR_ARCHIVE)
CreateConVar( "acf_legal_ignore_model", 0 , FCVAR_ARCHIVE)
CreateConVar( "acf_legal_ignore_solid", 0 , FCVAR_ARCHIVE)
CreateConVar( "acf_legal_ignore_mass", 0 , FCVAR_ARCHIVE)
CreateConVar( "acf_legal_ignore_material", 0 , FCVAR_ARCHIVE)
CreateConVar( "acf_legal_ignore_inertia", 0 , FCVAR_ARCHIVE)
CreateConVar( "acf_legal_ignore_makesphere", 0 , FCVAR_ARCHIVE)
CreateConVar( "acf_legal_ignore_visclip", 0 , FCVAR_ARCHIVE)
CreateConVar( "acf_legal_ignore_parent", 0 , FCVAR_ARCHIVE)

-- Prop Protection system
CreateConVar( "acf_enable_dp", 0 , FCVAR_ARCHIVE )    -- Enable the inbuilt damage protection system.    

-- Cvars for recoil/he push
CreateConVar("acf_hepush", 1, FCVAR_ARCHIVE)
CreateConVar("acf_recoilpush", 1, FCVAR_ARCHIVE)

-- New healthmod/armormod/ammomod cvars
CreateConVar("acf_healthmod", 1, FCVAR_ARCHIVE)
CreateConVar("acf_armormod", 1, FCVAR_ARCHIVE)
CreateConVar("acf_ammomod", 1, FCVAR_ARCHIVE)
CreateConVar("acf_gunfire", 1, FCVAR_ARCHIVE)

-- Debris
CreateConVar("acf_debris_lifetime", 30, FCVAR_ARCHIVE)
CreateConVar("acf_debris_children", 1, FCVAR_ARCHIVE)

-- Spalling
CreateConVar("acf_spalling", 1, FCVAR_ARCHIVE)
CreateConVar("acf_spalling_multipler", 1, FCVAR_ARCHIVE)

-- Scaled Explosions
CreateConVar("acf_explosions_scaled_he_max", 100, FCVAR_ARCHIVE)
CreateConVar("acf_explosions_scaled_ents_max", 5, FCVAR_ARCHIVE)

if CLIENT then
--[[-----------------------------
        Client Convars
]]-------------------------------

    CreateClientConVar( "ACFM_MissileLights", 0 ) --Should missiles emit light while their motors are burning?  Looks nice but hits framerate. Set to 1 to enable, set to 0 to disable, set to another number to set minimum light-size.
    CreateClientConVar("acf_sens_irons", 0.5, true, false, "Reduce mouse sensitivity by this amount when zoomed in with iron sights on ACE SWEPs.", 0.01, 1)
    CreateClientConVar("acf_sens_scopes", 0.2, true, false, "Reduce mouse sensitivity by this amount when zoomed in with scopes on ACE SWEPs.", 0.01, 1)

end

ACFM = ACFM or {}

-- Useless
ACFM.FlareBurnMultiplier        = 0.5
ACFM.FlareDistractMultiplier    = 1 / 35

ACF.DebrisChance        = 0.5
ACF.DebrisLifeTime      = 60  

ACF.ScaledHEMax         = 50
ACF.ScaledEntsMax       = 5

ACF.LargeCaliber        = 10 --Gun caliber in CM to be considered a large caliber gun, 10cm = 100mm

ACF.Threshold           = 264.7                     -- Health Divisor (don't forget to update cvar function down below)
ACF.PartialPenPenalty   = 5                         -- Exponent for the damage penalty for partial penetration
ACF.PenAreaMod          = 0.85
ACF.KinFudgeFactor      = 2.1                       -- True kinetic would be 2, over that it's speed biaised, below it's mass biaised
ACF.KEtoRHA             = 0.25                      -- Empirical conversion from (kinetic energy in KJ)/(Area in Cm2) to RHA penetration
ACF.GroundtoRHA         = 0.15                      -- How much mm of steel is a mm of ground worth (Real soil is about 0.15)
ACF.KEtoSpall           = 1
ACF.AmmoMod             = 2.6                       -- Ammo modifier. 1 is 1x the amount of ammo
ACF.AmmoLengthMul       = 1
ACF.AmmoWidthMul        = 1
ACF.ArmorMod            = 1 
ACF.SlopeEffectFactor   = 1.1                       -- Sloped armor effectiveness: armor / cos(angle)^factor
ACF.Spalling            = 1
ACF.SpallMult           = 1

ACF.GunfireEnabled      = true
ACF.MeshCalcEnabled     = false

ACF.BoomMult            = 1.5                       -- How much more do ammocrates blow up, useful since crates detonate all at once now.

--ACF Damage Multipler.

ACF.APDamageMult        = 2                         -- AP Damage Multipler             -1.1
ACF.APCDamageMult       = 1.5                       -- APC Damage Multipler           -1.1
ACF.APBCDamageMult      = 1.5                       -- APBC Damage Multipler           -1.05
ACF.APCBCDamageMult     = 1.0                       -- APCBC Damage Multipler           -1.05
ACF.APHEDamageMult      = 1.5                       -- APHE Damage Multipler          
ACF.APDSDamageMult      = 1.5                       -- APDS Damage Multipler          
ACF.HVAPDamageMult      = 1.65                      -- HVAP/APCR Damage Multipler
ACF.FLDamageMult        = 1.4                       -- FL Damage Multipler
ACF.HEATDamageMult      = 2                         -- HEAT Damage Multipler
ACF.HEDamageMult        = 2                         -- HE Damage Multipler
ACF.HESHDamageMult      = 1.2                       -- HESH Damage Multipler
ACF.HPDamageMult        = 8                         -- HP Damage Multipler

--ACF HE

ACF.HEDamageFactor      = 50

ACF.HEPower             = 8000                      -- HE Filler power per KG in KJ
ACF.HEDensity           = 1.65                      -- HE Filler density (That's TNT density)
ACF.HEFrag              = 1500                      -- Mean fragment number for equal weight TNT and casing
ACF.HEBlastPen          = 0.4                       -- Blast penetration exponent based of HE power
ACF.HEFeatherExp        = 0.5                       -- exponent applied to HE dist/maxdist feathering, <1 will increasingly bias toward max damage until sharp falloff at outer edge of range
ACF.HEATMVScale         = 0.75                      -- Filler KE to HEAT slug KE conversion expotential
ACF.HEATMVScaleTan      = 0.75                      -- Filler KE to HEAT slug KE conversion expotential
ACF.HEATMulAmmo         = 30                        -- HEAT slug damage multiplier; 13.2x roughly equal to AP damage
ACF.HEATMulFuel         = 4                         -- needs less multiplier, much less health than ammo
ACF.HEATMulEngine       = 10                        -- likewise
ACF.HEATPenLayerMul     = 0.95                      -- HEAT base energy multiplier
ACF.HEATBoomConvert     = 1/3                       -- percentage of filler that creates HE damage at detonation

ACF.DragDiv             = 80                        -- Drag fudge factor
ACF.VelScale            = 1                         -- Scale factor for the shell velocities in the game world

ACF.PhysMaxVel          = 8000
ACF.SmokeWind           = 5 + math.random()*35      -- affects the ability of smoke to be used for screening effect

ACF.PBase               = 1050                      -- 1KG of propellant produces this much KE at the muzzle, in kj
ACF.PScale              = 1                         -- Gun Propellant power expotential
ACF.MVScale             = 0.5                       -- Propellant to MV convertion expotential
ACF.PDensity            = 1.6                       -- Gun propellant density (Real powders go from 0.7 to 1.6, i'm using higher densities to simulate case bottlenecking)

ACF.TorqueBoost         = 1.25                      -- torque multiplier from using fuel
ACF.DriverTorqueBoost   = 0.25                      -- torque multiplier from having a driver
ACF.FuelRate            = 10                        -- multiplier for fuel usage, 1.0 is approx real world
ACF.ElecRate            = 2                         -- multiplier for electrics                                   --BEFORE to balance: 0.458
ACF.TankVolumeMul       = 1                         -- multiplier for fuel tank capacity, 1.0 is approx real world


ACF.NormalizationFactor = 0.15                      -- at 0.1(10%) a round hitting a 70 degree plate will act as if its hitting a 63 degree plate, this only applies to capped and LRP ammunition.

ACF.AllowCSLua          = 0

ACF.LiIonED             = 0.27                      -- li-ion energy density: kw hours / liter --BEFORE to balance: 0.458
ACF.CuIToLiter          = 0.0163871                 -- cubic inches to liters

ACF.RefillDistance      = 400                       -- Distance in which ammo crate starts refilling.
ACF.RefillSpeed         = 250                       -- (ACF.RefillSpeed / RoundMass) / Distance 

ACF.DebrisIgniteChance  = 0.25
ACF.DebrisScale         = 20                        -- Ignore debris that is less than this bounding radius.
ACF.SpreadScale         = 16                        -- The maximum amount that damage can decrease a gun's accuracy.  Default 4x
ACF.GunInaccuracyScale  = 1                         -- A multiplier for gun accuracy.
ACF.GunInaccuracyBias   = 2                         -- Higher numbers make shots more likely to be inaccurate.  Choose between 0.5 to 4. Default is 2 (unbiased).

ACF.EnableKillicons     = true                      -- Enable killicons overwriting.

if ACF.AllowCSLua > 0 then
    AddCSLuaFile("autorun/translation/ace_translationpacks.lua")
    RunConsoleCommand( "sv_allowcslua", 1 )
    include("autorun/translation/ace_translationpacks.lua") --File that is overwritten to install a translation pack
else
    RunConsoleCommand( "sv_allowcslua", 0 )
    include("autorun/translation/ace_translationpacks.lua")
    AddCSLuaFile("autorun/translation/ace_translationpacks.lua")
end

include("acf/shared/sh_ace_particles.lua")
include("acf/shared/sh_ace_sound_loader.lua")
include("autorun/acf_missile/folder.lua")
include("acf/shared/sh_ace_functions.lua")
include("acf/shared/sh_ace_loader.lua")
include("acf/shared/sh_ace_concommands.lua")
include("acf/shared/sh_acfm_roundinject.lua")

if SERVER then

    include("acf/shared/sv_ace_networking.lua")

    include("acf/server/sv_acfbase.lua")
    include("acf/server/sv_acfdamage.lua")
    include("acf/server/sv_acfballistics.lua")
    include("acf/server/sv_contraption.lua")
    include("acf/server/sv_heat.lua")
    include("acf/server/sv_legality.lua")


    include("acf/server/sv_acfpermission.lua")


    AddCSLuaFile("acf/client/cl_acfballistics.lua")
    AddCSLuaFile("acf/client/cl_acfmenu_gui.lua")
    AddCSLuaFile("acf/client/cl_acfrender.lua")
    AddCSLuaFile("acf/client/cl_extension.lua")

    AddCSLuaFile("acf/client/cl_acfmenu_missileui.lua")

    AddCSLuaFile("acf/client/cl_acfpermission.lua")
    AddCSLuaFile("acf/client/gui/cl_acfsetpermission.lua")


elseif CLIENT then

    include("acf/client/cl_acfballistics.lua")
    include("acf/client/cl_acfrender.lua")
    include("acf/client/cl_extension.lua")

    include("acf/client/cl_acfpermission.lua")
    include("acf/client/gui/cl_acfsetpermission.lua")
    
    CreateConVar("acf_cl_particlemul", 1)
    CreateClientConVar("ACF_MobilityRopeLinks", "1", true, true)
    
    -- Cache results so we don't need to do expensive filesystem checks every time
    local IsValidCache = {}

    -- Returns whether or not a sound actually exists, fixes client timeout issues
    function IsValidSound( path )
        if IsValidCache[path] == nil then 
            IsValidCache[path] = file.Exists( string.format( "sound/%s", tostring( path ) ), "GAME" ) and true or false
        end
        return IsValidCache[path]
    end
    
end


--[[--------------------------------------
    RoundType Loader
]]----------------------------------------

include("acf/shared/rounds/ace_roundfunctions.lua")

include("acf/shared/rounds/roundap.lua")
include("acf/shared/rounds/roundhe.lua")
include("acf/shared/rounds/roundfl.lua")
include("acf/shared/rounds/roundhp.lua")
include("acf/shared/rounds/roundsmoke.lua")
include("acf/shared/rounds/roundrefill.lua")
include("acf/shared/rounds/roundapc.lua")
    

--interwar period
if ACF.Year > 1920 then

    include("acf/shared/rounds/roundapbc.lua")
    include("acf/shared/rounds/roundapcbc.lua")

end
--A surprising amount of things were made during WW2
if ACF.Year > 1939 then 

    include("acf/shared/rounds/roundhesh.lua")
    include("acf/shared/rounds/roundheat.lua")
    include("acf/shared/rounds/roundaphe.lua")
    include("acf/shared/rounds/roundaphecbc.lua")
    include("acf/shared/rounds/roundhvap.lua")
    
end
--Cold war
if ACF.Year > 1960 then

    include("acf/shared/rounds/roundapds.lua")
    include("acf/shared/rounds/roundapfsds.lua")
    include("acf/shared/rounds/roundheatfs.lua")
    include("acf/shared/rounds/roundhefs.lua")
    include("acf/shared/rounds/roundflare.lua")
    include("acf/shared/rounds/roundglgm.lua")
    
end
--almost finishing cold war
if ACF.Year > 1989 then

    include("acf/shared/rounds/roundtheat.lua")
    include("acf/shared/rounds/roundtheatfs.lua")
    
end


ACF.Weapons     = list.Get("ACFEnts")
ACF.Classes     = list.Get("ACFClasses")
ACF.RoundTypes  = list.Get("ACFRoundTypes")
ACF.IdRounds    = list.Get("ACFIdRounds")   --Lookup tables so i can get rounds classes from clientside with just an integer

ACE.Armors      = list.Get("ACE_MaterialTypes")
ACE.GSounds     = list.Get("ACESounds")


game.AddDecal("GunShot1", "decals/METAL/shot5")

-- Add the ACF tool category
if CLIENT then

    ACF.CustomToolCategory = CreateClientConVar( "acf_tool_category", 0, true, false );

    if( ACF.CustomToolCategory:GetBool() ) then

        language.Add( "spawnmenu.tools.acf", "ACF" );

        -- We use this hook so that the ACF category is always at the top
        hook.Add( "AddToolMenuTabs", "CreateACFCategory", function()

            spawnmenu.AddToolCategory( "Main", "ACF", "#spawnmenu.tools.acf" );

        end );

    end

end

timer.Simple( 0, function()
    for Class,Table in pairs(ACF.Classes["GunClass"]) do
        PrecacheParticleSystem(Table["muzzleflash"])
    end
end)

--Stupid workaround red added to precache timescaling.
hook.Add( "Think", "Update ACF Internal Clock", function()
    ACF.CurTime = CurTime()
    ACF.SysTime = SysTime()
end )


function ACF_CVarChangeCallback(CVar, Prev, New)

    if( CVar == "acf_healthmod" ) then
        ACF.Threshold = 264.7 / math.max(New, 0.01)
    elseif( CVar == "acf_armormod" ) then
        ACF.ArmorMod = 1 * math.max(New, 0)
    elseif( CVar == "acf_ammomod" ) then
        ACF.AmmoMod = 1 * math.max(New, 0.01)
    elseif( CVar == "acf_spalling" ) then
        ACF.Spalling = math.floor(math.Clamp(New, 0, 1))
    elseif( CVar == "acf_spalling_multipler" ) then
        ACF.SpallMult = math.Clamp(New, 1, 5)
    elseif( CVar == "acf_gunfire" ) then
        ACF.GunfireEnabled = tobool( New )
    elseif( CVar == "acf_debris_lifetime" ) then
        ACF.DebrisLifeTime = math.max( New,0)
    elseif( CVar == "acf_debris_children" ) then
        ACF.DebrisChance = math.Clamp(New,0,1)
    elseif( CVar == "acf_explosions_scaled_he_max" ) then
        ACF.ScaledHEMax = math.max(New,50)
    elseif( CVar == "acf_explosions_scaled_ents_max" ) then
        ACF.ScaledEntsMax = math.max(New,1)
    elseif( CVar == "acf_enable_dp" ) then
        if ACE_SendDPStatus then
            ACE_SendDPStatus()
        end
    end
end

--cvars.AddChangeCallback("acf_year", ACF_CVarChangeCallback)
cvars.AddChangeCallback("acf_healthmod", ACF_CVarChangeCallback)
cvars.AddChangeCallback("acf_armormod", ACF_CVarChangeCallback)
cvars.AddChangeCallback("acf_ammomod", ACF_CVarChangeCallback)
cvars.AddChangeCallback("acf_spalling", ACF_CVarChangeCallback)
cvars.AddChangeCallback("acf_spalling_multipler", ACF_CVarChangeCallback)
cvars.AddChangeCallback("acf_gunfire", ACF_CVarChangeCallback)
cvars.AddChangeCallback("acf_debris_lifetime", ACF_CVarChangeCallback)
cvars.AddChangeCallback("acf_debris_children", ACF_CVarChangeCallback)
cvars.AddChangeCallback("acf_explosions_scaled_he_max", ACF_CVarChangeCallback)
cvars.AddChangeCallback("acf_explosions_scaled_ents_max", ACF_CVarChangeCallback)
cvars.AddChangeCallback("acf_enable_dp", ACF_CVarChangeCallback)

if SERVER then

    function ACE_SendDPStatus()

        local Cvar = GetConVar("acf_enable_dp"):GetInt()
        local bool = tobool(Cvar)

        net.Start("ACE_DPStatus")
            net.WriteBool(bool)
        net.Broadcast()

    end

    function ACF_SendNotify( ply, success, msg )
        net.Start( "ACF_Notify" )
        net.WriteBit( success )
        net.WriteString( msg or "" )
        net.Send( ply )
    end
else

    local function ACF_Notify()
        local Type = NOTIFY_ERROR
        if tobool( net.ReadBit() ) then Type = NOTIFY_GENERIC end
        
        GAMEMODE:AddNotify( net.ReadString(), Type, 7 )
    end
    net.Receive( "ACF_Notify", ACF_Notify )
end

do

    local function OnInitialSpawn( ply )
        local Table = {}
        for k,v in pairs( ents.GetAll() ) do
            if v.ACF and v.ACF.PrHealth then
                table.insert(Table,{ID = v:EntIndex(), Health = v.ACF.Health, v.ACF.MaxHealth})
            end
        end
        if Table ~= {} then
            net.Start("ACF_RenderDamage")
                net.WriteTable(Table)
            net.Send(ply)
        end
    end
    hook.Add( "PlayerInitialSpawn", "renderdamage", OnInitialSpawn )

end

cleanup.Register( "aceexplosives" )

AddCSLuaFile("autorun/acf_missile/folder.lua")
include("autorun/acf_missile/folder.lua")

print('[ACE | INFO]- Done!')