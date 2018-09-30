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
