
-- Pickaxe

minetest.register_tool("magicalities:pick_tellium", {
	description = "Tellium Pickaxe",
	inventory_image = "magicalities_tellium_pick.png",
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level = 3,
		groupcaps = {
			cracky = { times = { [1] = 2.0, [2] = 1.0, [3] = 0.50}, uses = 30, maxlevel = 3},
		},
		damage_groups = { fleshy = 5 },
	},
	sound = { breaks = "default_tool_breaks" },
	groups = { pickaxe = 1 },
	on_secondary_use = function(itemstack, user, pointed_thing)
		local w = itemstack:get_wear()
		itemstack = ItemStack("magicalities:pick_tellium_rage")
		itemstack:set_wear(w)
		minetest.sound_play("magicalities_charge")
		return itemstack
	end,
})

minetest.register_tool("magicalities:pick_tellium_rage", {
	description = "Empowered Tellium Pickaxe",
	inventory_image = "magicalities_tellium_pick_rage.png",
	tool_capabilities = {
		full_punch_interval = 0.45,
		max_drop_level = 3,
		groupcaps = {
			cracky = { times = { [1] = 1.0, [2] = 0.5, [3] = 0.25}, uses = 5, maxlevel = 3},
		},
		damage_groups = { fleshy = 10 },
	},
	sound = { breaks = "default_tool_breaks" },
	groups = { pickaxe = 1, not_in_creative_inventory = 1 },
	on_secondary_use = function(itemstack, user, pointed_thing)
		local w = itemstack:get_wear()
		itemstack = ItemStack("magicalities:pick_tellium")
		itemstack:set_wear(w)
		minetest.sound_play("magicalities_discharge")
		return itemstack
	end,
})

-- Shovel

minetest.register_tool("magicalities:shovel_tellium", {
	description = "Tellium Shovel",
	inventory_image = "magicalities_tellium_shovel.png",
	wield_image = "magicalities_tellium_shovel.png^[transformR90",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level = 1,
		groupcaps = {
			crumbly = { times = { [1] = 1.10, [2] = 0.50, [3] = 0.30}, uses = 30, maxlevel = 3},
		},
		damage_groups = { fleshy = 4 },
	},
	sound = { breaks = "default_tool_breaks" },
	groups = { shovel = 1 },
	on_secondary_use = function(itemstack, user, pointed_thing)
		local w = itemstack:get_wear()
		itemstack = ItemStack("magicalities:shovel_tellium_rage")
		itemstack:set_wear(w)
		minetest.sound_play("magicalities_charge")
		return itemstack
	end,
})

minetest.register_tool("magicalities:shovel_tellium_rage", {
	description = "Empowered Tellium Shovel",
	inventory_image = "magicalities_tellium_shovel_rage.png",
	wield_image = "magicalities_tellium_shovel_rage.png^[transformR90",
	tool_capabilities = {
		full_punch_interval = 0.5,
		max_drop_level = 1,
		groupcaps = {
			crumbly = { times = { [1] = 0.55, [2] = 0.25, [3] = 0.15}, uses = 5, maxlevel = 3},
		},
		damage_groups = { fleshy = 4 },
	},
	sound = { breaks = "default_tool_breaks" },
	groups = { shovel = 1, not_in_creative_inventory = 1 },
	on_secondary_use = function(itemstack, user, pointed_thing)
		local w = itemstack:get_wear()
		itemstack = ItemStack("magicalities:shovel_tellium")
		itemstack:set_wear(w)
		minetest.sound_play("magicalities_discharge")
		return itemstack
	end,
})

-- Axe

minetest.register_tool("magicalities:axe_tellium", {
	description = "Tellium Axe",
	inventory_image = "magicalities_tellium_axe.png",
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level = 1,
		groupcaps = {
			choppy = { times = { [1] = 2.10, [2] = 0.90, [3] = 0.50}, uses = 30, maxlevel = 3},
		},
		damage_groups = { fleshy = 7 },
	},
	sound = { breaks = "default_tool_breaks" },
	groups = { axe = 1 },
	on_secondary_use = function(itemstack, user, pointed_thing)
		local w = itemstack:get_wear()
		itemstack = ItemStack("magicalities:axe_tellium_rage")
		itemstack:set_wear(w)
		minetest.sound_play("magicalities_charge")
		return itemstack
	end,
})

minetest.register_tool("magicalities:axe_tellium_rage", {
	description = "Empowered Tellium Axe",
	inventory_image = "magicalities_tellium_axe_rage.png",
	tool_capabilities = {
		full_punch_interval = 0.45,
		max_drop_level = 1,
		groupcaps = {
			choppy = { times = { [1] = 1.05, [2] = 0.45, [3] = 0.25}, uses = 5, maxlevel = 3},
		},
		damage_groups = { fleshy = 14 },
	},
	sound = { breaks = "default_tool_breaks" },
	groups = { axe = 1, not_in_creative_inventory = 1 },
	on_secondary_use = function(itemstack, user, pointed_thing)
		local w = itemstack:get_wear()
		itemstack = ItemStack("magicalities:axe_tellium")
		itemstack:set_wear(w)
		minetest.sound_play("magicalities_discharge")
		return itemstack
	end,
})

-- Sword

minetest.register_tool("magicalities:sword_tellium", {
	description = "Tellium Sword",
	inventory_image = "magicalities_tellium_sword.png",
	tool_capabilities = {
		full_punch_interval = 0.7,
		max_drop_level = 1,
		groupcaps = {
			snappy = { times={ [1] = 1.90, [2] = 0.90, [3] = 0.30 }, uses = 40, maxlevel = 3 },
		},
		damage_groups = { fleshy = 8 },
	},
	sound = { breaks = "default_tool_breaks" },
	groups = { sword = 1 },
	on_secondary_use = function(itemstack, user, pointed_thing)
		local w = itemstack:get_wear()
		itemstack = ItemStack("magicalities:sword_tellium_rage")
		itemstack:set_wear(w)
		minetest.sound_play("magicalities_charge")
		return itemstack
	end,
})

minetest.register_tool("magicalities:sword_tellium_rage", {
	description = "Empowered Tellium Sword",
	inventory_image = "magicalities_tellium_sword_rage.png",
	tool_capabilities = {
		full_punch_interval = 0.35,
		max_drop_level = 1,
		groupcaps = {
			snappy = { times={ [1] = 0.95, [2] = 0.45, [3] = 0.15 }, uses = 10, maxlevel = 3 },
		},
		damage_groups = { fleshy = 16 },
	},
	sound = { breaks = "default_tool_breaks" },
	groups = { sword = 1, not_in_creative_inventory = 1 },
	on_secondary_use = function(itemstack, user, pointed_thing)
		local w = itemstack:get_wear()
		itemstack = ItemStack("magicalities:sword_tellium")
		itemstack:set_wear(w)
		minetest.sound_play("magicalities_discharge")
		return itemstack
	end,
})
