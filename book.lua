
minetest.register_craftitem("magicalities:book", {
	description = "Magicalities' Guide for Witches and Wizards",
	inventory_image = "magicalities_book.png",
	on_place = function (itemstack, user, pointed_thing)
		return itemstack
	end
})