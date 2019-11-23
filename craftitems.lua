
local function grant_research(itemstack, placer, pointed_thing)
	if not placer or placer:get_player_name() == "" then return itemstack end
	local name = placer:get_player_name()
	local points = math.random(0, 10)

	if points == 0 then
		minetest.chat_send_player(name, "This Research Note did not contain anything interesting.")
	else
		magicalities.deal_research_points(name, points)
		minetest.chat_send_player(name, "This Research Note has granted you some knowledge about magic!")
	end

	if not (creative and creative.is_enabled_for and creative.is_enabled_for(name)) then
		itemstack:take_item(1)
	end

	return itemstack
end

local function learn_research(paper, player)
	local name = player:get_player_name()
	local meta = paper:get_meta()
	local t = meta:get_int("type")
	local l = meta:get_string("learn")
	if l ~= "" and t ~= 0 then
		magicalities.player_learn(name, l, t == 2)
		paper:take_item(1)
	end
	return paper
end

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

minetest.register_craftitem("magicalities:cap_tellium", {
	description = "Tellium Wand Cap",
	inventory_image = "magicalities_cap_tellium.png"
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
	description = "Transterra\nThis substance can change the world!",
	inventory_image = "magicalities_red_stone.png",
	groups = {shard = 1, transterra = 1}
})

minetest.register_craftitem("magicalities:note", {
	description = "Research Note\nRight-Click to read and learn!",
	inventory_image = "magicalities_note.png",
	groups = {note = 1},
	on_place = grant_research,
	on_secondary_use = grant_research
})

minetest.register_craftitem("magicalities:research", {
	description = minetest.colorize("#007bff", "Research Paper") .. "\nIncomplete.",
	inventory_image = "magicalities_research.png",
	groups = {note = 1, not_in_creative_inventory = 1},
	stack_max = 1
})

minetest.register_craftitem("magicalities:research_complete", {
	description = minetest.colorize("#f600ff", "Research Paper (Completed)") .. "\nRight-Click to read and learn!",
	inventory_image = "magicalities_research_complete.png",
	groups = {note = 1, not_in_creative_inventory = 1},
	stack_max = 1,
	on_place = learn_research,
	on_secondary_use = learn_research
})

minetest.register_tool("magicalities:ink_and_quill", {
	description = "Ink and Quill",
	inventory_image = "magicalities_quill.png"
})
