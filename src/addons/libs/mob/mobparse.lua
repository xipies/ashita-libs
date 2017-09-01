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

---------------------------------------------------------------------------------------------------
-- func: ParseZoneMobDat
-- desc: Parses a zone monster dat for monster name and id entries.
---------------------------------------------------------------------------------------------------
function ParseZoneMobDat( path )
    -- Attempt to open the DAT file..
    local f = io.open( path, 'rb' );
    if (f == nil) then
        return nil;
    end
    
    -- Attempt to obtain the file size..
    local curr = f:seek();
    local size = f:seek( 'end' );
    f:seek( 'set', 0 );
    
    -- Ensure the file size is valid.. (Entries are 0x1C in length)
    if (size == 0 or ((size - math.floor( size / 0x20 ) * 0x20) ~= 0)) then
        f:close();
        return nil;
    end
    
    -- Parse each entry from the file..
    local mobEntries = { };
    for x = 0, ((size / 0x20) - 1) do
        local mobData = f:read(0x20);
        local mobName, mobId = struct.unpack('c28L', mobData);
        table.insert(mobEntries, { bit.band(mobId, 0x0FFF), mobName });
    end
    f:close();
    
    return mobEntries;
end
