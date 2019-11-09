
local abilities = {}
local recipes = {}

function magicalities.player_has_recipe(player, recipe_name)
	if not magicalities.data[player] then return false end
	return recipes[recipe_name] and (recipes[recipe_name].default == true or table.indexof(magicalities.data[player].recipes, recipe_name) ~= -1)
end

function magicalities.player_has_ability(player, ability_name)
	if not magicalities.data[player] then return false end
	return abilities[ability_name] and (abilities[ability_name].default == true or table.indexof(magicalities.data[player].abilities, ability_name) ~= -1)
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
		for _,v in pairs(a[item].depends) do
			if not c(player_name, v) then
				can = false
				break
			end
		end
		if not can then return false end
	end

	return true
end

-- List all abilities and crafting recipes available to player, (optionally including ones that can immediately be researched)
function magicalities.available_to_player(player_name, unlocked, researchable)
	local all = {}

	-- Abilities
	for name,data in pairs(abilities) do
		local tc = table.copy(data)
		tc.type = 'ability'
		if magicalities.player_has_ability(player_name, name) then
			tc.unlocked = true
			if unlocked then
				table.insert(all, tc)
			end
		elseif magicalities.learn_meets_prerequisites(player_name, name) and researchable then
			tc.unlocked = false
			table.insert(all, tc)
		end
	end

	-- Recipes
	for name,data in pairs(recipes) do
		local tc = table.copy(data)
		tc.type = 'recipe'
		if magicalities.player_has_recipe(player_name, name) then
			tc.unlocked = true
			if unlocked then
				table.insert(all, tc)
			end
		elseif magicalities.learn_meets_prerequisites(player_name, name, true) and researchable then
			tc.unlocked = false
			table.insert(all, tc)
		end
	end

	return all
end

local function no_newline(str)
	return str:gsub("\n(.*)", "")
end

-- Learn a recipe or an ability
function magicalities.player_learn(player_name, item, recipe, silent)
	if not magicalities.data[player_name] then
		magicalities.load_player_data(player_name)
	end

	local success = false
	local msgname = "to craft "

	if recipe and not magicalities.player_has_recipe(player_name, item) then
		local recipe_n = recipes[item]
		if recipe_n then
			recipe_n = no_newline(recipe_n.description)
			table.insert(magicalities.data[player_name].recipes, item)
			success = true
			msgname = msgname .. recipe_n
		end
	elseif not recipe and not magicalities.player_has_ability(player_name, item) then
		local ability_n = abilities[item]
		if ability_n then
			ability_n = no_newline(ability_n.description)
			table.insert(magicalities.data[player_name].abilities, item)
			success = true
			msgname = ability_n
		end
	end

	if success then
		magicalities.save_player_data(player_name)
		if not silent then
			minetest.chat_send_player(player_name, "You have learned " .. msgname .. "!")
		end
	end

	return success
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

function magicalities.register_recipe_learnable(data)
	if not data.name or not data.description then return end
	recipes[data.name] = data
end

function magicalities.register_ability_learnable(data)
	if not data.name or not data.description then return end
	abilities[data.name] = data
end
