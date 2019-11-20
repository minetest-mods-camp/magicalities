
--[[
	JSON storage information:
	"<player name>": {
		"recipes": [<list of item names that this player knows how to craft>],
		"abilities": [<list of learned abilities that are not crafting recipes>],
		"protect": [<list of player protected nodes (positions)>],
		"research": <integer of research points>,
	}
]]

-- Modstorage
local storage = minetest.get_mod_storage()

-- Memory cache
magicalities.data = {}

local data_default = {
	recipes = {},
	abilities = {},
	protect = {},
	research = 0,
}

-- Storage actions

function magicalities.load_player_data(player_name)
	local stdata = minetest.deserialize(storage:get_string(player_name))

	if not stdata then
		magicalities.data[player_name] = table.copy(data_default)
		return
	end

	magicalities.data[player_name] = stdata
end

function magicalities.save_player_data(player_name)
	if not magicalities.data[player_name] then return end
	local data = magicalities.data[player_name]

	-- Do not save empty data
	if #data.recipes == 0 and #data.abilities == 0 and #data.protect == 0 and data.research == 0 then return end

	local str = minetest.serialize(data)

	storage:set_string(player_name, str)
end

function magicalities.save_all_data()
	for pname in pairs(magicalities.data) do
		minetest.after(0.1, magicalities.save_player_data, pname)
	end
end

-- System Actions

minetest.register_chatcommand("mgcstoragereset", {
	func = function (name, params)
		magicalities.data[name] = table.copy(data_default)
		magicalities.save_player_data(name)
		return true, "Deleted player storage successfully."
	end
})

minetest.register_chatcommand("mgcstoragesave", {
	privs = {basic_privs = 1},
	func = function (name, params)
		magicalities.save_all_data()
		return true, "Saved all magicalities data."
	end
})

minetest.register_on_shutdown(magicalities.save_all_data)

minetest.register_on_joinplayer(function (player)
	magicalities.load_player_data(player:get_player_name())
end)

minetest.register_on_leaveplayer(function (player, timed)
	local name = player:get_player_name()
	magicalities.save_player_data(name)
	if timed then return end
	magicalities.data[name] = nil
end)
