
local cat = ((ACF.CustomToolCategory and ACF.CustomToolCategory:GetBool()) and "ACF" or "Construction");

TOOL.Category		= cat
TOOL.Name			= "#Tool.acfsound.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar["pitch"] = "1"
if CLIENT then
	language.Add( "Tool.acfsound.name", ACFTranslation.SoundToolText[1] )
	language.Add( "Tool.acfsound.desc", ACFTranslation.SoundToolText[2] )
	language.Add( "Tool.acfsound.0", ACFTranslation.SoundToolText[3] )
end

ACF.SoundToolSupport = {
	acf_gun = {
		GetSound = function(ent) return {Sound = ent.Sound} end,
		
		SetSound = function(ent, soundData) 
			ent.Sound = soundData.Sound
			ent:SetNWString( "Sound", soundData.Sound )
		end,
		
		ResetSound = function(ent)
			local Class = ent.Class
			local Classes = list.Get("ACFClasses")
			
			local List = list.Get("ACFEnts")
			local lookup = List.Guns[ent.Id]

			local sound = lookup.sound or Classes["GunClass"][Class]["sound"]

			local soundData = {Sound = sound}
			
			local setSound = ACF.SoundToolSupport["acf_gun"].SetSound
			setSound( ent, soundData )
		end
	},
	
	acf_engine = {
		GetSound = function(ent) return {Sound = ent.SoundPath, Pitch = ent.SoundPitch} end,
		
		SetSound = function(ent, soundData) 
			ent.SoundPath = soundData.Sound
			ent.SoundPitch = soundData.Pitch
		end,
		
		ResetSound = function(ent)
			local Id = ent.Id
			local List = list.Get("ACFEnts")
			local pitch = List["Mobility"][Id]["pitch"] or 1
			
			local soundData = {Sound = List["Mobility"][Id]["sound"], Pitch = pitch}
			
			local setSound = ACF.SoundToolSupport["acf_engine"].SetSound
			setSound( ent, soundData )
		end
	},

	acf_rack = {
		GetSound = function(ent) return {Sound = ent.Sound} end,
		
		SetSound = function(ent, soundData) 
			ent.Sound = soundData.Sound
			ent:SetNWString( "Sound", soundData.Sound )
		end,
		
		ResetSound = function(ent)
			local Class = ent.Class
			local Classes = list.Get("ACFClasses")
			
			local soundData = {Sound = Classes["GunClass"][Class]["sound"]}
			
			local setSound = ACF.SoundToolSupport["acf_gun"].SetSound
			setSound( ent, soundData )
		end
	},
	
	acf_missileradar = {
		GetSound = function(ent) return {Sound = ent.Sound} end,
		
		SetSound = function(ent, soundData) 
			ent.Sound = soundData.Sound
			ent:SetNWString( "Sound", soundData.Sound )
		end,
		
		ResetSound = function(ent)
			local soundData = {Sound = ACFM.DefaultRadarSound}
			
			local setSound = ACF.SoundToolSupport["acf_gun"].SetSound
			setSound( ent, soundData )
		end
	} 
}

local function ReplaceSound( ply , Entity , data)
	if !IsValid( Entity ) then return end
	local sound = data[1]
	local pitch = data[2] or 1
	
	timer.Simple(1, function()
		if not IsValid( Entity ) then return end --Caused by insta removal of the dupe
		local class = Entity:GetClass()
		
		local support = ACF.SoundToolSupport[class]
		if not support then return end
	
		support.SetSound(Entity, {Sound = sound, Pitch = pitch})
	end)
			
	duplicator.StoreEntityModifier( Entity, "acf_replacesound", {sound, pitch} )
end

duplicator.RegisterEntityModifier( "acf_replacesound", ReplaceSound )


local function IsReallyValid(trace, ply)

	local isValid = true
	
	if not trace.Entity:IsValid() then return false end
	if trace.Entity:IsPlayer() then return false end
	if SERVER and not trace.Entity:GetPhysicsObject():IsValid() then return false end
	
	
	local class = trace.Entity:GetClass()
	if not ACF.SoundToolSupport[class] then 
	
		if string.StartWith(class, "acf_") then
			ACF_SendNotify( ply, false, class .. ACFTranslation.SoundToolText[4] )
		else
			ACF_SendNotify( ply, false, ACFTranslation.SoundToolText[5] )
		end
		
		return false
	end
	
	return true
	
end

function TOOL:LeftClick( trace )
	if CLIENT then return true end
	if not IsReallyValid( trace, self:GetOwner() ) then return false end
	
	local sound = self:GetOwner():GetInfo("wire_soundemitter_sound")
	local pitch = self:GetOwner():GetInfo("acfsound_pitch")
	ReplaceSound( self:GetOwner(), trace.Entity, {sound, pitch} )
	return true
end

function TOOL:RightClick( trace )
	if CLIENT then return true end
	if not IsReallyValid( trace, self:GetOwner() ) then return false end
	
	local class = trace.Entity:GetClass()
	local support = ACF.SoundToolSupport[class]
	if not support then return false end
	
	local soundData = support.GetSound(trace.Entity)
	
	self:GetOwner():ConCommand("wire_soundemitter_sound "..soundData.Sound);
	
	if soundData.Pitch then
		self:GetOwner():ConCommand("acfsound_pitch "..soundData.Pitch);
	end
	
	return true
end

function TOOL:Reload( trace )
	if CLIENT then return true end
	if not IsReallyValid( trace, self:GetOwner() ) then return false end
	
	local class = trace.Entity:GetClass()
	local support = ACF.SoundToolSupport[class]
	if not support then return false end
	
	support.ResetSound(trace.Entity)
	
	return true
end

function TOOL.BuildCPanel(panel)
	local wide = panel:GetWide()

	local SoundNameText = vgui.Create("DTextEntry", ValuePanel)
	SoundNameText:SetText("")
	SoundNameText:SetWide(wide)
	SoundNameText:SetTall(20)
	SoundNameText:SetMultiline(false)
	SoundNameText:SetConVar("wire_soundemitter_sound")
	SoundNameText:SetVisible(true)
	panel:AddItem(SoundNameText)

	local SoundBrowserButton = vgui.Create("DButton")
	SoundBrowserButton:SetText("Open Sound Browser")
	SoundBrowserButton:SetWide(wide)
	SoundBrowserButton:SetTall(20)
	SoundBrowserButton:SetVisible(true)
	SoundBrowserButton.DoClick = function()
		RunConsoleCommand("wire_sound_browser_open",SoundNameText:GetValue())
	end
	panel:AddItem(SoundBrowserButton)

	local SoundPre = vgui.Create("DPanel")
	SoundPre:SetWide(wide)
	SoundPre:SetTall(20)
	SoundPre:SetVisible(true)

	local SoundPreWide = SoundPre:GetWide()

	local SoundPrePlay = vgui.Create("DButton", SoundPre)
	SoundPrePlay:SetText("Play")
	SoundPrePlay:SetWide(SoundPreWide / 2)
	SoundPrePlay:SetPos(0, 0)
	SoundPrePlay:SetTall(20)
	SoundPrePlay:SetVisible(true)
	SoundPrePlay.DoClick = function()
		RunConsoleCommand("play",SoundNameText:GetValue())
	end

	local SoundPreStop = vgui.Create("DButton", SoundPre)
	SoundPreStop:SetText("Stop")
	SoundPreStop:SetWide(SoundPreWide / 2)
	SoundPreStop:SetPos(SoundPreWide / 2, 0)
	SoundPreStop:SetTall(20)
	SoundPreStop:SetVisible(true)
	SoundPreStop.DoClick = function()
		RunConsoleCommand("play", "common/NULL.WAV") //Playing a silent sound will mute the preview but not the sound emitters.
	end
	panel:AddItem(SoundPre)
	SoundPre:InvalidateLayout(true)
	SoundPre.PerformLayout = function()
		local SoundPreWide = SoundPre:GetWide()
		SoundPrePlay:SetWide(SoundPreWide / 2)
		SoundPreStop:SetWide(SoundPreWide / 2)
		SoundPreStop:SetPos(SoundPreWide / 2, 0)
	end
	
	panel:AddControl("Slider", {
        Label = "Pitch:",
        Command = "acfsound_pitch",
        Type = "Float",
        Min = "0.1",
        Max = "2",
    }):SetTooltip("Works only for engines.")
	/*
	local SoundPitch = vgui.Create("DNumSlider")
	SoundPitch:SetMin( 0.1 )
	SoundPitch:SetMax( 2 )
    SoundPitch:SetDecimals( 0.1 )
	SoundPitch:SetWide(wide)
	SoundPitch:SetText("Pitch:")
	SoundPitch:SetToolTip(ACFTranslation.SoundToolText[6])
	SoundPitch:SetConVar( "acfsound_pitch" )
	SoundPitch:SetValue( 1 )
	panel:AddItem(SoundPitch)
	*/
end
