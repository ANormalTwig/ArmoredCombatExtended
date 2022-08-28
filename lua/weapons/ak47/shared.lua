AddCSLuaFile("shared.lua")
SWEP.Base = "ace_basewep"

if (CLIENT) then
SWEP.PrintName		= "AK-47"
SWEP.Slot		    = 2
SWEP.SlotPos		= 1			
end

SWEP.Spawnable		= true	

--Visual
SWEP.ViewModelFlip 	= true
SWEP.ViewModel		= "models/weapons/v_rif_ak47.mdl"	
SWEP.WorldModel		= "models/weapons/w_rif_ak47.mdl"	
SWEP.ReloadSound	= "Weapon_Pistol.Reload"	
SWEP.HoldType		= "ar2"		
SWEP.CSMuzzleFlashes	= true


-- Other settings
SWEP.Weight			= 10						
SWEP.ZoomAccuracyImprovement = 0.65 -- 0.3 means 0.7 the inaccuracy
SWEP.ZoomRecoilImprovement = 0.65 -- 0.3 means 0.7 the recoil movement 
SWEP.CrouchAccuracyImprovement = 0.4 -- 0.3 means 0.7 the inaccuracy
SWEP.CrouchRecoilImprovement = 0.7 -- 0.3 means 0.7 the recoil movement
-- Weapon info		
SWEP.Purpose		= "Slavic bullet thrower"	
SWEP.Instructions	= "Left mouse to shoot"		

-- Primary fire settings
SWEP.Primary.Sound			= "Weapon_AK47.Single"	
SWEP.Primary.NumShots		= 1	
SWEP.Primary.Recoil			= 0.5	
SWEP.Primary.RecoilAngleVer	= 0.2	
SWEP.Primary.RecoilAngleHor	= 0.12		
SWEP.Primary.Cone			= 0.01		
SWEP.Primary.Delay			= 0.10
SWEP.Primary.ClipSize		= 30		
SWEP.Primary.DefaultClip	= 30			
SWEP.Primary.Force			= 1	
SWEP.Primary.Automatic		= 1	
SWEP.Primary.Ammo		= "AR2"	

SWEP.Secondary.Ammo		= "none"	
SWEP.Secondary.ClipSize		= -1		
SWEP.Secondary.DefaultClip	= -1

SWEP.ReloadSoundEnabled = 1

SWEP.Category 			= "ACE Sweps - AR"

SWEP.AimOffset = Vector(0,0,0)
SWEP.InaccuracyAccumulation = 0
SWEP.lastFire=CurTime()

SWEP.MaxInaccuracyMult = 5
SWEP.InaccuracyAccumulationRate = 0.3
SWEP.InaccuracyDecayRate = 1
SWEP.CarrySpeedMul = 0.9 --WalkSpeedMult when carrying the weapon

SWEP.IronSights = true
SWEP.IronSightsPos = Vector(-2, -15, 2.98)
SWEP.ZoomPos = Vector(2,-2,2)
SWEP.IronSightsAng = Angle(0.45, 0, 0)
--

function SWEP:InitBulletData()
	
	self.BulletData = {}

		self.BulletData.Id = "7.62mmMG"
		self.BulletData.Type = "AP"
		self.BulletData.Id = 1
		self.BulletData.Caliber = 0.762
		self.BulletData.PropLength = 4.7 --Volume of the case as a cylinder * Powder density converted from g to kg		
		self.BulletData.ProjLength = 3.75 --Volume of the projectile as a cylinder * streamline factor (Data5) * density of steel
		self.BulletData.Data5 = 0  --He Filler or Flechette count
		self.BulletData.Data6 = 0 --HEAT ConeAng or Flechette Spread
		self.BulletData.Data7 = 0
		self.BulletData.Data8 = 0
		self.BulletData.Data9 = 0
		self.BulletData.Data10 = 1 -- Tracer
		self.BulletData.Colour = Color(0, 255, 0)
		--
		self.BulletData.Data13 = 0 --THEAT ConeAng2
		self.BulletData.Data14 = 0 --THEAT HE Allocation
		self.BulletData.Data15 = 0
	
		self.BulletData.AmmoType  = self.BulletData.Type
		self.BulletData.FrAera    = 3.1416 * (self.BulletData.Caliber/2)^2
		self.BulletData.ProjMass  = self.BulletData.FrAera * (self.BulletData.ProjLength*7.9/1000)
		self.BulletData.PropMass  = self.BulletData.FrAera * (self.BulletData.PropLength*ACF.PDensity/1000) --Volume of the case as a cylinder * Powder density converted from g to kg
--		self.BulletData.DragCoef  = 0 --Alternatively manually set it
		self.BulletData.DragCoef  = ((self.BulletData.FrAera/10000)/self.BulletData.ProjMass)	

		--Don't touch below here
		self.BulletData.MuzzleVel = ACF_MuzzleVelocity( self.BulletData.PropMass, self.BulletData.ProjMass, self.BulletData.Caliber )		
		self.BulletData.ShovePower = 0.2
		self.BulletData.KETransfert = 0.3
		self.BulletData.PenAera = self.BulletData.FrAera^ACF.PenAreaMod*1.3
		self.BulletData.Pos = Vector(0 , 0 , 0)
		self.BulletData.LimitVel = 800	
		self.BulletData.Ricochet = 60
		self.BulletData.Flight = Vector(0 , 0 , 0)
		self.BulletData.BoomPower = self.BulletData.PropMass
		
		--For Fake Crate
		self.Type = self.BulletData.Type
		self.BulletData.Tracer = self.BulletData.Data10
		self.Tracer = self.BulletData.Tracer
		self.Caliber = self.BulletData.Caliber
		self.ProjMass = self.BulletData.ProjMass
		self.FillerMass = self.BulletData.Data5
		self.DragCoef = self.BulletData.DragCoef
		self.Colour = self.BulletData.Colour
		
end	
		
function SWEP:PrimaryAttack()	

	--Put this if you want sounds + lights working on client realm.....
	--if ( game.SinglePlayer() ) then self:CallOnClient( "PrimaryAttack" ) end

	if ( !self:CanPrimaryAttack() ) then return end		
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )	
	self.Weapon:EmitSound(Sound(self.Primary.Sound), 100, 100, 1, CHAN_WEAPON )	


	--Add this to your weapon. Easy to edit. reminder: 
	-- ACF_RenderLight(entity index, lightSize, colour, pos)
	-- ACE_SGunFire( SWEP entity, Sound , PropMass )
	
    if CLIENT then 
        --ACE_SGunFire( self, self.Primary.Sound, self.BulletData.PropMass ) -- cool
        --ACF_RenderLight(self:EntIndex(), 1000, Color(255, 128, 48), self:GetPos())
        return 
    end 
	
	self.BulletData.Owner = self.Owner
	self.BulletData.Gun = self	
	self.InaccuracyAccumulation = math.Clamp(self.InaccuracyAccumulation + self.InaccuracyAccumulationRate - self.InaccuracyDecayRate*(CurTime()-self.lastFire),1,self.MaxInaccuracyMult)
	
	if ( self.Owner:IsPlayer() ) then
		self.Owner:LagCompensation( true )
	end

	self:ACEFireBullet()
	
	if ( self.Owner:IsPlayer() ) then
		self.Owner:LagCompensation( false )
	end
	
	self.lastFire=CurTime()
--	print("Inaccuracy: "..self.InaccuracyAccumulation)
	
	
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )							
	self.Owner:SetAnimation( PLAYER_ATTACK1 )			
	self.Owner:ViewPunch(Angle( -self.Primary.Recoil + math.Rand(-self.Primary.RecoilAngleVer,self.Primary.RecoilAngleVer), math.Rand(-self.Primary.RecoilAngleHor,self.Primary.RecoilAngleHor), 0 )*(1+self.InaccuracyAccumulation))	
	if (self.Primary.TakeAmmoPerBullet) then			
		self:TakePrimaryAmmo(self.Primary.NumShots)
	else
		self:TakePrimaryAmmo(1)
	end
end

function SWEP:Reload()	

	if self:Clip1() < self.Primary.ClipSize and self:Ammo1() > 0 and self.ReloadSoundEnabled == 1 then
	self.Weapon:EmitSound(Sound(self.ReloadSound))
	end
	self:DefaultReload(ACT_VM_RELOAD)
	
--player.GetByID( 1 ):GiveAmmo( 30-self:Clip1(), "AR2", true )
	self:Think()
	return true
end



