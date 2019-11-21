-- Magicalities crystals

magicalities.crystals = {}

local randbuff = PcgRandom(os.clock())

local function compare(a,b)
	return a[2] > b[2]
end

local function crystal_infotext(pos, data)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local nodedef = minetest.registered_nodes[node.name]
	if not data then
		data = minetest.deserialize(meta:get_string("contents"))
	end

	-- Sort
	local sortable = {}
	for name, v in pairs(data) do
		sortable[#sortable + 1] = {name, v[1]}
	end
	table.sort(sortable, compare)

	-- Create string
	local str = nodedef.description.. "\n\n"
	local datastrs = {}
	for _, v in pairs(sortable) do
		local elemdesc = magicalities.elements[v[1]].description
		datastrs[#datastrs + 1] = v[2].."x "..elemdesc
	end
	str = str .. table.concat( datastrs, "\n")

	meta:set_string("infotext", str)
end

function magicalities.crystals.generate_crystal_buffer(pos)
	local final    = {}
	local node     = minetest.get_node(pos)
	local nodedef  = minetest.registered_nodes[node.name]
	local self_cnt = randbuff:next(10, 60)
	local added    = 0

	for name, data in pairs(magicalities.elements) do
		if added > 5 then break end
		if not data.inheritance then
			if name == nodedef["_element"] then
				final[name] = {self_cnt, self_cnt}
				added = added + 1
			else
				if randbuff:next(0, 5) == 0 then
					local cnt = randbuff:next(0, math.floor(self_cnt / 4))
					if cnt > 0 then
						final[name] = {cnt, cnt}
						added = added + 1
					end
				end
			end
		else
			if randbuff:next(0, 15) == 0 then
				local cnt = randbuff:next(0, math.floor(self_cnt / 8))
				if cnt > 0 then
					final[name] = {cnt, cnt}
					added = added + 1
				end
			end
		end
	end

	return final
end

-- If content goes to zero, remove element from crystal
local function update_contents(pos, contents)
	local meta = minetest.get_meta(pos)
	local keep = {}

	for name,data in pairs(contents) do
		if data[1] > 0 then
			keep[name] = data
		end
	end

	meta:set_string("contents", minetest.serialize(keep))
end

local function crystal_rightclick(pos, node, clicker, itemstack, pointed_thing)
	local player = clicker:get_player_name()
	local meta = minetest.get_meta(pos)

	-- Protect crystals
	if minetest.is_protected(pos, player) then
		return itemstack
	end

	-- Add contents to the crystal
	local contents = minetest.deserialize(meta:get_string("contents"))
	if not contents then
		contents = magicalities.crystals.generate_crystal_buffer(pos)
		meta:set_string("contents", minetest.serialize(contents))
	end

	-- Check for wand
	if minetest.get_item_group(itemstack:get_name(), "wand") == 0 then
		return itemstack
	end

	-- The player learned about crystal tapping
	local element_ring = magicalities.player_has_recipe(player, "magicalities:crystal")
	if not element_ring then
		magicalities.player_learn(player, "magicalities:crystal")
	end

	-- Check if player can preserve this crystal
	local preserve = magicalities.player_has_ability(player, "magicalities:crystal_preserve")
	local mincheck = 0
	if preserve then mincheck = 1 end

	-- Check if we can take more than one
	local draining = magicalities.player_has_ability(player, "magicalities:crystal_draining")
	local maxtake = 1
	if draining then maxtake = 5 end

	local one_of_each = {}
	for name, count in pairs(contents) do
		if count[1] > mincheck then
			local take = maxtake
			if count[1] <= maxtake then
				take = count[1] - mincheck
			end

			if take > 0 then
				one_of_each[name] = take
			end
		end
	end

	local done_did = 0
	local can_put = magicalities.wands.wand_insertable_contents(itemstack, one_of_each)
	for name, count in pairs(can_put) do
		if count > 0 then
			done_did = done_did + count
			contents[name][1] = contents[name][1] - count
		end
	end

	if done_did == 0 then return itemstack end

	-- Take - Particles
	local cpls = clicker:get_pos()
	cpls.y = cpls.y + 1
	for name in pairs(can_put) do
		local ecolor = magicalities.elements[name].color
		local dist   = vector.distance(cpls, pos)
		local normal = vector.normalize(vector.subtract(cpls, pos))
		local spawn  = vector.add(normal, pos)
		local vel    = vector.multiply(normal, 4)
		local extime = dist / 4

		minetest.add_particle({
			pos = spawn,
			velocity = vel,
			acceleration = vel,
			expirationtime = extime,
			size = 4,
			collisiondetection = true,
			collision_removal = true,
			texture = "magicalities_spark.png^[multiply:"..ecolor.."",
			glow = 2
		})
	end

	itemstack = magicalities.wands.wand_insert_contents(itemstack, can_put)
	magicalities.wands.update_wand_desc(itemstack)
	update_contents(pos, contents)

	return itemstack
end

function magicalities.register_crystal(element, description, color)
	-- Crystal Item
	minetest.register_craftitem("magicalities:crystal_"..element, {
		description = description.." Crystal Shard",
		inventory_image = "magicalities_crystal_shard.png^[multiply:"..color,
		_element = element,
		groups = {crystal = 1, ["elemental_"..element] = 1}
	})

	-- Crystal Cluster
	minetest.register_node("magicalities:crystal_cluster_"..element, {
		description = description.." Crystal Cluster",
		use_texture_alpha = true,
		mesh = "crystal.obj",
		paramtype = "light",
		paramtype2 = "wallmounted",
		drawtype = "mesh",
		light_source = 4,
		_element = element,
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.4375, -0.5000, -0.4375, 0.4375, 0.3750, 0.4375}
			}
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.4375, -0.5000, -0.4375, 0.4375, 0.3750, 0.4375}
			}
		},
		tiles = {
			{
				name = "magicalities_crystal.png^[multiply:"..color,
				backface_culling = true
			}
		},
		drop = {
            max_items = 1,
            items = {
                {
                    items = {"magicalities:crystal_"..element.." 4"},
                    rarity = 1,
                },
                {
                    items = {"magicalities:crystal_"..element.." 5"},
                    rarity = 5,
                },
            },
		},
		groups = {cracky = 3, oddly_breakable_by_hand = 3, crystal_cluster = 1, ["elemental_"..element] = 1},
		sunlight_propagates = true,
		is_ground_content = false,
		sounds = default.node_sound_glass_defaults(),

		on_rightclick = crystal_rightclick,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
        	local meta = minetest.get_meta(pos)
        	local imeta = itemstack:get_meta()
        	meta:set_string("contents", imeta:get_string("contents"))
    	end
	})

	-- Crystal Block
	minetest.register_node("magicalities:crystal_block_"..element, {
		description = description.." Crystal Block",
		use_texture_alpha = true,
		paramtype = "light",
		drawtype = "glasslike",
		tiles = {
			{
				name = "magicalities_crystal.png^[multiply:"..color
			}
		},
		groups = {cracky = 3, oddly_breakable_by_hand = 3, crystal_block = 1, ["elemental_"..element] = 1},
		sunlight_propagates = true,
		is_ground_content = false,
		_element = element,
		sounds = default.node_sound_glass_defaults(),
	})

	-- Register cave crystal appearances
	minetest.register_decoration({
		deco_type = "simple",
		place_on  = "default:stone",
		sidelen   = 16,
		y_max = -30,
		y_min = -31000,
		flags = "all_ceilings",
		fill_ratio = 0.0004,
		decoration = "magicalities:crystal_cluster_"..element,
	})

	minetest.register_decoration({
		deco_type = "simple",
		place_on  = "default:stone",
		sidelen   = 16,
		y_max = -30,
		y_min = -31000,
		flags = "all_floors",
		fill_ratio = 0.0004,
		decoration = "magicalities:crystal_cluster_"..element,
	})

	minetest.register_craft({
		type = "shapeless",
		output = "magicalities:crystal_block_"..element,
		recipe = {
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element
		},
	})

	minetest.register_craft({
		type = "shapeless",
		output = "magicalities:crystal_"..element.." 9",
		recipe = {
			"magicalities:crystal_block_"..element
		},
	})
end

-- Register refill ABMs
minetest.register_abm({
	label     = "Crystal Elements Refill",
	nodenames = {"group:crystal_cluster"},
	interval  = 30.0,
	chance    = 2,
	action    = function (pos, node, active_object_count, active_object_count_wider)
		local meta = minetest.get_meta(pos)
		local contents = meta:get_string("contents")
		if contents ~= "" then
			-- Regenerate some elements
			contents = minetest.deserialize(contents)
			local count = 0
			for _, v in pairs(contents) do
				count = count + 1
			end

			if count == 0 then return end

			local mcnt    = randbuff:next(1, count)
			local cnt     = 0
			for name, data in pairs(contents) do
				if cnt == mcnt then break end
				if type(data) ~= 'table' then break end

				if data[1] < data[2] then
					data[1] = data[1] + 1
					cnt = cnt + 1
				end
			end

			if cnt == 0 then return end

			meta:set_string("contents", minetest.serialize(contents))
		end 
	end
})

minetest.register_on_generated(function (minp, maxp)
	local clusters = minetest.find_nodes_in_area(minp, maxp, "group:crystal_cluster")
	for _, pos in pairs(clusters) do
		local stone = minetest.find_node_near(pos, 1, "default:stone")
		if stone then
			local param2 = minetest.dir_to_wallmounted(vector.direction(pos, stone))

			local node = minetest.get_node(pos)
			node.param2 = param2
			minetest.set_node(pos, node)
		end
	end
end)
