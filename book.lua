
local function book_formspec(user)
	local avail_list = magicalities.available_to_player(user, true)
	return "size[5,6]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots
end

local function book_read(itemstack, user, pointed_thing)
	local uname = user:get_player_name()
	minetest.show_formspec(uname, "magicalities:book", book_formspec(uname))
	return itemstack
end

minetest.register_craftitem("magicalities:book", {
	description = "Magicalities' Guide for Witches and Wizards",
	inventory_image = "magicalities_book.png",
	on_place = book_read,
	on_secondary_use = book_read,
	_wand_created = function (itemstack, wand, user, pos)
		itemstack:get_meta():set_string("player", user:get_player_name())
		return itemstack
	end,
	stack_max = 1
})
