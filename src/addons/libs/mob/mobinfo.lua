--[[
* Copyright (c) 2011-2014 - Ashita Development Team
*
* Ashita is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Ashita is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Ashita.  If not, see <http://www.gnu.org/licenses/>.
]]--

-- Eleven Pies: Modified from filterscan

require 'common'
require 'mob.mobparse'

-- Get the proper install folder..
local polVersion = AshitaCore:GetConfigurationManager():get_uint32("boot_config", "pol_version", 2);
if (polVersion == 4) then
    polVersion = 3;
end

---------------------------------------------------------------------------------------------------
-- desc: Mob Info Main Table
---------------------------------------------------------------------------------------------------
local MobInfo =
{
    FFXiPath    = ashita.file.get_install_dir(polVersion, 1) .. '\\',
    MobList     = { },
    ZoneDatList = require('mob.zonemoblist'),
    ZoneId      = 0
};

---------------------------------------------------------------------------------------------------
-- func: UpdateZoneMobList
-- desc: Updates the zone mob list.
---------------------------------------------------------------------------------------------------
local function UpdateZoneMobList(zoneId)
    MobInfo.ZoneId = zoneId;

    -- Attempt to get the dat file for this entry..
    local dat = MobInfo.ZoneDatList[zoneId];
    if (dat == nil) then
        MobInfo.MobList = { };
        return false;
    end

    -- Attempt to parse the dat file..
    MobInfo.MobList = ParseZoneMobDat(MobInfo.FFXiPath .. dat);
    return true;
end

---------------------------------------------------------------------------------------------------
-- func: MobInfoZoneId
-- desc: Returns the zone id.
---------------------------------------------------------------------------------------------------
function MobInfoZoneId()
    return MobInfo.ZoneId;
end

---------------------------------------------------------------------------------------------------
-- func: MobNameFromTargetId
-- desc: Returns the mob name from the given target id.
---------------------------------------------------------------------------------------------------
function MobNameFromTargetId(targId)
    if (MobInfo.MobList == nil) then
        return nil;
    end
    for _, v in pairs(MobInfo.MobList) do
        if (v[1] == targId) then
            return v[2];
        end
    end
    return nil;
end

---------------------------------------------------------------------------------------------------
-- func: __mobinfo_load
-- desc: First called when our addon is loaded.
---------------------------------------------------------------------------------------------------
function __mobinfo_load()
    -- Parse the players current zone if we are in-game..
    if (AshitaCore:GetDataManager():GetParty():GetMemberActive(0)) then
        local zoneId = AshitaCore:GetDataManager():GetParty():GetMemberZone(0);
        UpdateZoneMobList(zoneId);
    end
end

---------------------------------------------------------------------------------------------------
-- func: __mobinfo_incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
function __mobinfo_incoming_packet(id, size, packet)
    -- Check for zone-in packets..
    if (id == 0x0A) then
        -- Are we zoning into a mog house..
        if (struct.unpack('b', packet, 0x80 + 1) == 1) then
            return false;
        end

        -- Pull the zone id from the packet..
        local zoneId = struct.unpack('H', packet, 0x30 + 1);
        if (zoneId == 0) then
            zoneId = struct.unpack('H', packet, 0x42 + 1);
        end

        -- Update our mob list..
        UpdateZoneMobList(zoneId);
    end

    return false;
end
