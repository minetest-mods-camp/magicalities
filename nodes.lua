
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
