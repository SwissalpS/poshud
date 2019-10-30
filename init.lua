--Simple head-up display for current position in space and time.

-- Origin:
--ver 0.2.1 minetest_time

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-------Minetest Time--kazea's code tweaked by cg72 with help from crazyR--------
----------------Zeno` simplified some math and additional tweaks ---------------
--------------------------------------------------------------------------------

poshud_light = {
	-- Position of hud
	posx = tonumber(minetest.settings:get("poshud_light.hud.offsetx") or 0.8),
	posy = tonumber(minetest.settings:get("poshud_light.hud.offsety") or 0.95)
}

-- deps
local has_advtrains_mod = minetest.get_modpath("advtrains")

--settings

local colour = 0xFFFFFF  --text colour in hex format default is white

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- hud id map (playername -> hud-id)
local player_hud = {}

-- hud enabled map (playername -> bool)
local player_hud_enabled = {}

local function generatehud(player)
	local name = player:get_player_name()

	if player_hud[name] then
		-- already set up
		return
	end

	local hud = {}
	hud.id = player:hud_add({
		hud_elem_type = "text",
		name = "poshud_light",
		position = {x=poshud_light.posx, y=poshud_light.posy},
		offset = {x=8, y=-8},
		text = "Initializing...",
		scale = {x=100,y=100},
		alignment = {x=1,y=0},
		number = colour, --0xFFFFFF,
	})
	player_hud[name] = hud
end

local function updatehud(player, text)

	local name = player:get_player_name()

	if player_hud_enabled[name]==false then
		-- check if the player enabled the hud
		return
	end

	if not player_hud[name] then
		generatehud(player)
	end

	local hud = player_hud[name]
	if not hud then return end

	local posi = player:get_pos()
	local x = math.floor(posi.x + 0.5)
	local y = math.floor(posi.y + 0.5)
	local z = math.floor(posi.z + 0.5)
	local posistr = x.." | ".. y .." | ".. z

	-- resulting hud string
	local hud_display = text .. "\nPos: " .. posistr

	-- append mapblock
	local mapblockstr = math.floor(x / 16) .. " | "
			.. math.floor(y / 16) .. " | "
			.. math.floor(z / 16)


	hud_display = hud_display .. "\nBlock: " .. mapblockstr

	player:hud_change(hud.id, "text", hud_display)

end

local function removehud(player)
	local name = player:get_player_name()
	if player_hud[name] then
		player:hud_remove(player_hud[name].id)
		player_hud[name] = nil
	end
end

minetest.register_on_leaveplayer(function(player)
	minetest.after(1,removehud,player)
end)


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- hud enabled/disable


minetest.register_chatcommand("poshud", {
	params = "on|off",
	description = "Turn poshud on or off",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)

		if param == "on" then
			player_hud_enabled[name] = true
			generatehud(player)

		elseif param == "off" then
			player_hud_enabled[name] = false
			removehud(player)

		else
			return true, "Usage: poshud [on|off]"

		end
	end
})


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- time
-- from https://gitlab.com/Rochambeau/mthudclock/blob/master/init.lua

local function floormod ( x, y )
	return (math.floor(x) % y);
end

local function get_time()
	local secs = (60*60*24*minetest.get_timeofday());
	local m = floormod(secs/60, 60);
	local h = floormod(secs/3600, 60);
	return ("%02d:%02d"):format(h, m);
end

-- track time of last call
local time_next_refresh = 0

minetest.register_globalstep(function()

	-- time to update?
	local now = os.clock()
	if time_next_refresh > now then return end

	time_next_refresh = now + 2

	-- Update hud text that is the same for all players
	local s_time = "Time: " .. get_time()

	local s_rwt = ""
	if has_advtrains_mod and advtrains.lines and advtrains.lines.rwt then
		s_rwt = "\nRailway Time: "..advtrains.lines.rwt.to_string(advtrains.lines.rwt.now(), true)
	end

	local h_text = s_time .. "   " .. s_rwt

	for _, player in ipairs(minetest.get_connected_players()) do
		updatehud(player,  h_text)
	end

end);

