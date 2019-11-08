local nostructures = minetest.settings:get_bool("mgc_skip_structures", false)

if not nostructures then
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = "default:dirt_with_grass",
		y_min = 0,
		y_max = 31000,
		flags = "force_placement, all_floors",
		schematic = "schems/magicalities_booktower.mts",
		rotation = "random",
		place_offset_y = 0,
		-- what noise_params should i use instead of this?
		fill_ratio = 0.00000001,
	})
end
