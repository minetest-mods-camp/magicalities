-- Magicalities Wands

magicalities.wands = {}

-- This is a method of picking up crystals without breaking them into shards and preserving all of their elements.
-- Surround a crystal in a 3x3 thing of glass, except for the top layer, which has to be wood slabs.
-- When the structure is complete, hit any node of glass with the wand.
-- Views from the side:
--        (middle)
--   sss    sss    sss
--   ggg    gxg    ggg
--   ggg    ggg    ggg
-- s: stairs:slab_wood, g: default:glass, x: group:crystal_cluster
local function pickup_jarred(itemstack, user, glassp)
	local node = minetest.get_node_or_nil(glassp)
	if not node or node.name ~= "default:glass" then return nil end
	local closest = minetest.find_node_near(glassp, 1, "group:crystal_cluster")
	if not closest then return nil end
	if minetest.is_protected(closest, user:get_player_name()) then return nil end
	local cap = minetest.find_nodes_in_area(
		vector.add(closest, {x = -1, y = 1, z = -1}),
		vector.add(closest, {x = 1, y = 1, z = 1}), {"stairs:slab_wood"})
	if #cap ~= 9 then return nil end
	local glass = minetest.find_nodes_in_area(
		vector.add(closest, {x = -1, y = 0, z = -1}),
		vector.add(closest, {x = 1, y = -1, z = 1}), {"default:glass", "group:crystal_cluster"})
	if #glass ~= 18 then return nil end
	local node = minetest.get_node(closest)
	local item = ItemStack(node.name)
	local nmeta = minetest.get_meta(closest)
	local imeta = item:get_meta()

	local contents = nmeta:get_string("contents")
	if contents ~= "" then
		local def = minetest.registered_items[node.name]
		imeta:set_string("description", def.description .. "\n" ..
			minetest.colorize("#a070e0", "Contains elements!"))
		imeta:set_string("contents", contents)
	end

	for _,p in pairs(cap) do
		minetest.set_node(p, { name = "air" })
	end

	for _,p in pairs(glass) do
		minetest.set_node(p, { name = "air" })
	end

	minetest.add_item(closest, item)

	return itemstack
end

magicalities.wands.transform_recipes = {
	["group:enchanted_table"] = {result = "magicalities:arcane_table", requirements = nil},
	["default:bookshelf"]     = {result = "magicalities:book", requirements = nil, drop = true},
	["default:glass"]         = {result = pickup_jarred, requirements = nil, learn = "magicalities:pickup_jarred"},
	["group:tree"]            = {result = "magicalities:tree_enchanted", requirements = nil},
}

local wandcaps = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {},
	damage_groups = {fleshy = 2},
}

local function align(len)
	local str = ""
	for i = 1, len do
		str = str.."\t"
	end
	return str
end

function magicalities.wands.get_wand_focus(stack)
	local meta = stack:get_meta()
	if meta:get_string("focus") == "" then
		return nil
	end

	local focus   = meta:get_string("focus")
	local itemdef = minetest.registered_items[focus]
	if not itemdef then return nil end

	return focus, itemdef
end

function magicalities.wands.get_wand_owner(stack)
	local meta = stack:get_meta()
	return meta:get_string("player")
end

local function focus_requirements(stack, fdef)
	if fdef["_wand_requirements"] then
		return magicalities.wands.wand_has_contents(stack, fdef["_wand_requirements"])
	end
	
	return true
end

local function focuses_formspec(available, focusname)
	local x   = 0
	local fsp = ""
	for focus in pairs(available) do
		if x < 5 then
			fsp = fsp .. "item_image_button["..x..",2.8;1,1;"..focus..";"..focus..";]"
			x = x + 1
		end
	end

	local current = ""
	if not focusname then
		current = "label[2,1;No Focus]"
	else
		current = "item_image_button[2,0.5;1,1;"..focusname..";remove;Remove]"..
				  "label[0,1.5;Current: "..minetest.registered_items[focusname].description.."]"
	end

	return "size[5,3.5]"..
		default.gui_bg..
		default.gui_bg_img..
		"label[0,0;Wand Focuses]"..
		current..
		"label[0,2.4;Available]"..
		fsp
end

-- Update wand's description
function magicalities.wands.update_wand_desc(stack)
	local meta = stack:get_meta()
	local data_table = minetest.deserialize(meta:get_string("contents"))
	if not data_table then data_table = {} end

	local focus, fdef = magicalities.wands.get_wand_focus(stack)

	local wanddata    = minetest.registered_items[stack:get_name()]
	local description = wanddata.description
	local capcontents = wanddata["_cap_max"] or 15
	local strbld      = description.."\n\n"

	local elems = {}
	for elem, amount in pairs(data_table) do
		local dataelem = magicalities.elements[elem]
		local visual = amount
		if amount < 10 then visual = "0" .. amount end
		if amount == 0 then visual = minetest.colorize("#ff0505", visual) end
		local str = "["..visual.."/"..capcontents.."] "
		str = str .. minetest.colorize(dataelem.color, dataelem.description)
		if focus and fdef and fdef['_wand_requirements'] and fdef['_wand_requirements'][elem] ~= nil then
			elems[#elems + 1] = str .. minetest.colorize("#a070e0", " ("..fdef['_wand_requirements'][elem]..") ")
		elseif amount ~= 0 then
			elems[#elems + 1] = str
		end
	end

	local focusstr = "No Wand Focus"
	if focus then
		focusstr = fdef.description
	end

	strbld = strbld .. minetest.colorize("#a070e0", focusstr) .. "\n"
	if #elems > 0 then
		table.sort(elems)
		strbld = strbld .. "\n" .. table.concat(elems, "\n")
	end

	local owner = meta:get_string("player")
	if owner ~= "" then
		strbld = strbld .. "\n" .. minetest.colorize("#d33b57", string.format("Soulbound to %s", owner))
	end

	meta:set_string("description", strbld)
end

-- Ensure wand has contents
function magicalities.wands.wand_has_contents(stack, requirements)
	local meta = stack:get_meta()
	local data_table = minetest.deserialize(meta:get_string("contents"))
	
	if not data_table then return false end

	for name, count in pairs(requirements) do
		if not data_table[name] or data_table[name] < count then
			return false
		end
	end
	
	return true
end

-- Take wand contents
function magicalities.wands.wand_take_contents(stack, to_take)
	local meta = stack:get_meta()
	local data_table = minetest.deserialize(meta:get_string("contents"))

	for name, count in pairs(to_take) do
		if not data_table[name] or data_table[name] - count < 0 then
			return stack
		end

		data_table[name] = data_table[name] - count
	end
	
	local data_res = minetest.serialize(data_table)
	meta:set_string("contents", data_res)

	return stack
end

-- Add wand contents
function magicalities.wands.wand_insert_contents(stack, to_put)
	local meta = stack:get_meta()
	local data_table = minetest.deserialize(meta:get_string("contents"))
	local cap = minetest.registered_items[stack:get_name()]["_cap_max"]
	local leftover = {}

	for name, count in pairs(to_put) do
		if data_table[name] then
			if data_table[name] + count > cap then
				data_table[name] = cap
				leftover[name] = (data_table[name] + count) - cap
			else
				data_table[name] = data_table[name] + count
			end
		end
	end
	
	local data_res = minetest.serialize(data_table)
	meta:set_string("contents", data_res)

	return stack, leftover
end

-- Can add wand contents
function magicalities.wands.wand_insertable_contents(stack, to_put)
	local meta = stack:get_meta()
	local data_table = minetest.deserialize(meta:get_string("contents"))
	local cap = minetest.registered_items[stack:get_name()]["_cap_max"]
	local insertable = {}

	for name, count in pairs(to_put) do
		if data_table[name] then
			if data_table[name] + count <= cap then
				insertable[name] = count
			elseif cap - data_table[name] > 0 then
				insertable[name] = cap - data_table[name]
			end
		end
	end

	return insertable
end

-- Initialize wand metadata
local function initialize_wand(stack, player)
	local data_table = {}

	for name, data in pairs(magicalities.elements) do
		if not data.inheritance then
			data_table[name] = 0
		end
	end

	local meta = stack:get_meta()
	meta:set_string("player", player)
	meta:set_string("contents", minetest.serialize(data_table))
end

local function wand_action(itemstack, placer, pointed_thing)
	if not pointed_thing.type == "node" then return itemstack end
	local pos = pointed_thing.under
	local node = minetest.get_node(pointed_thing.under)
	local imeta = itemstack:get_meta()

	-- Initialize wand metadata
	if imeta:get_string("contents") == nil or imeta:get_string("contents") == "" then
		initialize_wand(itemstack, placer:get_player_name())
		magicalities.wands.update_wand_desc(itemstack)
	end

	-- Call rightclick on the wand focus
	local focus, fdef = magicalities.wands.get_wand_focus(itemstack)
	if focus then
		if fdef["_wand_node"] and focus_requirements(itemstack, fdef) then
			itemstack = fdef["_wand_node"](pos, node, placer, itemstack, pointed_thing)

			return itemstack
		end
	end

	-- Call on_rightclick on the node
	local nodedef = minetest.registered_nodes[node.name]
	if nodedef.on_rightclick then
		itemstack = nodedef.on_rightclick(pos, node, placer, itemstack, pointed_thing)
	end

	return itemstack
end

local function use_wand(itemstack, user, pointed_thing)
	local imeta = itemstack:get_meta()
	local pname = user:get_player_name()

	-- Initialize wand metadata
	if imeta:get_string("contents") == "" then
		initialize_wand(itemstack, pname)
		magicalities.wands.update_wand_desc(itemstack)
	end

	-- Call use on the wand focus
	local focus, fdef = magicalities.wands.get_wand_focus(itemstack)
	if focus then
		if fdef["_wand_use"] and focus_requirements(itemstack, fdef) then
			itemstack = fdef["_wand_use"](itemstack, user, pointed_thing)

			return itemstack
		end
	end

	if pointed_thing.type ~= "node" then
		magicalities.wands.update_wand_desc(itemstack)
		return itemstack
	end

	local pos = pointed_thing.under
	local node = minetest.get_node_or_nil(pos)

	if not node or node.name == "air" or minetest.is_protected(pos, pname) then
		minetest.record_protection_violation(pos, pname)
		magicalities.wands.update_wand_desc(itemstack)
		return itemstack
	end

	-- Replacement
	local to_replace = nil
	for name, result in pairs(magicalities.wands.transform_recipes) do
		if name:match("group:") ~= nil and
			minetest.get_item_group(node.name, string.gsub(name, "group:", "")) > 0 then
			to_replace = result
			break
		elseif name == node.name then
			to_replace = result
			break
		end
	end

	-- Make sure player has this replacement ability
	if to_replace and to_replace.learn and not magicalities.player_has_ability(magicalities.wands.get_wand_owner(itemstack), to_replace.learn) then
		to_replace = nil
	end

	-- Make sure we can "dig" the node before we, potentially, remove it from the world
	if to_replace then
		local ndef = minetest.registered_items[node.name]
		if ndef.can_dig and not ndef.can_dig(pos, user) then
			to_replace = nil
		end
	end

	-- Commit action
	if to_replace then
		local take_req = true

		if type(to_replace.result) == "function" then
			local t = to_replace.result(itemstack, user, pos)
			if not t then
				take_req = false
			else
				itemstack = t
			end
		elseif to_replace.drop then
			local istack = ItemStack(to_replace.result)
			local istackdef = minetest.registered_items[to_replace.result]
			if istackdef._wand_created then
				istack = istackdef._wand_created(istack, itemstack, user, pos)
			end
			minetest.add_item(pos, istack)
			minetest.set_node(pos, {name = "air"})
		else
			minetest.set_node(pos, {name = to_replace.result, param1 = node.param1, param2 = node.param2})
			local spec = minetest.registered_nodes[to_replace.result]
			if spec.on_construct then
				spec.on_construct(pos)
			end
		end

		if take_req and to_replace.requirements then
			if not magicalities.wands.wand_has_contents(itemstack, to_replace.requirements) then
				return itemstack
			end
			itemstack = magicalities.wands.wand_take_contents(itemstack, to_replace.requirements)
		end

		magicalities.wands.update_wand_desc(itemstack)
		return itemstack
	end

	-- Call _wand_use on the node, if it has the callback registered
	local ndef = minetest.registered_nodes[node.name]
	if ndef['_wand_use'] then
		return ndef['_wand_use'](pos, node, itemstack, user, pointed_thing)
	end

	magicalities.wands.update_wand_desc(itemstack)
	return itemstack
end

local function wand_focuses(itemstack, user, pointed_thing)
	local focuses_found = {}
	local inv  = user:get_inventory()
	local list = inv:get_list("main")

	local focusname, focusdef = magicalities.wands.get_wand_focus(itemstack)
	local meta = itemstack:get_meta()

	for _, stack in pairs(list) do
		if minetest.get_item_group(stack:get_name(), "wand_focus") > 0 then
			focuses_found[stack:get_name()] = true
		end
	end

	minetest.show_formspec(user:get_player_name(), "magicalities:wand_focuses", focuses_formspec(focuses_found, focusname))
	minetest.register_on_player_receive_fields(function (player, formname, fields)
		if formname ~= "magicalities:wand_focuses" then
			return false
		end

		-- Make sure field is a valid item
		local f = ""
		if not fields["quit"] then
			if fields["remove"] then
				f = nil
			else
				for v in pairs(fields) do
					if minetest.registered_items[v] then
						f = v
						break
					end
				end
			end
		else
			return true
		end

		local was

		was = meta:get_string("focus")
		if was == "" and not f then
			return true
		elseif was ~= "" then
			was = ItemStack(was)
			if not inv:room_for_item("main", was) then
				return true
			end
		end

		minetest.close_formspec(player:get_player_name(), "magicalities:wand_focuses")

		local removed_focus = false
		local set = false

		-- Update itemstack
		for i, stack in pairs(list) do
			if set and (removed_focus or not f) then break end
			if not removed_focus and stack:get_name() == f then
				inv:set_stack("main", i, ItemStack(nil))
				removed_focus = true -- Make sure to only remove one
			end
			
			if stack:get_name() == itemstack:get_name() and stack:get_meta() == itemstack:get_meta() and not set then
				if not f then
					meta:set_string("focus", "")
					magicalities.wands.update_wand_desc(itemstack)
				elseif f ~= "" then
					meta:set_string("focus", f)
					magicalities.wands.update_wand_desc(itemstack)
				end

				inv:set_stack("main", i, itemstack)
				set = true
			end
		end

		-- Give the removed focus back
		if was then
			inv:add_item("main", was)
		end

		return true
	end)

	return itemstack
end

function magicalities.wands.register_wand(name, data)
	local mod = minetest.get_current_modname()
	minetest.register_tool(mod..":wand_"..name, {
		description = data.description,
		inventory_image = data.image,
		tool_capabilities = wandcaps,
		stack_max = 1,
		_cap_max = data.wand_cap,
		on_use = use_wand,
		on_place = wand_action,
		on_secondary_use = wand_focuses,
		groups = {wand = 1}
	})
end
