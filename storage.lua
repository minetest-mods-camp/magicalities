
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
local abilities = {}
local recipes = {}

-- Memory cache
magicalities.data = {}

-- Storage actions

function magicalities.load_player_data(player_name)
	local stdata = minetest.deserialize(storage:get_string(player_name))

	if not stdata then
		magicalities.data[player_name] = {
			recipes = {},
			abilities = {},
			protect = {},
			research = 0,
		}
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

-- Getters

function magicalities.player_has_recipe(player, recipe_name)
	if not magicalities.data[player] then return false end
	return table.indexof(magicalities.data[player].recipes, recipe_name) ~= -1
end

function magicalities.player_has_ability(player, ability_name)
	if not magicalities.data[player] then return false end
	return table.indexof(magicalities.data[player].abilities, ability_name) ~= -1
end

function magicalities.player_research(player)
	if not magicalities.data[player] then return 0 end
	return magicalities.data[player].research
end

-- Check if a recipe/ability depends on another recipe/ability
function magicalities.learn_meets_prerequisites(player_name, item, recipe)
	local a = abilities
	local c = magicalities.player_has_ability

	if recipe then
		a = recipes
		c = magicalities.player_has_recipe
	end

	if not a[item] then return false end
	if a[item].depends then
		local can = true
		for v in pairs(a[item].depends) do
			if not c(player, v) then
				can = false
				break
			end
		end
		if not can then return false end
	end

	return true
end

-- Setters

-- Learn a recipe or an ability
function magicalities.player_learn(player_name, item, recipe)
	if not magicalities.data[player_name] then
		magicalities.load_player_data(player_name)
	end

	local success = false
	local msgname = "to craft "

	if recipe and not magicalities.player_has_recipe(player_name, item) then
		local recipe_n = recipes[item]
		if recipe_n then
			recipe_n = recipe_n.description
		end
		table.insert(magicalities.data[player_name].recipes, item)
		success = true
		msgname = msgname .. recipe_n
	elseif not recipe and not magicalities.player_has_ability(player_name, item) then
		local ability_n = abilities[item]
		if ability_n then
			ability_n = ability_n.description
		end
		table.insert(magicalities.data[player_name].abilities, item)
		success = true
		msgname = "to " .. ability_n
	end

	if success then
		magicalities.save_player_data(player_name)
		minetest.chat_send_player(player_name, "You have learned " .. msgname .. "!")
	end
end

-- Add/remove research points
function magicalities.deal_research_points(player_name, points)
	if not magicalities.data[player_name] then
		magicalities.load_player_data(player_name)
	end

	magicalities.data[player_name].research = magicalities.data[player_name].research + points
	if magicalities.data[player_name].research < 0 then
		magicalities.data[player_name].research = 0
	end

	magicalities.save_player_data(player_name)
end

-- Registration

function magicalities.register_recipe_learnable (data)
	if not data.name or not data.description then return end
	recipes[data.name] = data
end

function magicalities.register_ability_learnable (data)
	if not data.name or not data.description then return end
	abilities[data.name] = data
end

-- System Actions

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
