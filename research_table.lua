
magicalities.researching = {}

local function table_formspec()
	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"image[0.5,0.5;1,1;magicalities_gui_book_slot.png]"..
		"list[context;book;0.5,0.5;1,1;]"..
		"image[1.5,0.5;1,1;magicalities_gui_quill_slot.png]"..
		"list[context;tools;1.5,0.5;1,1;]"..
		"image[2.5,0.5;1,1;magicalities_gui_paper_slot.png]"..
		"list[context;paper;2.5,0.5;3,3;]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[current_player;main]"..
		"listring[context;book]"..
		"listring[current_player;main]"..
		"listring[context;paper]"..
		"listring[current_player;main]"..
		"listring[context;tools]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

local function table_use(pos, node, clicker, itemstack, pointed_thing)
	return itemstack
end

local function allow_metadata_inventory_put (pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	if (listname == "book" and stack:get_name() ~= "magicalities:book") or 
		(listname == "paper" and stack:get_name() ~= "magicalities:research" and stack:get_name() ~= "default:paper") or 
		(listname == "tools" and stack:get_name() ~= "magicalities:ink_and_quill") then
		return 0
	end

	return 1
end

local function allow_metadata_inventory_move (pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)

	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take (pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function table_inventory_changed (pos, listname, index, stack, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	local vec = vector.add(pos,{x=0,y=1,z=0})
	local node = minetest.get_node_or_nil(vec)
	if inv:get_stack("tools", 1):is_empty() then
		if node and (node.name == "magicalities:quill" or node.name == "magicalities:quill_research") then
			minetest.set_node(vec, {name="air"})
		end
	elseif node then
		local dir = minetest.dir_to_facedir(vector.normalize(vector.subtract(pos, player:get_pos())), false)
		local ver = "magicalities:quill"
		if not inv:get_stack("paper", 1):is_empty() then
			ver = "magicalities:quill_research"
		end
		minetest.set_node(vec, {name=ver,param2=dir})
	end
end

-- Base Table Override
minetest.override_item("magicalities:table", {
	on_construct = function (pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("book", 1)
		inv:set_size("tools", 1)
		inv:set_size("paper", 1)

		meta:set_string("formspec", table_formspec())
	end,
	on_destruct = function (pos)
		local vec = vector.add(pos,{x=0,y=1,z=0})
		local node = minetest.get_node_or_nil(vec)
		if node and node.name == "magicalities:quill" then
			minetest.set_node(vec, {name="air"})
		end
	end,
	on_rightclick = table_use,
	can_dig = function (pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:get_stack("book", 1):is_empty() and inv:get_stack("paper", 1):is_empty() and inv:get_stack("tools", 1):is_empty()
	end,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	on_metadata_inventory_take = table_inventory_changed,
	on_metadata_inventory_put = table_inventory_changed,
	on_metadata_inventory_move = table_inventory_changed,
})

-- Remove floating quills
minetest.register_lbm({
	label = "Remove floating quills",
	name = "magicalities:quill_cleanup",
	nodenames = {"magicalities:quill", "magicalities:quill_research"},
	run_at_every_load = true,
	action = function(pos, node)
		local vecunder = vector.add(pos,{x=0,y=-1,z=0})
		local nodeunder = minetest.get_node_or_nil(vecunder)
		if not nodeunder or nodeunder.name ~= "magicalities:table" then
			minetest.set_node(pos, {name="air"})
		end
	end,
})
