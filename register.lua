---------------------------
-- Register all crystals --
---------------------------

for name, data in pairs(magicalities.elements) do
	if not data.inheritance then
		magicalities.register_crystal(name, data.description, data.color)
	end
end

-----------
-- Wands --
-----------

-- Iron
magicalities.wands.register_wand("steel", {
	description = "Steel-Capped Wand",
	image       = "magicalities_wand_iron.png",
	wand_cap    = 25,
})

-- Gold
magicalities.wands.register_wand("gold", {
	description = "Gold-Capped Wand",
	image       = "magicalities_wand_gold.png",
	wand_cap    = 50,
})

-- Tellium
magicalities.wands.register_wand("tellium", {
	description = "Tellium-Capped Wand",
	image       = "magicalities_wand_tellium.png",
	wand_cap    = 100,
})

-----------------------------
-- Arcane crafting recipes --
-----------------------------

local recipes = {
	{
		input = {
			{"default:gold_ingot", "default:glass", "default:gold_ingot"},
			{"default:glass",      "",              "default:glass"},
			{"default:gold_ingot", "default:glass", "default:gold_ingot"},
		},
		output = "magicalities:element_ring",
		requirements = {
			["water"] = 15,
			["earth"] = 15,
			["light"] = 15,
			["fire"]  = 15,
			["dark"]  = 15,
			["air"]   = 15,
		},
		learnable = true
	},
	{
		input = {
			{"",              "",                       "magicalities:cap_gold"},
			{"",              "magicalities:wand_core", ""},
			{"group:crystal", "",                       ""}
		},
		output = "magicalities:wand_gold",
		requirements = {
			["water"] = 25,
			["earth"] = 25,
			["light"] = 25,
			["fire"]  = 25,
			["dark"]  = 25,
			["air"]   = 25,
		},
		learnable = true
	},
	{
		input = {
			{"",                     "magicalities:focus_atk_earth", "magicalities:cap_tellium"},
			{"magicalities:tellium", "magicalities:wand_core",       "magicalities:focus_atk_water"},
			{"group:crystal",        "magicalities:tellium",         ""}
		},
		output = "magicalities:wand_tellium",
		requirements = {
			["water"] = 50,
			["earth"] = 50,
			["light"] = 50,
			["fire"]  = 50,
			["dark"]  = 50,
			["air"]   = 50,
		},
		learnable = {
			depends = {"magicalities:wand_gold", "magicalities:focus_atk_earth", "magicalities:focus_atk_water"}
		}
	},
	{
		input = {
			{"default:gold_ingot", "default:gold_ingot", "default:gold_ingot"},
			{"default:gold_ingot", "",                   "default:gold_ingot"},
		},
		output = "magicalities:cap_gold",
		requirements = {
			["earth"] = 5,
			["light"] = 5,
			["dark"]  = 5,
		}
	},
	{
		input = {
			{"magicalities:tellium", "magicalities:tellium", "magicalities:tellium"},
			{"magicalities:tellium", "",                   "magicalities:tellium"},
		},
		output = "magicalities:cap_tellium",
		requirements = {
			["earth"] = 25,
			["light"] = 25,
			["dark"]  = 25,
		}
	},
	{
		input = {
			{"group:crystal",        "magicalities:tellium", "group:crystal"},
			{"magicalities:tellium", "group:crystal",        "magicalities:tellium"},
			{"group:crystal",        "magicalities:tellium", "group:crystal"}
		},
		output = "magicalities:focus_blank",
		requirements = {
			["light"] = 10,
			["dark"] = 10,
		},
		learnable = {
			depends = {"magicalities:tellium"}
		}
	},
	{
		input = {
			{"magicalities:crystal_earth", "magicalities:tellium",     "magicalities:crystal_earth"},
			{"magicalities:tellium",       "magicalities:focus_blank", "magicalities:tellium"},
			{"magicalities:crystal_earth", "magicalities:tellium",     "magicalities:crystal_earth"}
		},
		output = "magicalities:focus_atk_earth",
		requirements = {
			["earth"] = 50,
		},
		learnable = {
			depends = {"magicalities:focus_blank"}
		}
	},
	{
		input = {
			{"magicalities:crystal_air", "magicalities:tellium",     "magicalities:crystal_air"},
			{"magicalities:tellium",     "magicalities:focus_blank", "magicalities:tellium"},
			{"magicalities:crystal_air", "magicalities:tellium",     "magicalities:crystal_air"}
		},
		output = "magicalities:focus_atk_air",
		requirements = {
			["air"] = 50,
		},
		learnable = {
			depends = {"magicalities:focus_blank"}
		}
	},
	{
		input = {
			{"magicalities:crystal_water", "magicalities:tellium",     "magicalities:crystal_water"},
			{"magicalities:tellium",       "magicalities:focus_blank", "magicalities:tellium"},
			{"magicalities:crystal_water", "magicalities:tellium",     "magicalities:crystal_water"}
		},
		output = "magicalities:focus_atk_water",
		requirements = {
			["water"] = 50,
		},
		learnable = {
			depends = {"magicalities:focus_blank"}
		}
	},
	{
		input = {
			{"magicalities:crystal_fire", "magicalities:tellium",     "magicalities:crystal_fire"},
			{"magicalities:tellium",      "magicalities:focus_blank", "magicalities:tellium"},
			{"magicalities:crystal_fire", "magicalities:tellium",     "magicalities:crystal_fire"}
		},
		output = "magicalities:focus_atk_fire",
		requirements = {
			["fire"] = 50,
		},
		learnable = {
			depends = {"magicalities:focus_blank"}
		}
	},
	{
		input = {
			{"magicalities:crystal_earth", "default:dirt",                 "magicalities:crystal_light"},
			{"magicalities:transterra",    "magicalities:focus_atk_earth", "magicalities:transterra"},
			{"magicalities:crystal_light", "default:stone",                "magicalities:crystal_earth"}
		},
		output = "magicalities:focus_swap",
		requirements = {
			["earth"] = 25,
			["light"] = 25,
		},
		learnable = {
			depends = {"magicalities:focus_atk_earth"}
		}
	},
	{
		input = {
			{"magicalities:crystal_earth", "magicalities:tellium",     "magicalities:transterra"},
			{"magicalities:tellium",       "magicalities:focus_blank", "magicalities:tellium"},
			{"magicalities:transterra",    "magicalities:tellium",     "magicalities:crystal_earth"}
		},
		output = "magicalities:focus_tunnel",
		requirements = {
			["earth"] = 25,
			["dark"]  = 25,
		},
		learnable = {
			depends = {"magicalities:focus_blank", "magicalities:transterra"}
		}
	},
	{
		input = {
			{"magicalities:crystal_air", "",                           "magicalities:crystal_air"},
			{"",                         "magicalities:focus_atk_air", ""},
			{"magicalities:crystal_air", "",                           "magicalities:crystal_air"}
		},
		output = "magicalities:focus_teleport",
		requirements = {
			["air"] = 10,
		},
		learnable = {
			depends = {"magicalities:focus_atk_air"}
		}
	},
	{
		input = {
			{"magicalities:crystal_light", "magicalities:crystal_block_light", "magicalities:crystal_light"},
			{"default:stone",              "magicalities:focus_blank",         "default:stone"},
			{"magicalities:crystal_light", "magicalities:crystal_block_light", "magicalities:crystal_light"}
		},
		output = "magicalities:focus_light",
		requirements = {
			["light"] = 10,
		},
		learnable = {
			depends = {"magicalities:focus_blank"}
		}
	},
	{
		input = {
			{"magicalities:tellium", "magicalities:tellium", ""},
			{"magicalities:tellium", "magicalities:transterra", ""},
			{"", "default:stick", ""}
		},
		output = "magicalities:axe_tellium",
		requirements = {
			["air"] = 45,
			["light"] = 45,
			["earth"] = 15
		},
		learnable = {
			depends = {"magicalities:tellium", "magicalities:transterra", "magicalities:wand_gold"}
		}
	},
	{
		input = {
			{"magicalities:tellium", "magicalities:tellium", "magicalities:tellium"},
			{"", "magicalities:transterra", ""},
			{"", "default:stick", ""}
		},
		output = "magicalities:pick_tellium",
		requirements = {
			["air"] = 45,
			["light"] = 15,
			["earth"] = 45
		},
		learnable = {
			depends = {"magicalities:tellium", "magicalities:transterra", "magicalities:wand_gold"}
		}
	},
	{
		input = {
			{"", "magicalities:tellium", ""},
			{"", "magicalities:transterra", ""},
			{"", "default:stick", ""}
		},
		output = "magicalities:shovel_tellium",
		requirements = {
			["air"] = 45,
			["dark"] = 15,
			["earth"] = 45
		},
		learnable = {
			depends = {"magicalities:tellium", "magicalities:transterra", "magicalities:wand_gold"}
		}
	},
	{
		input = {
			{"", "magicalities:tellium", ""},
			{"", "magicalities:tellium", ""},
			{"", "magicalities:transterra", ""}
		},
		output = "magicalities:sword_tellium",
		requirements = {
			["air"] = 45,
			["dark"] = 45,
			["light"] = 45,
			["earth"] = 45,
			["fire"] = 15
		},
		learnable = {
			depends = {"magicalities:tellium", "magicalities:transterra", "magicalities:wand_gold"}
		}
	}
}

for _, recipe in pairs(recipes) do
	magicalities.arcane.register_recipe(recipe)
end

--------------
-- Cauldron --
--------------

local cauldron_recipes = {
	{
		items = {"default:steel_ingot", "default:obsidian"},
		requirements = {
			earth = 1,
			dark  = 1,
		},
		output = "magicalities:tellium",
		learnable = true
	},
	{
		items = {"default:stone", "default:dirt", "magicalities:crystal_fire"},
		requirements = {
			fire  = 5,
			earth = 5,
		},
		output = "magicalities:transterra",
		learnable = true
	}
}

for _, recipe in pairs(cauldron_recipes) do
	magicalities.cauldron.register_recipe(recipe)
end

--------------------
-- Basic Crafting --
--------------------

minetest.register_craft({
	recipe = {
		{"default:steel_ingot",     "default:steel_ingot", "default:steel_ingot"},
		{"", "default:steel_ingot", "default:steel_ingot"},
		{"", "",                    "default:steel_ingot"},
	},
	output = "magicalities:cap_steel",
})

minetest.register_craft({
	recipe = {
		{"",              "default:stick"},
		{"default:stick", ""},
	},
	output = "magicalities:wand_core",
})

minetest.register_craft({
	recipe = {
		{"",              "",                       "magicalities:cap_steel"},
		{"",              "magicalities:wand_core", ""},
		{"group:crystal", "",                       ""}
	},
	output = "magicalities:wand_steel",
})

minetest.register_craft({
	recipe = {
		{"group:tree", "group:tree", "group:tree"},
		{"",           "group:tree", ""},
		{"group:tree", "group:tree", "group:tree"}
	},
	output = "magicalities:table",
})

minetest.register_craft({
	recipe = {
		{"default:steelblock", "", "default:steelblock"},
		{"default:steelblock", "", "default:steelblock"},
		{"default:steelblock", "default:steelblock", "default:steelblock"}
	},
	output = "magicalities:cauldron",
})

if minetest.registered_items["mobs:chicken_feather"] then
	minetest.register_craft({
		recipe = {
			{"mobs:chicken_feather"},
			{"group:color_black"},
			{"default:glass"}
		},
		output = "magicalities:ink_and_quill",
	})
else
	minetest.register_craft({
		recipe = {
			{"group:color_white"},
			{"group:color_black"},
			{"default:glass"}
		},
		output = "magicalities:ink_and_quill",
	})
end

local function _flatten(arr)
	local result = {}
	for i,v in ipairs(arr) do
		for j,b in ipairs(v) do
			table.insert(result, b)
		end
	end
	return result
end

if minetest.get_modpath("craftguide") ~= nil then
	local function construct_gridset(list)
		local final = {}
		for a,v in pairs(list) do
			local height = math.ceil(a / 3)
			if not final[height] then
				if v == "" then v = "," end
				final[height] = v
			else
				final[height] = final[height] .. "," .. v
			end
		end
		return final
	end

	local function register_craftguide_recipe(type,output,items)
		craftguide.register_craft({
			type   = type,
			output = output,
			items  = construct_gridset(items),
		})
	end

	craftguide.register_craft_type("arcane", {
		description = "Arcane Crafting",
		icon = "magicalities_table_arcane_top.png",
	})

	for _, recipe in pairs(recipes) do
		register_craftguide_recipe("arcane", recipe.output, _flatten(recipe.input))
	end

	-- How to make things with wand
	craftguide.register_craft_type("wand", {
		description = "Use Wand",
		icon = "magicalities_wand_iron.png",
	})

	for g,v in pairs(magicalities.wands.transform_recipes) do
		if v.result and type(v.result) == "string" then
			register_craftguide_recipe("wand", v.result, {g})
		end
	end

	-- Cauldron
	craftguide.register_craft_type("cauldron", {
		description = "Cauldron",
		icon = "magicalities_cauldron.png",
	})

	for g,v in pairs(cauldron_recipes) do
		register_craftguide_recipe("cauldron", v.output, v.items)
	end
end

-- Treasurer mod, add Research Notes as a form of treasure.
if minetest.get_modpath("treasurer") then
	treasurer.register_treasure("magicalities:note", 0.35, 5, {1,3}, nil, "tool")
	treasurer.register_treasure("magicalities:tellium", 0.8, 8, {1,3}, nil, "crafting_component")
	treasurer.register_treasure("magicalities:transterra", 0.8, 5, {1,3}, nil, "crafting_component")
end

---------------
-- Abilities --
---------------

-- Default abilities

magicalities.register_recipe_learnable({
	name = "magicalities:wand_steel",
	description = "Wands",
	default = true,
})

magicalities.register_recipe_learnable({
	name = "magicalities:table",
	description = "Research Table\nDo research about the magic world",
	default = true,
})

magicalities.register_recipe_learnable({
	name = "magicalities:arcane_table",
	description = "Arcane Table\nCraft magical items",
	default = true,
})

magicalities.register_recipe_learnable({
	name = "magicalities:cauldron",
	description = "Cauldron",
	default = true
})

-- Crystals

magicalities.register_ability_learnable({
	name = "magicalities:crystal",
	description = "Crystal Tapping\nExtract elements from crystals",
	icon = "magicalities_crystal_gui.png",
})

magicalities.register_ability_learnable({
	name = "magicalities:crystal_preserve",
	description = "Crystal Preservation\nAvoid collecting every last drop of elements",
	icon = "magicalities_crystal_preservation.png",
	depends = {"magicalities:crystal"}
})

magicalities.register_ability_learnable({
	name = "magicalities:crystal_draining",
	description = "Efficient Crystal Draining\nIncrease element drain rate",
	depends = {"magicalities:crystal_preserve"},
	icon = "magicalities_crystal_draining.png"
})

magicalities.register_ability_learnable({
	name = "magicalities:pickup_jarred",
	description = "Crystal Jarring\nPick up intact crystals using jarring",
	depends = {"magicalities:crystal_preserve"},
	icon = "magicalities_jarred.png"
})
