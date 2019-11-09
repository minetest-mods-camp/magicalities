
magicalities.researching = {}

function magicalities.researching.generate_formspec_list(list, x, y, w, h, index, canlearn, canopen)
	local i = ""
	if #list == 0 then return "" end
	local ty = 0
	local total = #list
	local visualtotal = math.ceil(y + h)
	local reallist = {}
	local pages = math.ceil(total / visualtotal)

	for i = index * visualtotal, (index * visualtotal) + visualtotal do
		if list[i + 1] then
			table.insert(reallist, list[i + 1])
		end
	end

	for _,v in pairs(reallist) do
		if ty + 1 > visualtotal then break end
		local icon = ""
		local t = 1
		if v.type == "recipe" then t = 2 end

		if canopen then
			i = i .. "button["..x..","..(y+ty)..";"..w..",1;#"..t..""..v.name..";]"
		end

		if v.icon ~= nil then
			icon = "image["..x..","..(y+ty)..";1,1;"..v.icon.."]"
		elseif v.type == "recipe" then
			icon = "item_image["..x..","..(y+ty)..";1,1;"..v.name.."]"
		end

		i = i .. icon .. "label["..(x + 1)..","..(y+ty)..";"..v.description.."]"
		if canlearn then
			i = i .. "button["..(x+w-1)..","..(y+ty)..";1,1;@"..t..""..v.name..";Learn]"
		end
		ty = ty + 1
	end

	if index > 0 then
		i = i .. "button["..(x+w)..","..y..";1,1;up;Up]"
	end

	if pages > index + 1 then
		i = i .. "button["..(x+w)..","..(y+ty-1)..";1,1;dn;Down]"
	end

	return i
end

local function table_formspec(player, research, index, canlearn)
	local list = {}

	if player then
		list = magicalities.available_to_player(player, false, true)
	end

	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"image[0.5,0.5;1,1;magicalities_gui_book_slot.png]"..
		"list[context;book;0.5,0.5;1,1;]"..
		"image[0.5,1.5;1,1;magicalities_gui_quill_slot.png]"..
		"list[context;tools;0.5,1.5;1,1;]"..
		"image[0.5,2.5;1,1;magicalities_gui_paper_slot.png]"..
		"list[context;paper;0.5,2.5;3,3;]"..
		magicalities.researching.generate_formspec_list(list, 1.5, 0.5, 5.5, 2, index, canlearn)..
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

local function allow_metadata_inventory_put (pos, listname, index, stack, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
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

local function update_table_formspec(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local learnable = not inv:get_stack("tools", 1):is_empty()

	if inv:get_stack("book", 1):is_empty() then
		meta:set_int("scrolli", 0)
		meta:set_string("formspec", table_formspec())
	else
		local paper = inv:get_stack("paper", 1)
		local bmeta = inv:get_stack("book", 1):get_meta()
		local iplayer = bmeta:get_string("player")
		local current_research = ""
		local current_research_type = 0

		if not paper:is_empty() then
			if paper:get_name() ~= "default:paper" then
				learnable = false
			end
			local pmeta = paper:get_meta()
			current_research = pmeta:get_string("learn")
			current_research_type = pmeta:get_int("type")
		else
			learnable = false
		end

		if learnable and magicalities.player_research(iplayer) < 10 then
			learnable = false
		end

		meta:set_string("formspec", table_formspec(iplayer, current_research, meta:get_int("scrolli"), learnable))
	end
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

	update_table_formspec(pos)
end

local function damage_tools(tools)
	local wear = tools:get_wear()
	local percent = math.floor(65535 * 0.25)
	if wear == 0 then
		wear = 65535 - (65535 - percent)
	else
		wear = wear + percent
	end

	if wear <= 65535 and wear >= 0 then
		tools:set_wear(wear)
	else
		return nil
	end

	return tools
end

local function process_learn(pos, ltype, learn, pts, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if inv:get_stack("book", 1):is_empty() or inv:get_stack("tools", 1):is_empty() or inv:get_stack("paper", 1):is_empty() then
		return
	end

	local bookm = inv:get_stack("book", 1):get_meta()
	local player = bookm:get_string("player")

	if player == "" then return end
	if inv:get_stack("paper", 1):get_name() ~= "default:paper" then return end

	-- Commit learn
	magicalities.deal_research_points(player, -pts)
	local istack = ItemStack("magicalities:research_complete")
	local istackmeta = istack:get_meta()
	istackmeta:set_int("type", ltype)
	istackmeta:set_string("learn", learn)
	local itool = damage_tools(inv:get_stack("tools", 1))
	inv:set_stack("tools", 1, itool)
	if not itool then
		table_inventory_changed(pos, "tools", 1, ItemStack(itool), player)
	end
	inv:set_stack("paper", 1, istack)
end

local function first_key(list)
	local ekey
	for key,_ in pairs(list) do
		ekey = key
		break
	end
	return ekey
end

local function table_fields(pos, formname, fields, sender)
	local meta = minetest.get_meta(pos)
	local findex = meta:get_int("scrolli")
	local scrolled = false
	local learn_type
	local learn
	local fkey = first_key(fields)

	if fields["dn"] then
		scrolled = true
		findex = findex + 1
	elseif fields["up"] then
		scrolled = true
		findex = findex - 1
		if findex < 0 then
			findex = 0
		end
	elseif fkey and fkey:sub(0,1) == "@" then
		learn_type = tonumber(fkey:sub(2,2))
		learn = fkey:sub(3)
	end

	if scrolled then
		meta:set_int("scrolli", findex)
	end

	if learn and learn_type then
		process_learn(pos, learn_type, learn, 10, sender)
	end

	update_table_formspec(pos)
end

local function table_use(pos, node, clicker, itemstack, pointed_thing)
	update_table_formspec(pos)
	return itemstack
end

-- Base Table Override
minetest.override_item("magicalities:table", {
	description = "Research Table",
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
	on_receive_fields = table_fields,
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
