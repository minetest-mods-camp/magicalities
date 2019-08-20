---------------------------
-- Register all crystals --
---------------------------

for name, data in pairs(magicalities.elements) do
	if not data.inheritance then
		magicalities.register_crystal(name, data.description, data.color)
	end
end

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
		}
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
			{"group:crystal",        "magicalities:tellium", "group:crystal"},
			{"magicalities:tellium", "group:crystal",        "magicalities:tellium"},
			{"group:crystal",        "magicalities:tellium", "group:crystal"}
		},
		output = "magicalities:focus_blank",
		requirements = {
			["light"] = 10,
			["dark"] = 10,
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
		}
	}
}

for _, recipe in pairs(recipes) do
	magicalities.arcane.register_recipe(recipe)
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

--------------------
-- Basic Crafting --
--------------------

minetest.register_craft({
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "",                    "default:steel_ingot"},
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
	craftguide.register_craft_type("arcane", {
		description = "Arcane Crafting",
		icon = "magicalities_table_arcane_top.png",
	})

	for _, recipe in pairs(recipes) do
		craftguide.register_craft({
			type   = "arcane",
			output = recipe.output,
			width  = 3,
			height = 3,
			items  = _flatten(recipe.input),
		})
	end

	-- How to make things with wand
	craftguide.register_craft_type("wand", {
		description = "Use Wand",
		icon = "magicalities_wand_iron.png",
	})

	for g,v in pairs(magicalities.wands.transform_recipes) do
		craftguide.register_craft({
			type   = "wand",
			output = v.result,
			width  = 1,
			items  = {"group:"..g},
		})
	end

	-- Cauldron
	craftguide.register_craft_type("cauldron", {
		description = "Cauldron",
		icon = "magicalities_cauldron.png",
	})

	for g,v in pairs(magicalities.cauldron.recipes) do
		local height = math.ceil(#v.items / 3)
		local width = math.floor(#v.items % 3)
		craftguide.register_craft({
			type   = "cauldron",
			output = v.output,
			height = height,
			width  = width,
			items  = v.items,
		})
	end
end
