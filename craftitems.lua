
minetest.register_craftitem("magicalities:wand_core", {
	description = "Wand Core",
	inventory_image = "magicalities_wand_core.png"
})

minetest.register_craftitem("magicalities:cap_steel", {
	description = "Steel Wand Cap",
	inventory_image = "magicalities_cap_iron.png"
})

minetest.register_craftitem("magicalities:cap_gold", {
	description = "Gold Wand Cap",
	inventory_image = "magicalities_cap_gold.png"
})

minetest.register_craftitem("magicalities:focus_blank", {
	description = "Blank Wand Focus",
	inventory_image = "magicalities_focus_base.png",
})

minetest.register_craftitem("magicalities:tellium", {
	description = "Tellium Ingot",
	inventory_image = "magicalities_tellium_ingot.png",
	groups = {ingot = 1, tellium = 1}
})

minetest.register_craftitem("magicalities:transterra", {
	description = "Transterra",
	inventory_image = "magicalities_red_stone.png",
	groups = {shard = 1, transterra = 1}
})

local function grant_research(itemstack, placer, pointed_thing)
	if not placer or placer:get_player_name() == "" then return itemstack end
	local name = placer:get_player_name()
	local points = math.random(1, 10)
	magicalities.deal_research_points(name, points)
	minetest.chat_send_player(name, "This Research Note granted you " .. points .. " Research Points!")
	if not (creative and creative.is_enabled_for and creative.is_enabled_for(name)) then
		itemstack:take_item(1)
	end
	return itemstack
end

minetest.register_craftitem("magicalities:note", {
	description = "Research Note",
	inventory_image = "magicalities_note.png",
	groups = {note = 1},
	on_place = grant_research,
	on_secondary_use = grant_research
})

