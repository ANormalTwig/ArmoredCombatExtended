
AddCSLuaFile()

--put all guns that this ammo should NOT fit
ACF.AmmoBlacklist.AP =  { "MO", "RM", "SL", "GL", "BOMB" , "GBU", "ASM", "AAM", "SAM", "UAR", "POD", "FFAR", "ATGM", "ARTY", "ECM", "FGL","SBC"}

local Round = {}

Round.type  = "Ammo"                                    -- Tells the spawn menu what entity to spawn
Round.name  = "[AP] - "..ACFTranslation.ShellAP[1]      -- Human readable name
Round.model = "models/munitions/round_100mm_shot.mdl"   -- Shell flight model
Round.desc  = ACFTranslation.ShellAP[2]                 -- Ammo description
Round.netid = 1                                         -- Unique ID for this ammo

Round.Type  = "AP"

function Round.create( Gun, BulletData )
    
    ACF_CreateBullet( BulletData )
    
end

-- Function to convert the player's slider data into the complete round data
function Round.convert( Crate, PlayerData )
    
    local Data          = {}
    local ServerData    = {}
    local GUIData       = {}
    
    PlayerData.PropLength   =  PlayerData.PropLength    or 0
    PlayerData.ProjLength   =  PlayerData.ProjLength    or 0 
    PlayerData.Data10       =  PlayerData.Data10        or 0

    PlayerData, Data, ServerData, GUIData = ACF_RoundBaseGunpowder( PlayerData, Data, ServerData, GUIData )
    
    Data.ProjMass       = Data.FrArea * (Data.ProjLength*7.9/1000)  -- Volume of the projectile as a cylinder * density of steel
    Data.ShovePower     = 0.2
    Data.PenArea        = Data.FrArea^ACF.PenAreaMod
    Data.DragCoef       = ((Data.FrArea/10000)/Data.ProjMass)*1.2
    Data.LimitVel       = 750                                       -- Most efficient penetration speed in m/s
    Data.KETransfert    = 0.3                                       -- Kinetic energy transfert to the target for movement purposes
    Data.Ricochet       = 53                                        -- Base ricochet angle
    Data.MuzzleVel      = ACF_MuzzleVelocity( Data.PropMass, Data.ProjMass, Data.Caliber )
    Data.BoomPower      = Data.PropMass

    if SERVER then --Only the crates need this part
        ServerData.Id       = PlayerData.Id
        ServerData.Type     = PlayerData.Type
        return table.Merge(Data,ServerData)
    end
    
    if CLIENT then --Only tthe GUI needs this part
        GUIData = table.Merge(GUIData, Round.getDisplayData(Data))
        return table.Merge(Data,GUIData)
    end
    
end

function Round.getDisplayData(Data)
    local GUIData = {}
    local Energy    = ACF_Kinetic( Data.MuzzleVel*39.37 , Data.ProjMass, Data.LimitVel )
    GUIData.MaxPen  = (Energy.Penetration/Data.PenArea)*ACF.KEtoRHA
    return GUIData
end

function Round.network( Crate, BulletData )
    
    Crate:SetNWString( "AmmoType", Round.Type )
    Crate:SetNWString( "AmmoID", BulletData.Id )
    Crate:SetNWFloat( "Caliber", BulletData.Caliber )
    Crate:SetNWFloat( "ProjMass", BulletData.ProjMass )
    Crate:SetNWFloat( "PropMass", BulletData.PropMass )
    Crate:SetNWFloat( "DragCoef", BulletData.DragCoef )
    Crate:SetNWFloat( "MuzzleVel", BulletData.MuzzleVel )
    Crate:SetNWFloat( "Tracer", BulletData.Tracer )

    -- For propper bullet model
    Crate:SetNWFloat( "BulletModel", Round.model )
    
end

function Round.cratetxt( BulletData )
    
    local DData = Round.getDisplayData(BulletData)
    
    local str = 
    {
        "Muzzle Velocity: ", math.floor(BulletData.MuzzleVel, 1), " m/s\n",
        "Max Penetration: ", math.floor(DData.MaxPen), " mm"
    }
    
    return table.concat(str)
    
end

function Round.propimpact( Index, Bullet, Target, HitNormal, HitPos, Bone )

    if ACF_Check( Target ) then
    
        local Speed     = Bullet.Flight:Length() / ACF.VelScale
        local Energy    = ACF_Kinetic( Speed , Bullet.ProjMass, Bullet.LimitVel )
        local HitRes    = ACF_RoundImpact( Bullet, Speed, Energy, Target, HitPos, HitNormal , Bone )
        
        if HitRes.Overkill > 0 then

            table.insert( Bullet.Filter , Target )                  --"Penetrate" (Ingoring the prop for the retry trace)

            ACF_Spall( HitPos , Bullet.Flight , Bullet.Filter , Energy.Kinetic*HitRes.Loss , Bullet.Caliber , Target.ACF.Armour , Bullet.Owner , Target.ACF.Material) --Do some spalling
            Bullet.Flight = Bullet.Flight:GetNormalized() * (Energy.Kinetic*(1-HitRes.Loss)*2000/Bullet.ProjMass)^0.5 * 39.37

            return "Penetrated"
        elseif HitRes.Ricochet then

            return "Ricochet"
        else
            return false
        end
    else 
        table.insert( Bullet.Filter , Target )
        return "Penetrated" 
    end
        
end

function Round.worldimpact( Index, Bullet, HitPos, HitNormal )
    
    local Energy = ACF_Kinetic( Bullet.Flight:Length() / ACF.VelScale, Bullet.ProjMass, Bullet.LimitVel )
    local HitRes = ACF_PenetrateGround( Bullet, Energy, HitPos, HitNormal )

    if HitRes.Penetrated then

        return "Penetrated"
    elseif HitRes.Ricochet then

        return "Ricochet"
    else
        return false
    end

end

function Round.endflight( Index, Bullet, HitPos )
    
    ACF_RemoveBullet( Index )
    
end

-- Bullet stops here
function Round.endeffect( Effect, Bullet )
    
    local Spall = EffectData()
        Spall:SetEntity( Bullet.Crate )
        Spall:SetOrigin( Bullet.SimPos )
        Spall:SetNormal( (Bullet.SimFlight):GetNormalized() )
        Spall:SetScale( Bullet.SimFlight:Length() )
        Spall:SetMagnitude( Bullet.RoundMass )
    util.Effect( "acf_ap_impact", Spall )

end

-- Bullet penetrated something
function Round.pierceeffect( Effect, Bullet )

    local Spall = EffectData()
        Spall:SetEntity( Bullet.Crate )
        Spall:SetOrigin( Bullet.SimPos )
        Spall:SetNormal( (Bullet.SimFlight):GetNormalized() )
        Spall:SetScale( Bullet.SimFlight:Length() )
        Spall:SetMagnitude( Bullet.RoundMass )
    util.Effect( "acf_ap_penetration", Spall )

end

-- Bullet ricocheted off something
function Round.ricocheteffect( Effect, Bullet )

    local Spall = EffectData()
        Spall:SetEntity( Bullet.Crate )
        Spall:SetOrigin( Bullet.SimPos )
        Spall:SetNormal( (Bullet.SimFlight):GetNormalized() )
        Spall:SetScale( Bullet.SimFlight:Length() )
        Spall:SetMagnitude( Bullet.RoundMass )
    util.Effect( "acf_ap_ricochet", Spall )
    
end

function Round.guicreate( Panel, Table )

    acfmenupanel:AmmoSelect( ACF.AmmoBlacklist.AP )

    acfmenupanel:CPanelText("BonusDisplay", "")
    acfmenupanel:CPanelText("Desc", "")                                         --Description (Name, Desc)
    acfmenupanel:AmmoStats(0,0,0,0)                                             --AmmoStats -->> RoundLenght, MuzzleVelocity & MaxPen
    acfmenupanel:AmmoSlider("PropLength",0,0,1000,3, "Propellant Length", "")   --Propellant Length Slider (Name, Value, Min, Max, Decimals, Title, Desc)
    acfmenupanel:AmmoSlider("ProjLength",0,0,1000,3, "Projectile Length", "")   --Projectile Length Slider (Name, Value, Min, Max, Decimals, Title, Desc)
    acfmenupanel:AmmoCheckbox("Tracer", "Tracer", "")                           --Tracer checkbox (Name, Title, Desc)
    acfmenupanel:CPanelText("RicoDisplay", "")                                  --estimated rico chance
    acfmenupanel:CPanelText("PenetrationDisplay", "")                           --Proj muzzle penetration (Name, Desc)
    
    Round.guiupdate( Panel, Table )

end

function Round.guiupdate( Panel, Table )
    
    local PlayerData = {}
        PlayerData.Id           = acfmenupanel.AmmoData.Data.id                     -- AmmoSelect GUI
        PlayerData.Type         = Round.Type                                              -- Hardcoded, match ACFRoundTypes table index
        PlayerData.PropLength   = acfmenupanel.AmmoData.PropLength                  -- PropLength slider
        PlayerData.ProjLength   = acfmenupanel.AmmoData.ProjLength                  -- ProjLength slider
        PlayerData.Data10       = acfmenupanel.AmmoData.Tracer and 1 or 0
    
    local Data = Round.convert( Panel, PlayerData )
    
    RunConsoleCommand( "acfmenu_data1", acfmenupanel.AmmoData.Data.id )
    RunConsoleCommand( "acfmenu_data2", PlayerData.Type )
    RunConsoleCommand( "acfmenu_data3", Data.PropLength )                           --For Gun ammo, Data3 should always be Propellant
    RunConsoleCommand( "acfmenu_data4", Data.ProjLength )                           --And Data4 total round mass
    RunConsoleCommand( "acfmenu_data10", Data.Tracer )
    
    ---------------------------Ammo Capacity---------------------------------------
    
    ACE_AmmoCapacityDisplay( Data )
    
    -------------------------------------------------------------------------------
    
    acfmenupanel:CPanelText("Desc", ACF.RoundTypes[PlayerData.Type].desc)           --Description (Name, Desc)
    
    acfmenupanel:AmmoSlider("PropLength", Data.PropLength, Data.MinPropLength, Data.MaxTotalLength, 3, "Propellant Length", "Propellant Mass : "..(math.floor(Data.PropMass*1000)).." g" .. "/ ".. (math.Round(Data.PropMass, 1)) .." kg" )  --Propellant Length Slider (Name, Min, Max, Decimals, Title, Desc)
    acfmenupanel:AmmoSlider("ProjLength", Data.ProjLength, Data.MinProjLength, Data.MaxTotalLength, 3, "Projectile Length", "Projectile Mass : "..(math.floor(Data.ProjMass*1000)).." g" .. "/ ".. (math.Round(Data.ProjMass, 1)) .." kg")  --Projectile Length Slider (Name, Min, Max, Decimals, Title, Desc)

    acfmenupanel:AmmoCheckbox("Tracer", "Tracer : "..(math.floor(Data.Tracer*5)/10).."cm\n", "" )           --Tracer checkbox (Name, Title, Desc)
    
    acfmenupanel:AmmoStats((math.floor((Data.PropLength+Data.ProjLength+(math.floor(Data.Tracer*5)/10))*100)/100), (Data.MaxTotalLength) ,math.floor(Data.MuzzleVel*ACF.VelScale) ,math.floor(Data.MaxPen))
    
    local None, Mean, Max = ACF_RicoProbability( Data.Ricochet, Data.MuzzleVel*ACF.VelScale )
    acfmenupanel:CPanelText("RicoDisplay", '0% chance of ricochet at: '..None..'°\n50% chance of ricochet at: '..Mean..'°\n100% chance of ricochet at: '..Max..'°')

    ACE_AmmoRangeStats( Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel )

end

list.Set( "APRoundTypes", Round.Type , Round )
list.Set( "ACFRoundTypes", Round.Type, Round )        --Set the round properties
list.Set( "ACFIdRounds", Round.netid, Round.Type )    --Index must equal the ID entry in the table above, Data must equal the index of the table above

ACF.RoundTypes  = list.Get("ACFRoundTypes")
ACF.IdRounds    = list.Get("ACFIdRounds")