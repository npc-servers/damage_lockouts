
local IsValid = IsValid
util.AddNetworkString( "notifylockout" )

local tookDamageTime = 3
local didDamageTime = 3
local spawnPropTimeAfterRespawn = 3

local function sendNotify( ply, time, string )
    net.Start( "notifylockout" )
    net.WriteInt( math.ceil( time ), 8 )
    net.WriteString( string )
    net.Send( ply )
end

local function spawnedIn( ply )
    local lastSpawn = ply.LockoutSpawnTime
    if not lastSpawn then return end

    local time = lastSpawn + spawnPropTimeAfterRespawn - CurTime()

    if time > 0 then
        return time
    end
    ply.LockoutSpawnTime = nil
end

local function tookDamage( ply )
    local lastDmg = ply.LockoutTookDamage
    if not lastDmg then return end

    local time = lastDmg + tookDamageTime - CurTime()

    if time > 0 then
        return time
    end
    ply.LockoutTookDamage = nil
end

local function didDamage( ply )
    local lastDmg = ply.LockoutDidDamage
    if not lastDmg then return end

    local time = lastDmg + didDamageTime - CurTime()

    if time > 0 then
        return time
    end
    ply.LockoutDidDamage = nil
end

local function canSpawnProp( ply )
    local time = spawnedIn( ply )
    if time then
        sendNotify( ply, time, "You spawned in, you can spawn props in" )
        return false
    end

    local source = debug.getinfo( 5 )
    if source and source.short_src and string.find( source.short_src, "advdupe2" ) then return end

    time = tookDamage( ply )
    if time then
        sendNotify( ply, time, "You recently took damage you can spawn props in" )
        return false
    end

    time = didDamage( ply )
    if time then
        sendNotify( ply, time, "You recently did damage you can spawn props in" )
        return false
    end
end

hook.Add( "PlayerSpawnProp", "SpawnDelayAfterDamage", canSpawnProp )
hook.Add( "PlayerSpawnSENT", "SpawnDelayAfterDamage", canSpawnProp )
hook.Add( "PlayerSpawnVehicle", "SpawnDelayAfterDamage", canSpawnProp )

local function onDamage( ent, dmg )
    if not IsValid( ent ) then return end
    if not ent:IsPlayer() then return end
    if dmg:GetDamage() == 0 then return end

    local attacker = dmg:GetAttacker()
    if attacker:IsWorld() or attacker:IsNPC() then return end
    if attacker == ent then return end

    ent.LockoutTookDamage = CurTime()

    if attacker:IsPlayer() then
        attacker.LockoutDidDamage = CurTime()
    end
end

hook.Add( "PostEntityTakeDamage", "SpawnDelayAfterDamage", onDamage )

local function onSpawningIn( ply )
    ply.LockoutSpawnTime = CurTime()
end

hook.Add( "PlayerSpawn", "SpawnDelayAfterSpawningIn", onSpawningIn )
