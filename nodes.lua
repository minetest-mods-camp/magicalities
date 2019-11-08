
-- Enchanted Wood
minetest.register_node("magicalities:tree_enchanted", {
	description = "Enchanted Tree",
	tiles = {"magicalities_tree_top.png", "magicalities_tree_top.png", "magicalities_table_wood.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
	sounds = default.node_sound_wood_defaults(),

	on_place = minetest.rotate_node
})

-- circumvent a weird issue
local function add_fix(inv, item)
	inv:add_item("main", item)
end

-- Researchable bookshelf
-- Supposed to be a generated node that gives Research Notes
minetest.register_node("magicalities:bookshelf", {
	description = "Wise Bookshelf",
	tiles = {"default_wood.png", "default_wood.png", "default_wood.png",
		"default_wood.png", "default_bookshelf.png", "default_bookshelf.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {choppy = 3, oddly_breakable_by_hand = 2, flammable = 3, not_in_creative_inventory = 1},
	sounds = default.node_sound_wood_defaults(),
	drop = "default:bookshelf",
	on_rightclick = function (pos, node, clicker, itemstack, pointed_thing)
		if not clicker or clicker:get_player_name() == "" then return itemstack end
		local name = clicker:get_player_name()
		local count = math.random(0, 3)

		-- Swap the node with an ordinary bookshelf after inspecting
		node.name = "default:bookshelf"
		minetest.swap_node(pos, node)
		minetest.registered_nodes[node.name].on_construct(pos)

		-- A chance of not getting anything from this bookshelf
		if count == 0 then
			minetest.chat_send_player(name, "This bookshelf did not contain anything interesting.")
			return itemstack
		end

		-- Add some books into the new bookshelf
		local bookinv = minetest.get_meta(pos):get_inventory()
		bookinv:add_item("books", ItemStack("default:book " .. count))

		-- Give player Research Notes
		local item = ItemStack("magicalities:note")
		item:set_count(count)

		local inv = clicker:get_inventory()
		if inv:room_for_item("main", item) then
			minetest.after(0.1, add_fix, inv, item)
		else
			minetest.item_drop(item, clicker, clicker:get_pos())
		end

		minetest.chat_send_player(name, "You have read some of the books in this bookshelf and wrote up some notes.")

		return itemstack
	end
})

local nboxcollsel = {
	type = "fixed",
	fixed = {
		{-0.375, -0.5, 0.1875, -0.1875, -0.375, 0.375}, -- pot-base
		{-0.3125, -0.375, 0.25, -0.25, -0.3125, 0.3125}, -- pot-head
	}
}

local nbox = {
	type = "fixed",
	fixed = {
		{-0.375, -0.5, 0.1875, -0.1875, -0.375, 0.375}, -- pot-base
		{-0.3125, -0.375, 0.25, -0.25, -0.3125, 0.3125}, -- pot-head
		{-0.28125, -0.3125, 0.125, -0.28125, 0.1875, 0.4375}, -- feather
		{-0.5, -0.5, -0.5, 0.5, -0.5, 0.5}, -- paper-base
	}
}

minetest.register_node("magicalities:quill", {
	description = "Quill",
	tiles = {
		"magicalities_quill_top.png",
		"magicalities_quill_top.png^[transformFY",
		"magicalities_quill_right.png",
		"magicalities_quill_right.png^[transformFX",
		"magicalities_quill_front.png^[transformFX",
		"magicalities_quill_front.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	is_ground_content = false,
	node_box = nbox,
	selection_box = nboxcollsel,
	collision_box = nboxcollsel,
	groups = { not_in_creative_inventory = 1 },
})

minetest.register_node("magicalities:quill_research", {
	tiles = {
		"magicalities_quill_top_research.png",
		"magicalities_quill_top.png^[transformFY",
		"magicalities_quill_right.png",
		"magicalities_quill_right.png^[transformFX",
		"magicalities_quill_front.png^[transformFX",
		"magicalities_quill_front.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	is_ground_content = false,
	drop = "magicalities:quill",
	node_box = nbox,
	selection_box = nboxcollsel,
	collision_box = nboxcollsel,
	groups = { not_in_creative_inventory = 1 },
})
