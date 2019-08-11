
--[[
	JSON storage information:
	"<player name>": {
		"recipes": [<list of item names that this player knows how to craft>],
		"abilities": [<list of learned abilities that are not crafting recipes>],
		"protect": [<list of player protected nodes (positions)>],
		"research": <integer of research points>,
	}
]]

-- Memory cache
magicalities.data = {}

function magicalities.load_player_data(player_name)
	local world     = minetest.get_worldpath()
	local directory = world.."/magicalities"
	minetest.mkdir(directory)

	local filetag = player_name..".info.json"
	local file = io.open(directory.."/"..filetag)
	
	if not file then
		magicalities.data[player_name] = {
			recipes = {},
			abilities = {},
			protect = {},
			research = 0,
		}
		return
	end

	local str = ""
	for line in file:lines() do
		str = str..line
	end

	file:close()

	magicalities.data[player_name] = minetest.deserialize(str)
end

function magicalities.save_player_data(player_name)
	if not magicalities.data[player_name] then return nil end

	local world     = minetest.get_worldpath()
	local directory = world.."/magicalities"
	minetest.mkdir(directory)

	local filetag = player_name..".info.json"
	local data    = minetest.serialize(magicalities.data[player_name])

	minetest.safe_file_write(directory.."/"..filetag, data)
end

function magicalities.save_all_data()
	for pname in pairs(magicalities.data) do
		minetest.after(0.1, magicalities.save_player_data, pname)
	end
end

minetest.register_on_shutdown(magicalities.save_all_data)
