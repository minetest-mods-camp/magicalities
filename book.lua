
local page_cache = {}
local recipe_cache = {}
local group_cache = {}

local function resolve_group(group)
	if group_cache[group] then return group_cache[group] end
	local remove_group = group:sub(7)
	local found
	for v in pairs(minetest.registered_items) do
		if minetest.get_item_group(v, remove_group) > 0 then
			found = v
			break
		end
	end
	if not found then return "" end
	group_cache[group] = found
	return found
end

local function fromtable_output(tbl, out)
	local res
	for _,v in pairs(tbl) do
		if v.output == out then
			res = v
			break
		end
	end
	return res
end

local function generate_recipe_hypertext(item, recipe_type)
	if recipe_cache[recipe_type .. "/" .. item] then return recipe_cache[recipe_type .. "/" .. item] end

	local lines = {}

	if recipe_type == 'cauldron' then
		local x = fromtable_output(magicalities.cauldron.recipes, item)
		if not x then return "" end
		local rec = x.requirements
		local y = {}

		for _,v in pairs(x.items) do
			table.insert(y, "<item name=\""..v.."\" width=64 height=64>")
		end

		table.insert(lines, "<center>" .. table.concat(y, "<img name=magicalities_book_plus.png width=64 height=64>") .. "</center>")
		table.insert(lines, "<center><img name=gui_furnace_arrow_bg.png^\\[transformFY width=64 height=64></center>")
		table.insert(lines, "<center><item name=\"magicalities:cauldron_with_water\" width=64 height=64><img name=magicalities_book_plus.png width=64 height=64><item name=\"magicalities:wand_steel\" width=64 height=64></center>")

		if rec then
			local p = {}
			for rec,v in pairs(rec) do
				table.insert(p, v .. " " .. magicalities.elements[rec].description)
			end
			table.insert(lines, "<center><big>" .. table.concat(p, " | ") .. "</big></center>")
		end
	end

	if #lines > 0 then
		local ht = table.concat(lines, "\n")
		recipe_cache[recipe_type .. "/" .. item] = ht
		return ht
	end
end

local function line_special (line)
	local types = {"cauldron"}
	local matched = false

	for _,v in pairs(types) do
		matched = line:match("^<"..v) ~= nil
		if matched then break end
	end

	if not matched then return line end
	local tyt = line:match("^<([%w]*)")
	local itm = line:match("name=([^>]*)")
	if not tyt or not itm then return "" end
	return generate_recipe_hypertext(itm, tyt)
end

local function book_formspec(user, page, scrollindex)
	if page then
		return "size[8,8]"..
			"button[0,0;2,1;back;Back to index]"..
			"hypertext[0.1,0.5;7.9,7.5;text;"..page_cache[page].."]"..
			default.gui_bg..
			default.gui_bg_img..
			default.gui_slots
	end

	local avail_list = magicalities.available_to_player(user, true)
	return "size[6,5.7]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		magicalities.researching.generate_formspec_list(avail_list, 0, 0, 5, 5.25, scrollindex, false, true)
end

local function first_key(list)
	local ekey
	for key,_ in pairs(list) do
		ekey = key
		break
	end
	return ekey
end

local function book_read_page(book, user, page, ptype)
	local uname = user:get_player_name()
	local check = magicalities.player_has_ability
	if ptype == 2 then
		check = magicalities.player_has_recipe
	end

	if not check(uname, page) then return false end

	local chapter = "#"..ptype..""..page
	if not page_cache[chapter] then
		return false
	end

	minetest.show_formspec(uname, "magicalities:book", book_formspec(uname, chapter, 0))
	return true
end

local function book_read(book, user, pointed_thing)
	local uname = user:get_player_name()
	if pointed_thing and pointed_thing.type == "node" then
		local pos = pointed_thing.under
		local node = minetest.get_node(pos)
		local ptype = 2
		local page = node.name

		-- Special case for crystals
		if minetest.get_item_group(node.name, "crystal_cluster") > 0 then
			ptype = 1
			page = "magicalities:crystal"
		end

		-- Open a page instead
		if page_cache["#"..ptype..""..page] then
			local read = book_read_page(book, user, page, ptype)
			if read then
				return book
			end
		end
	end

	local meta = book:get_meta()
	minetest.show_formspec(uname, "magicalities:book", book_formspec(uname, nil, meta:get_int("scrolli")))
	return book
end

local function cache_book_pages()
	recipe_cache = {}
	local file = io.open(minetest.get_modpath("magicalities").."/book.txt")
	local all = {}
	local previous = ""
	local since = 0

	for line in file:lines() do
		if line:sub(0,1) == "#" then
			all[line] = ""
			previous = line
			since = 0
		elseif previous ~= "" then
			line = line_special(line)
			if since > 0 then
				line = '\n'..line
			end
			all[previous] = all[previous] .. line
			since = since + 1
		end
	end

	page_cache = all
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "magicalities:book" then return false end

	local book = player:get_wielded_item()
	if book:get_name() ~= "magicalities:book" then return true end

	local bmeta = book:get_meta()

	local scrolled = false
	local findex = bmeta:get_int("scrolli")

	local page
	local page_type

	local fkey = first_key(fields)
	if fields["text"] and fields["text"]:sub(0,6) == "action" then
		local pact = fields["text"]:sub(8):gsub("\"", "")
		if pact then
			fkey = pact
		end
	end

	if fields["dn"] then
		scrolled = true
		findex = findex + 1
	elseif fields["up"] then
		scrolled = true
		findex = findex - 1
		if findex < 0 then
			findex = 0
		end
	elseif fkey and fkey:sub(0,1) == "#" then
		page_type = tonumber(fkey:sub(2,2))
		page = fkey:sub(3)
	elseif fields["back"] then
		book_read(book, player)
		return true
	end

	if scrolled then
		bmeta:set_int("scrolli", findex)
		player:set_wielded_item(book)
		book_read(book, player)

		return true
	end

	if not page or not page_type then return true end
	-- Handle page
	--print("Open page on topic " .. page .. ", which is of type " .. page_type)
	book_read_page(book, player, page, page_type)

	return true
end)

local mgww = "Magicalities' Guide for Witches and Wizards"
minetest.register_craftitem("magicalities:book", {
	description = mgww,
	inventory_image = "magicalities_book.png",
	on_use = book_read,
	on_place = book_read,
	on_secondary_use = book_read,
	_wand_created = function (itemstack, wand, user, pos)
		local meta = itemstack:get_meta()
		local name = user:get_player_name()
		meta:set_string("player", name)
		meta:set_string("description", mgww .. "\n" ..
			minetest.colorize("#d33b57", string.format("Soulbound to %s", name)))
		return itemstack
	end,
	stack_max = 1
})

minetest.register_chatcommand("mgcbookcache", {
	privs = {basic_privs = 1},
	func = function ()
		cache_book_pages()
		return true, "Reloaded book cache successfully."
	end
})

local initial = true
minetest.register_on_joinplayer(function ()
	if not initial then return end
	initial = false
	cache_book_pages()
end)
