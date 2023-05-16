local lRagdoll = nil;
local lRagdollInt = nil;
local lPlayerInt = nil;

net.Receive("death_client",function()
	lRagdollInt = net.ReadInt(32);
	lPlayerInt = net.ReadInt(32);
end)

hook.Add("CalcView","RagDeath_Cam",function(ply, pos, angles, fov)
	if LocalPlayer():Alive() then 
		return;
	end
	if not IsValid(lRagdoll) then 
		return;
	end
	local rd = util.TraceLine({start=lRagdoll:GetPos(),endpos=lRagdoll:GetPos()-angles:Forward()*105,filter={lRagdoll,LocalPlayer()}})
	return {origin=lRagdoll:GetPos()-angles:Forward()*(100*rd.Fraction),angles=angles,fov=fov,znear=0.5} 
end)

hook.Add("NetworkEntityCreated","RagDeath_Setup",function(ent)
	if not lRagdollInt then 
		return;
	end
	if lRagdollInt==ent:EntIndex() then
		if lPlayerInt==LocalPlayer():EntIndex() then 
			lRagdoll=ent
		end
	end
end)if CLIENT then return end

AddCSLuaFile("gPhoria_cl_init.lua")
util.AddNetworkString("death_client")

local conAffectNpc = CreateConVar("gphoria_affect_npc","1", FCVAR_ARCHIVE,"");
local conAffectPlayer = CreateConVar("gphoria_affect_player","1", FCVAR_ARCHIVE,"");
local conAmtTimeMin = CreateConVar("gphoria_min_time","20", FCVAR_ARCHIVE,"");
local conAmtTimeMax = CreateConVar("gphoria_max_time","30", FCVAR_ARCHIVE,"");

function initJoin( ply )
	ply:PrintMessage( HUD_PRINTTALK, "This server uses 'gPhoria' v1.1 made by Savva." );
end
hook.Add( "PlayerInitialSpawn", "First_Spawn", initJoin);

local pTable={""};
local ragTable={""};

function playerJoin( ply )
		if IsValid(ply) then
			if (table.HasValue(pTable,ply)) then
				if IsValid(ply) then
					local loc = table.KeyFromValue(pTable,ply);
					local lRagdoll = table.remove(ragTable, loc);
					if IsValid(lRagdoll) then 
						lRagdoll:Remove(); 
					end
					table.remove(pTable, loc);
				end
			end
		end
end
hook.Add( "PlayerSpawn", "ReSpawn", playerJoin );
hook.Add( "PlayerDisconnected", "DisConnect", playerJoin );

function death( ent )
	if IsValid( ent ) then
		if ( ent:GetClass() == "prop_ragdoll" && conAffectNpc:GetBool()) then

				local timerCount = 0.016;
				local amtTime = math.random(conAmtTimeMin:GetInt(),conAmtTimeMax:GetInt());
				local startForce = math.random(11,13);
				if(ent:GetPhysicsObjectCount()>0) then
					local x = ent:GetPhysicsObjectNum( 0 ):GetVelocity().x;
					local y = ent:GetPhysicsObjectNum( 0 ):GetVelocity().y;
					local z = ent:GetPhysicsObjectNum( 0 ):GetVelocity().z;
					local normal = math.sqrt(x*x +y*y+z*z);
					startForce = startForce * normal;
					if( startForce > 400 ) then
						startForce=130;
					end
					if( startForce > 300 ) then
						startForce=startForce/2.4;
					end
					if( startForce > 200 ) then
						startForce=startForce/1.6;
					end
					if( startForce > 150 ) then
						startForce=startForce/1.1;
					end
					startForce = startForce/1.4;
					amtTime = amtTime * (normal/0.9);
					if(amtTime>280) then
						amtTime = math.random(200,280);
					end
					local forceAmount = startForce ;
					for j=0, amtTime, 1 do
						timer.Simple(timerCount, function ()
							if(IsValid(ent)) then
								local numBones = ent:GetPhysicsObjectCount();
								for i = 1, numBones - 1 do
									if(IsValid(ent)) then
										local bone = ent:GetBoneName( i );
										if(IsValid(ent)) then
											local physBone = ent:GetPhysicsObjectNum( i );
											if IsValid( physBone ) then
												if( string.find(bone:lower(),"pelvis") == nil && string.find(bone:lower(),"spine") == nil && string.find(bone:lower(),"forward") == nil && string.find(bone:lower(),"neck") == nil  && string.find(bone:lower(),"head") == nil && string.find(bone:lower(),"attach") == nil && string.find(bone:lower(),"anim") == nil) then
													if IsValid(ent) then
														local physBonePos, physBoneAng = ent:GetBonePosition( ent:TranslatePhysBoneToBone( i ));
														physBone:SetVelocity(physBone:GetVelocity()+Vector(math.random(-forceAmount,forceAmount),math.random(-forceAmount,forceAmount),math.random(-forceAmount,forceAmount))) ;
													end
												end
											end
										end
										if not (IsValid(ent)) then
											j = amtTime;
										end
									end
									if not (IsValid(ent)) then
										j = amtTime;
									end
								end
								forceAmount = forceAmount - (startForce/(amtTime));
							end
							if not (IsValid(ent)) then
								j = amtTime;
							end
						end )
						timerCount = timerCount + 0.016;
						
					end
				end
			end

	end
end
hook.Add ("OnEntityCreated", "CCRagdoll", death);


function playerDies( ent, wep, attacker )
	if IsValid(ent) then
		local lEnt = ent:GetRagdollEntity();
		if ( lEnt && lEnt:IsValid() && conAffectPlayer:GetBool()) then 
			lEnt:Remove();
			
			local lRagdoll = ents.Create( "prop_ragdoll" );
			lRagdoll:SetModel(ent:GetModel());
			lRagdoll:SetPos(ent:GetPos());
		
			for k,v in pairs(ent:GetBodyGroups()) do
				lRagdoll:SetBodygroup(v.id,ent:GetBodygroup(v.id))
			end
		
			lRagdoll:Spawn();
			lRagdoll:SetCollisionGroup(0);
			lRagdoll.RagColor = Vector(ent:GetPlayerColor().r, ent:GetPlayerColor().g, ent:GetPlayerColor().b);
			
			local lVel = ent:GetVelocity();
		
			for i = 0, lRagdoll:GetPhysicsObjectCount()-1 do
				local physBoneT = lRagdoll:GetPhysicsObjectNum( i );
				if ( physBoneT:IsValid() ) then
					local lPos, lAng = ent:GetBonePosition( lRagdoll:TranslatePhysBoneToBone( i ) );
					physBoneT:SetPos( lPos );
					physBoneT:SetAngles( lAng );
					physBoneT:AddVelocity( lVel );
				end
			end
			table.insert(pTable,ent);
			table.insert(ragTable,lRagdoll);
			net.Start("death_client");
				net.WriteInt(lRagdoll:EntIndex(),32);
				net.WriteInt(ent:EntIndex(),32);
			net.Send(player.GetAll());
			
			local timerCount = 0.016;
			local amtTime = math.random(conAmtTimeMin:GetInt(),conAmtTimeMax:GetInt());
			local startForce = math.random(11,13);
			if ( lRagdoll:GetPhysicsObjectCount()>0 ) then
				local x = lRagdoll:GetPhysicsObjectNum( 0 ):GetVelocity().x;
				local y = lRagdoll:GetPhysicsObjectNum( 0 ):GetVelocity().y;
				local z = lRagdoll:GetPhysicsObjectNum( 0 ):GetVelocity().z;
				local normal = math.sqrt(x*x +y*y+z*z);
				startForce = startForce * normal;
				if( startForce > 400 ) then
					startForce=170;
				end
				if( startForce > 300 ) then
					startForce=startForce/2;
				end
				if( startForce > 200 ) then
					startForce=startForce/1.4;
				end
				if( startForce > 150 ) then
					startForce=startForce/1.1;
				end
				startForce = startForce/1.4;
				amtTime = amtTime * (normal/0.9);
				if(amtTime>280) then
					amtTime = math.random(200,280);
				end
				local forceAmount = startForce;
				for j=0, amtTime, 1 do
					timer.Simple(timerCount, function ()
						if(IsValid(lRagdoll)) then
							local numBones = lRagdoll:GetPhysicsObjectCount();
							for i = 1, numBones - 1 do
								if(IsValid(lRagdoll)) then
									local bone = lRagdoll:GetBoneName( i );
									if(IsValid(lRagdoll)) then
										local physBone = lRagdoll:GetPhysicsObjectNum( i );
										if IsValid( physBone ) then
											if( string.find(bone:lower(),"pelvis") == nil && string.find(bone:lower(),"spine") == nil && string.find(bone:lower(),"forward") == nil && string.find(bone:lower(),"neck") == nil  && string.find(bone:lower(),"head") == nil && string.find(bone:lower(),"attach") == nil && string.find(bone:lower(),"anim") == nil) then
												local physBonePos, physBoneAng = lRagdoll:GetBonePosition( lRagdoll:TranslatePhysBoneToBone( i ));
												physBone:SetVelocity(physBone:GetVelocity()+Vector(math.random(-forceAmount,forceAmount),math.random(-forceAmount,forceAmount),math.random(-forceAmount,forceAmount))) ;
											end
										end
									end
									if not (IsValid(lRagdoll)) then
										j = amtTime;
									end
								end
								if not (IsValid(lRagdoll)) then
									j = amtTime;
								end
							end
							forceAmount = forceAmount - (startForce/(amtTime));
						end
						if not (IsValid(lRagdoll)) then
							j = amtTime;
						end
					end )
					timerCount = timerCount + 0.016;
					
				end
			end
		end
	end
end
hook.Add( "PlayerDeath", "playerDeathTest", playerDies);¬cZT