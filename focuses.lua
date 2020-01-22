-- Wand Focuses

local particles = minetest.settings:get_bool("mgc_particles", true)

-- Constants
-- TODO: make settings
magicalities.magic_spray_count = 16
magicalities.elemental_focus_velocity = 16
magicalities.elemental_focus_consumption = 5

-- Teleportation
minetest.register_craftitem("magicalities:focus_teleport", {
	description = "Wand Focus of Teleportation",
	groups = {wand_focus = 1},
	inventory_image = "magicalities_focus_teleport.png",
	stack_max = 1,
	_wand_requirements = {
		["air"] = 1
	},
	_wand_use = function (itemstack, user, pointed_thing)
		local dir  = user:get_look_dir()
		local dest = vector.multiply(dir, 20)
		dest = vector.add(dest, user:get_pos())

		local pos = user:get_pos()
		pos.x = pos.x + (dir.x * 2)
		pos.y = pos.y + (dir.y * 2) + 1.5
		pos.z = pos.z + (dir.z * 2)

		local ray  = Raycast(pos, dest, true, false)
		local targ = ray:next()
		local can_go = targ == nil

		-- Go above node
		if targ and targ.type == "node" then
			local abv = minetest.get_node(targ.above)
			if not abv or abv.name == "air" then
				local add = {x=0,y=0,z=0}
				if user:get_pos().y < targ.above.y - 1.5 then
					add.y = 1.5
				end
				dest = vector.add(targ.above, add)
				can_go = true
			end
		end

		if can_go then
			itemstack = magicalities.wands.wand_take_contents(itemstack, {air = 1})
			magicalities.wands.update_wand_desc(itemstack)
			user:set_pos(dest)
		end

		return itemstack
	end
})

-- Node swapper
minetest.register_craftitem("magicalities:focus_swap", {
	description = "Wand Focus of Swapping",
	groups = {wand_focus = 1},
	inventory_image = "magicalities_focus_swap.png",
	stack_max = 1,
	_wand_requirements = {
		["earth"] = 1
	},
	_wand_use = function (itemstack, user, pointed_thing)
		local meta = itemstack:get_meta()
		local tnode = meta:get_string("swapnode")
		local pname = user:get_player_name()
		if tnode == "" or pointed_thing.type ~= "node" then return itemstack end

		local pos = pointed_thing.under

		if minetest.is_protected(pos, pname) then
			minetest.record_protection_violation(pos, pname)
			return itemstack
		end

		local node = minetest.get_node_or_nil(pos)
		if not node or node.name == tnode then
			return itemstack
		end

		local place_node_itm = ItemStack(tnode)
		local inv = user:get_inventory()

		local ndef = minetest.registered_nodes[tnode]
		if not inv:contains_item("main", place_node_itm) then
			minetest.chat_send_player(pname, ("You don't have enough %s in your inventory."):format(ndef.description))
			return itemstack
		end

		local drops = minetest.get_node_drops(node.name)

		if ndef.can_dig ~= nil and not ndef.can_dig(pos, user) then
			return itemstack
		end

		minetest.remove_node(pos)

		itemstack = magicalities.wands.wand_take_contents(itemstack, {earth = 1})
		magicalities.wands.update_wand_desc(itemstack)

		inv:remove_item("main", place_node_itm)

		for _, stk in pairs(drops) do
			if inv:room_for_item("main", stk) then
				inv:add_item("main", stk)
			else
				minetest.item_drop(ItemStack(stk), user, vector.add(pos, {x=0,y=1,z=0}))
			end
		end

		minetest.place_node(pos, {name = tnode})

		return itemstack
	end,
	_wand_node = function (pos, node, placer, itemstack, pointed_thing)
		if not node or node.name == "air" or node.name == "ignore" then return itemstack end
		local meta = itemstack:get_meta()
		local tnode = meta:get_string("swapnode")

		if tnode == node.name then return itemstack end
		meta:set_string("swapnode", node.name)

		local ndef = minetest.registered_nodes[node.name]
		minetest.chat_send_player(placer:get_player_name(), "Selected replacement node " .. ndef.description)

		return itemstack
	end
})

-- Light Source
minetest.register_node("magicalities:light_source", {
	description = "Magical Light Source",
	tiles = {"magicalities_light_source.png"},
	groups = {cracky = 3, not_in_creative_inventory = 1},
	light_source = 13,
	drop = ""
})

minetest.register_craftitem("magicalities:focus_light", {
	description = "Wand Focus of Light",
	groups = {wand_focus = 1},
	inventory_image = "magicalities_focus_light.png",
	stack_max = 1,
	_wand_requirements = {
		["light"] = 1
	},
	_wand_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end

		local pos = pointed_thing.under
		local pname = user:get_player_name()

		if minetest.is_protected(pos, pname) then
			minetest.record_protection_violation(pos, pname)
			return
		end

		local node = minetest.get_node(pos).name

		if node == "default:stone" or node == "default:desert_stone" then
			minetest.swap_node(pos, {name = "magicalities:light_source"})
			itemstack = magicalities.wands.wand_take_contents(itemstack, {light = 1})
			magicalities.wands.update_wand_desc(itemstack)
		end

		return itemstack
	end,
})

---------------
-- Tunneling --
---------------

local tunneler_memory = {}
local tunneler_depth  = 8

local function reset_tunnel(tid)
	local infos = tunneler_memory[tid]
	if not infos then return end

	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(infos.minp, infos.maxp)
	local area = VoxelArea:new{MinEdge=e1, MaxEdge=e2}

	local data = manip:get_data()

	for i in area:iterp(infos.minp, infos.maxp) do
		if infos.data[i] ~= nil then
			data[i] = infos.data[i]
		end
	end

	manip:set_data(data)
	manip:write_to_map()

	tunneler_memory['t' .. tid] = nil
end

local function create_tunnel(pos, dir, owner)
	-- Ensure no double tunnels
	for id,data in pairs(tunneler_memory) do
		if data.owner == owner then
			return false
		end
	end

	local minp
	local maxp

	if dir.x < 0 or dir.y < 0 or dir.z < 0 then
		maxp = vector.add(pos, dir)
		minp = vector.add(pos, vector.multiply(dir, tunneler_depth))
	else
		minp = vector.add(pos, dir)
		maxp = vector.add(pos, vector.multiply(dir, tunneler_depth))
	end

	if dir.z ~= 0 then
		minp.x = minp.x + -1
		maxp.x = maxp.x + 1

		minp.y = minp.y + -1
		maxp.y = maxp.y + 1
	end

	if dir.y ~= 0 then
		minp.z = minp.z + -1
		maxp.z = maxp.z + 1

		minp.x = minp.x + -1
		maxp.x = maxp.x + 1
	end

	if dir.x ~= 0 then
		minp.z = minp.z + -1
		maxp.z = maxp.z + 1

		minp.y = minp.y + -1
		maxp.y = maxp.y + 1
	end

	-- Set the nodes
	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(minp, maxp)
	local area = VoxelArea:new{MinEdge=e1, MaxEdge=e2}

	local data = manip:get_data()

	local c_air = minetest.get_content_id("air")
	local c_tunnel = minetest.get_content_id("magicalities:tunnel_node")
	local dtree = {}
	local abort = false

	for i in area:iterp(minp, maxp) do
		if data[i] ~= c_air then
			dtree[i] = data[i]
			data[i] = c_tunnel
		elseif data[i] == c_tunnel then
			abort = true
			break
		end
	end

	if abort then return false end

	-- Set nodes in map
	manip:set_data(data)
	manip:write_to_map()

	-- Save in cache
	local cnum = math.random(10, 1000)
	local comp1 = math.random(10, 1000)
	local comp2 = math.random(10, 1000)
	cnum = (math.ceil(comp2 + comp1 / cnum) + cnum)

	tunneler_memory['t' .. cnum] = {
		data  = dtree,
		minp  = minp,
		maxp  = maxp,
		owner = owner,
	}

	minetest.after(10, reset_tunnel, 't' .. cnum)
	return true
end

minetest.register_node("magicalities:tunnel_node", {
	groups    = {not_in_creative_inventory = 1},
	walkable  = false,
	pointable = false,
	diggable  = false,
	drawtype  = "glasslike_framed",
	paramtype = "light",
	sunlight_propagates = true,
	tiles     = {"magicalities_void.png"},
})

minetest.register_craftitem("magicalities:focus_tunnel", {
	description = "Wand Focus of Tunneling",
	groups = {wand_focus = 1},
	inventory_image = "magicalities_focus_tunnel.png",
	stack_max = 1,
	_wand_requirements = {
		["dark"] = 10,
		["light"] = 10,
		["earth"] = 10,
	},
	_wand_use = function (itemstack, user, pointed_thing)
		if not pointed_thing.above or pointed_thing.type ~= "node" then return itemstack end
		if not user or user:get_player_name() == "" then return itemstack end
		local dir = user:get_look_dir()
		local wm  = minetest.dir_to_wallmounted(dir)
		dir = minetest.wallmounted_to_dir(wm)

		minetest.after(0.1, create_tunnel, pointed_thing.above, dir, user:get_player_name())
		itemstack = magicalities.wands.wand_take_contents(itemstack, {
			["dark"] = 10,
			["light"] = 10,
			["earth"] = 10,
		})
		magicalities.wands.update_wand_desc(itemstack)

		return itemstack
	end
})

minetest.register_on_shutdown(function ()
	for id in pairs(tunneler_memory) do
		reset_tunnel(id)
	end
end)

-----------------------
-- Elemental Attacks --
-----------------------

local special_fn = {}

-- Particles
local randparticles = PcgRandom(os.clock())
local function shoot_particles (user, velocity, color)
	if not particles then return end
	if not color then
		color = ""
	else
		color = "^[multiply:"..color
	end

	-- Calculate velocity
	local dir = user:get_look_dir()
	local vel = {x=0,y=0,z=0}
	vel.x = dir.x * velocity
	vel.y = dir.y * velocity
	vel.z = dir.z * velocity

	-- Calculate position
	local pos = user:get_pos()
	pos.x = pos.x + (dir.x * 2)
	pos.y = pos.y + (dir.y * 2) + 1.5
	pos.z = pos.z + (dir.z * 2)

	for i = 1, magicalities.magic_spray_count do
		-- Deviation
		local relvel = {x=0,y=0,z=0}
		relvel.x = vel.x + (randparticles:next((-i/2.5) * 1000, (i/2.5) * 1000) / 1000)
		relvel.y = vel.y + (randparticles:next((-i/2.5) * 1000, (i/2.5) * 1000) / 1000)
		relvel.z = vel.z + (randparticles:next((-i/2.5) * 1000, (i/2.5) * 1000) / 1000)
		minetest.add_particle({
			pos = pos,
			velocity = relvel,
			acceleration = relvel,
			expirationtime = 1,
			size = 4,
			collisiondetection = true,
			collision_removal = true,
			texture = "magicalities_spark.png"..color,
		--	animation = {Tile Animation definition},
			glow = 2
		})
	end
end

local function shoot_spray(user, dmg, vel, color, hit_fn)
	shoot_particles(user, vel, color)

	minetest.after(0.05, function()
		local pos = user:get_pos()
		local dir = user:get_look_dir()

		local x = math.random(-1,1)*0.1
		local y = math.random(-1,1)*0.1
		local z = math.random(-1,1)*0.1
		local scatternum = math.random(2, magicalities.magic_spray_count / 2)

		for i = 1, scatternum do
			local relvel = {x=0,y=0,z=0}
			relvel.x = dir.x * vel + (randparticles:next((-i/2.5) * 1000, (i/2.5) * 1000) / 1000)
			relvel.y = dir.y * vel + (randparticles:next((-i/2.5) * 1000, (i/2.5) * 1000) / 1000)
			relvel.z = dir.z * vel + (randparticles:next((-i/2.5) * 1000, (i/2.5) * 1000) / 1000)

			local dmglow = dmg - math.floor(dmg / scatternum)
			local reldmg = math.random(dmglow, dmg)

			local e=minetest.add_entity({x=pos.x+x,y=pos.y+1.5+y,z=pos.z+z}, "magicalities:magic_spray")
			e:set_velocity(relvel)
			e:set_yaw(user:get_look_yaw()+math.pi)
			e:get_luaentity():set_dmg(reldmg)
			e:get_luaentity():set_user(user)
			if hit_fn then
				e:get_luaentity():set_hit_function(hit_fn)
			end
		end
	end)
end

-- Attack
local on_hit_object = function(self, target, hp, user)
	target:punch(user, 1, {full_punch_interval = 1, damage_groups = {fleshy = hp, magic = hp * 2}}, nil)
	return self
end

local magic_remove = function(self)
	if self.object:get_attach() then self.object:set_detach() end
	if self.target then self.target:punch(self.object, 1,{full_punch_interval=1,damage_groups={fleshy=4}}, nil) end
	self.object:set_hp(0)
	self.object:punch(self.object, 1,{full_punch_interval=1.0,damage_groups={fleshy=4}}, nil)
	return self
end

local magic_spray = {
	initial_properties = {
		hp_max = 1,
		physical = false,
		collide_with_objects = false,
		collisionbox = {-0.3, -0.3, -0.3, 0.3, 0.3, 0.3},
		visual = "sprite",
		visual_size = {x = 0.4, y = 0.4},
		textures = {"[combine:16x16"},
		pointable = false,
	},
	struck = false,
	timer = 0,
	hit_fn = nil,
	on_step = function(self, dtime)
		self.timer = self.timer + 1
		if self.timer > 80 or self.struck then
			magic_remove(self)
		end
		local pos=self.object:get_pos()
		local no=minetest.registered_nodes[minetest.get_node(pos).name]
		if no.walkable and not self.struck then
			if self.hit_fn and special_fn[self.hit_fn] and special_fn[self.hit_fn].on_hit_node then 
				special_fn[self.hit_fn].on_hit_node(self, pos, minetest.get_node(pos), self.user)
			end

			self.struck = true
			return self
		end
		for i, ob in pairs(minetest.get_objects_inside_radius(pos, 1)) do
			if (ob and not self.struck) and ((ob:is_player() and ob:get_player_name() ~= self.user:get_player_name()) or (ob:get_luaentity() and ob:get_luaentity().physical and ob:get_luaentity().name~="__builtin:item" )) then
				self.object:set_velocity({x=0, y=0, z=0})
				on_hit_object(self, ob, self.dmg / 2, self.user)
				if self.hit_fn and special_fn[self.hit_fn] and special_fn[self.hit_fn].on_hit_object then 
					special_fn[self.hit_fn].on_hit_object(self, ob, self.dmg / 2, self.user)
				end

				self.struck = true
				return self
			end
		end
		return self
	end,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if not self.target then return self end
		if not self.hp then self.hp = self.object:get_hp() end
		local hp = self.object:get_hp()
		local hurt = self.hp-self.object:get_hp()
		self.hp = self.object:get_hp()
		self.target:set_hp(self.target:get_hp() - hurt)
		self.target:punch(self.object, hurt, {full_punch_interval = 1.0, damage_groups = {fleshy=4}}, "default:sword_wood", nil)
		if hurt > 100 or hp <= hurt then
			self.target:set_detach()
			self.target:set_velocity({x=0, y=4, z=0})
			self.on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir) end
			magic_remove(self)
		end
		return self
	end
}

function magic_spray:set_dmg(dmg)
	self.dmg = dmg
end

function magic_spray:set_user(user)
	self.user = user
end

function magic_spray:set_hit_function(hit_fn)
	self.hit_fn = hit_fn
end

function magicalities.register_elemental_focus (element, description, damage, hit_fn)
	local el = magicalities.elements[element]
	minetest.register_craftitem("magicalities:focus_atk_"..element, {
		description = "Wand Focus of "..el.description.."\n"..description,
		groups = {wand_focus = 1},
		inventory_image = "magicalities_focus_atk_"..element..".png",
		stack_max = 1,
		_wand_requirements = {
			[element] = magicalities.elemental_focus_consumption
		},
		_wand_use = function (itemstack, user, pointed_thing)
			if not user or user:get_player_name() == "" then return itemstack end

			itemstack = magicalities.wands.wand_take_contents(itemstack, {[element] = magicalities.elemental_focus_consumption})
			magicalities.wands.update_wand_desc(itemstack)
			shoot_spray(user, damage, magicalities.elemental_focus_velocity, el.color, hit_fn)

			return itemstack
		end
	})
end

function magicalities.register_focus_atk_special(name, fns)
	special_fn[name] = fns
end

-- Register everything

minetest.register_entity("magicalities:magic_spray", magic_spray)

magicalities.register_elemental_focus("air", "Deals some damage to enemies", 2)
magicalities.register_elemental_focus("earth", "Deals some damage to enemies", 4)
magicalities.register_elemental_focus("water", "Spawns water sources", 3, "setwater")
magicalities.register_elemental_focus("fire", "Lights things on fire", 8, "setfire")

magicalities.register_focus_atk_special("setfire", {
	on_hit_node = function (self, pos, node, user)
		local toppos = vector.add(pos, {x=0,y=1,z=0})
		local topnode = minetest.get_node_or_nil(toppos)
		if not topnode or topnode.name ~= "air" then return end
		if minetest.is_protected(toppos, user:get_player_name()) then return end
		minetest.set_node(toppos, {name="fire:basic_flame"})
	end
})

local function set_water(self, _, __, user)
	local pos = self.object:get_pos()
	local toppos = vector.add(pos, {x=0,y=1,z=0})
	local topnode = minetest.get_node_or_nil(toppos)
	if not topnode or topnode.name ~= "air" then return end
	if minetest.is_protected(toppos, user:get_player_name()) then return end
	minetest.set_node(toppos, {name="default:water_source"})
end

magicalities.register_focus_atk_special("setwater", {
	on_hit_object = set_water,
	on_hit_node = set_water,
})
