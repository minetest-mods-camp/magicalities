
local page_cache = {}

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

	if not check(uname, page) then return book end

	local chapter = "#"..ptype..""..page
	if not page_cache[chapter] then
		return
	end

	minetest.show_formspec(uname, "magicalities:book", book_formspec(uname, chapter, 0))
end

local function book_read(book, user, pointed_thing)
	local uname = user:get_player_name()
	local meta = book:get_meta()
	minetest.show_formspec(uname, "magicalities:book", book_formspec(uname, nil, meta:get_int("scrolli")))
	return book
end

local function cache_book_pages()
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

minetest.register_chatcommand("mgcbookcache", {
	privs = {basic_privs = 1},
	func = function ()
		cache_book_pages()
		return true, "Reloaded book cache successfully."
	end
})

cache_book_pages()
