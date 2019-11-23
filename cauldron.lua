
magicalities.cauldron = { recipes = {} }

function magicalities.cauldron.register_recipe(data)
	if data.learnable then
		local recipe_data = { name = data.output }
		if type(data.learnable) == "string" then
			recipe_data.name = data.learnable
		end

		if type(data.learnable) == "table" then
			recipe_data = table.copy(data.learnable)
			if not recipe_data.name then
				recipe_data.name = data.output
			end
		end

		if not recipe_data.description then
			local itm = minetest.registered_items[data.output]
			recipe_data.description = itm.description
		else
			recipe_data.description = data.description .. ""
		end

		data.learnable = recipe_data.name
		magicalities.register_recipe_learnable(recipe_data)
	end

	table.insert(magicalities.cauldron.recipes, data)
end

local function flatten_stacks(stacks)
	local temp = {}
	for _, stack in pairs(stacks) do
		if not stack:is_empty() then
			local name = stack:get_name()
			if not temp[name] then 
				temp[name] = stack:get_count()
			else
				temp[name] = temp[name] + stack:get_count()
			end
		end
	end

	local stacks_new = {}
	for name,count in pairs(temp) do
		table.insert(stacks_new, ItemStack(name .. " " .. count))
	end

	return stacks_new
end

local function get_recipe(items_found, wand)
	local flatstacks = flatten_stacks(items_found)
	local match = {}
	for _,r in pairs(magicalities.cauldron.recipes) do
		local pass = true
		for _,item in pairs(r.items) do
			local found = false
			for _,item2 in pairs(flatstacks) do
				local i1 = ItemStack(item)
				local i2 = ItemStack(item2)
				if i1:get_name() == i2:get_name() and i2:get_count() >= i1:get_count() then
					found = true
					break
				end
			end
			if not found then
				pass = false
				break
			end
		end
		if pass then
			table.insert(match,r)
		end
	end

	if #match == 0 then return nil end
	local fulfilled = {}
	for _,a in pairs(match) do
		if magicalities.wands.wand_has_contents(wand, a.requirements) then
			table.insert(fulfilled, a)
		end
	end

	if #fulfilled == 0 then return nil end
	return fulfilled[1]
end

-- Return a list of items dropped into the cauldron
local function sample_items(pos, pickup)
	local items = {}
	for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 1)) do
		if not object:is_player() and object:get_luaentity() and object:get_luaentity().name == "__builtin:item" then
			if object:get_luaentity().itemstring ~= "" then
				table.insert(items, object:get_luaentity().itemstring)
			end
			if pickup then
				object:get_luaentity().itemstring = ""
				object:remove()
			end
		end
	end
	if #items == 0 then return nil end
	return items
end

local _clddef = {
	description = "Cauldron",
	tiles = {"magicalities_cauldron.png"},
	groups = {cracky = 2, cauldron = 1},
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.4375, -0.4375, -0.4375, 0.4375, -0.3125, 0.4375},
			{-0.375, -0.5, -0.375, -0.25, -0.4375, -0.25},
			{0.25, -0.5, 0.25, 0.375, -0.4375, 0.375},
			{0.25, -0.5, -0.375, 0.375, -0.4375, -0.25},
			{-0.375, -0.5, 0.25, -0.25, -0.4375, 0.375},
			{-0.4375, -0.3125, -0.4375, 0.4375, 0.5, -0.3125},
			{-0.4375, -0.3125, 0.3125, 0.4375, 0.5, 0.4375},
			{-0.4375, -0.3125, -0.3125, -0.3125, 0.5, 0.3125},
			{0.3125, -0.3125, -0.3125, 0.4375, 0.5, 0.3125},
		}
	},
	on_construct = function (pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("items", 8)
	end,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		if node.name ~= "magicalities:cauldron" then return itemstack end
		if itemstack:get_name() == "bucket:bucket_water" then
			node.name = "magicalities:cauldron_with_water"
			minetest.swap_node(pos, node)
			return ItemStack("bucket:bucket_empty")
		end
		return itemstack
	end,
	_wand_use = function (pos, node, itemstack, user, pointed_thing)
		if not user or user:get_player_name() == "" then return itemstack end
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local stacks = inv:get_list("items")
		local recipe = get_recipe(stacks, itemstack)

		if user:get_player_control().sneak then
			inv:set_list("items", {})
			node.name = "magicalities:cauldron"
			minetest.swap_node(pos, node)
			return itemstack
		end

		if not recipe then return itemstack end
		if recipe.learnable and not magicalities.player_has_recipe(magicalities.wands.get_wand_owner(itemstack), recipe.learnable) then return itemstack end

		for j = 1, 16 do
			if not recipe then break end
			for _,st in pairs(recipe.items) do
				for _,sta in pairs(stacks) do
					if sta:get_name() == st then
						sta:take_item(ItemStack(st):get_count())
					end
				end
			end

			minetest.item_drop(ItemStack(recipe.output), user, user:get_pos())
			itemstack = magicalities.wands.wand_take_contents(itemstack, recipe.requirements)
			inv:set_list("items", stacks)
			recipe = get_recipe(stacks, itemstack)
		end

		inv:set_list("items", {})
		node.name = "magicalities:cauldron"
		minetest.swap_node(pos, node)
		magicalities.wands.update_wand_desc(itemstack)

		return itemstack
	end
}

local _clddefw = table.copy(_clddef)
_clddefw.groups.not_in_creative_inventory = 1
_clddefw.drop = "magicalities:cauldron"
_clddefw.tiles = {"magicalities_cauldron_with_water.png", "magicalities_cauldron.png", "magicalities_cauldron.png",
				"magicalities_cauldron.png", "magicalities_cauldron.png", "magicalities_cauldron.png"}
table.insert(_clddefw.node_box.fixed, {-0.3125, -0.3125, -0.3125, 0.3125, 0.375, 0.3125})

minetest.register_node("magicalities:cauldron", _clddef)
minetest.register_node("magicalities:cauldron_with_water", _clddefw)

minetest.register_abm({
	label = "Cauldron",
	interval = 1,
	chance = 1,
	--name = "magicalities:cauldron_insert",
	nodenames = {"magicalities:cauldron_with_water"},
	neighbors = {"group:igniter"},
	action = function(pos, node, active_object_count, active_object_count_wider)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local pickup = sample_items(pos, true)
		if not pickup then return end
		for _,i in pairs(pickup) do
			local stack = ItemStack(i)
			if inv:room_for_item("items", stack) then
				inv:add_item("items", stack)
			else
				minetest.item_drop(stack, "", vector.add(pos, {x=0,y=1,z=0}))
			end
		end
	end
})
