-- Wand Focuses

minetest.register_craftitem("magicalities:focus_teleport", {
	description = "Wand Focus of Teleportation",
	groups = {wand_focus = 1},
	inventory_image = "magicalities_focus_teleport.png",
	stack_max = 1,
	_wand_requirements = {
		["air"] = 1
	},
	_wand_use = function (itemstack, user, pointed_thing)
		local dir  = user:get_look_dir()
		local dest = vector.multiply(dir, 20)
		dest = vector.add(dest, user:get_pos())

		local pos = user:get_pos()
		pos.x = pos.x + (dir.x * 2)
		pos.y = pos.y + (dir.y * 2) + 1.5
		pos.z = pos.z + (dir.z * 2)

		local ray  = Raycast(pos, dest, true, false)
		local targ = ray:next()
		local can_go = targ == nil

		if targ and targ.type == "node" then
			local abv = minetest.get_node(targ.above)
			if not abv or abv.name == "air" then
				dest = targ.above
				can_go = true
			end
		end

		if can_go then
			itemstack = magicalities.wands.wand_take_contents(itemstack, {air = 1})
			magicalities.wands.update_wand_desc(itemstack)
			user:set_pos(dest)
		end

		return itemstack
	end
})

minetest.register_craftitem("magicalities:focus_swap", {
	description = "Wand Focus of Swapping",
	groups = {wand_focus = 1},
	inventory_image = "magicalities_focus_swap.png",
	stack_max = 1,
	_wand_requirements = {
		["earth"] = 1
	},
	_wand_use = function (itemstack, user, pointed_thing)
		local meta = itemstack:get_meta()
		local tnode = meta:get_string("swapnode")
		local pname = user:get_player_name()
		if tnode == "" or pointed_thing.type ~= "node" then return itemstack end

		local pos = pointed_thing.under

		if minetest.is_protected(pos, pname) then
			return itemstack
		end

		local node = minetest.get_node_or_nil(pos)
		if not node or node.name == tnode then
			return itemstack
		end

		local place_node_itm = ItemStack(tnode)
		local inv = user:get_inventory()

		local ndef = minetest.registered_nodes[tnode]
		if not inv:contains_item("main", place_node_itm) then
			minetest.chat_send_player(pname, ("You don't have enough %s in your inventory."):format(ndef.description))
			return itemstack
		end

		local drops = minetest.get_node_drops(pos)

		if ndef.can_dig ~= nil and not ndef.can_dig(pos, user) then
			return itemstack
		end

		minetest.remove_node(pos)

		itemstack = magicalities.wands.wand_take_contents(itemstack, {earth = 1})
		magicalities.wands.update_wand_desc(itemstack)

		inv:remove_item("main", place_node_itm)

		for _, stk in pairs(drops) do
			if inv:room_for_item("main", stk) then
				inv:add_item("main", stk)
			else
				minetest.item_drop(ItemStack(stk), user, vector.add(pos, {x=0,y=1,z=0}))
			end
		end

		minetest.place_node(pos, {name = tnode})

		return itemstack
	end,
	_wand_node = function (pos, node, placer, itemstack, pointed_thing)
		if not node or node.name == "air" or node.name == "ignore" then return itemstack end
		local meta = itemstack:get_meta()
		local tnode = meta:get_string("swapnode")

		if tnode == node.name then return itemstack end
		meta:set_string("swapnode", node.name)

		local ndef = minetest.registered_nodes[node.name]
		minetest.chat_send_player(placer:get_player_name(), "Selected replacement node " .. ndef.description)

		return itemstack
	end
})


local tunneler_memory = {}
local tunneler_depth  = 8

local function reset_tunnel(tid)
	local infos = tunneler_memory['t' .. tid]
	if not infos then return end

	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(infos.minp, infos.maxp)
	local area = VoxelArea:new{MinEdge=e1, MaxEdge=e2}

	local data = manip:get_data()

	for i in area:iterp(infos.minp, infos.maxp) do
		if infos.data[i] ~= nil then
			data[i] = infos.data[i]
		end
	end

	manip:set_data(data)
	manip:write_to_map()

	tunneler_memory['t' .. tid] = nil

	t = false
end

local function create_tunnel(pos, dir, owner)
	-- Ensure no double tunnels
	for id,data in pairs(tunneler_memory) do
		if data.owner == owner then
			return
		end
	end

	local minp
	local maxp

	if dir.x < 0 or dir.y < 0 or dir.z < 0 then
		maxp = vector.add(pos, dir)
		minp = vector.add(pos, vector.multiply(dir, tunneler_depth))
	else
		minp = vector.add(pos, dir)
		maxp = vector.add(pos, vector.multiply(dir, tunneler_depth))
	end

	if dir.z ~= 0 then
		minp.x = minp.x + -1
		maxp.x = maxp.x + 1

		minp.y = minp.y + -1
		maxp.y = maxp.y + 1
	end

	if dir.y ~= 0 then
		minp.z = minp.z + -1
		maxp.z = maxp.z + 1

		minp.x = minp.x + -1
		maxp.x = maxp.x + 1
	end

	if dir.x ~= 0 then
		minp.z = minp.z + -1
		maxp.z = maxp.z + 1

		minp.y = minp.y + -1
		maxp.y = maxp.y + 1
	end

	-- Set the nodes
	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(minp, maxp)
	local area = VoxelArea:new{MinEdge=e1, MaxEdge=e2}

	local data = manip:get_data()

	local c_air = minetest.get_content_id("air")
	local c_tunnel = minetest.get_content_id("magicalities:tunnel_node")
	local dtree = {}
	local abort = false

	for i in area:iterp(minp, maxp) do
		if data[i] ~= c_air then
			dtree[i] = data[i]
			data[i] = c_tunnel
		elseif data[i] == c_tunnel then
			abort = true
			break
		end
	end

	if abort then return end

	-- Set nodes in map
	manip:set_data(data)
	manip:write_to_map()

	-- Save in cache
	local cnum = math.random(10, 1000)
	local comp1 = math.random(10, 1000)
	local comp2 = math.random(10, 1000)
	cnum = (math.ceil(comp2 + comp1 / cnum) + cnum)

	tunneler_memory['t' .. cnum] = {
		data  = dtree,
		minp  = minp,
		maxp  = maxp,
		owner = owner,
	}

	minetest.after(10, reset_tunnel, cnum)
end

minetest.register_node("magicalities:tunnel_node", {
	groups    = {not_in_creative_inventory = 1},
	walkable  = false,
	pointable = false,
	diggable  = false,
	drawtype  = "glasslike_framed",
	paramtype = "light",
	sunlight_propagates = true,
	tiles     = {"magicalities_void.png"},
})

minetest.register_craftitem("magicalities:focus_tunnel", {
	description = "Wand Focus of Tunneling",
	groups = {wand_focus = 1},
	inventory_image = "magicalities_focus_tunnel.png",
	stack_max = 1,
	_wand_requirements = {
		["air"] = 1
	},
	_wand_use = function (itemstack, user, pointed_thing)
		if not pointed_thing.above or pointed_thing.type ~= "node" then return itemstack end
		if not user or user:get_player_name() == "" then return itemstack end
		local dir = user:get_look_dir()
		local wm  = minetest.dir_to_wallmounted(dir)
		dir = minetest.wallmounted_to_dir(wm)

		minetest.after(0.1, create_tunnel, pointed_thing.above, dir, user:get_player_name())

		return itemstack
	end
})

minetest.register_on_shutdown(function ()
	for id in pairs(tunneler_memory) do
		reset_tunnel(id)
	end
end)
