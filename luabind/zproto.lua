local engine = require "zproto.c"

local zproto = {}

local cachemt = {__mode = "kv"}
local indexmt = {
	__index = zproto,
	__gc = function(table)
		if table.proto then
			engine.free(table.proto)
		end
	end
}



local function create(self, proto)
	local t = {
		ncache = {}, -- name cache
		tcache = {}, -- tag cache
		nametag = {}, -- name tag cache
		proto = proto,
	}
	setmetatable(t, indexmt)
	setmetatable(t.ncache, cachemt)
	setmetatable(t.tcache, cachemt)
	setmetatable(t.nametag, cachemt)
	return t;
end

function zproto:load(path)
	local proto, err = engine.load(path)
	if not proto then
		return nil, err
	end
	return create(self, proto)
end

function zproto:parse(str)
	local proto, err = engine.parse(str)
	if not proto then
		return nil, err
	end
	return create(self, proto)
end

local function query(self, typ)
	local itype
	local proto
	assert(type(typ) == "number" or type(typ) == "string")
	if type(typ) == "number" then
		itype = true
		assert(typ > 0, "protocol must be large then 0")
		proto = self.tcache[typ]
	elseif type(typ) == "string" then
		assert(#typ <= 32, "type name length less then 32 will be more effective")
		itype = false
		proto = self.ncache[typ]
	end
	if proto then
		return proto
	end

	assert(self.proto)
	local proto, tag = engine.query(self.proto, typ)
	assert(proto, typ)
	if itype then
		self.tcache[typ] = proto
	else
		self.ncache[typ] = proto
		self.nametag[typ] = tag
	end
	return proto
end

function zproto:encode(typ, packet)
	local record = query(self, typ)
	assert(typ, "packet type nil")
	assert(packet, "packet body nil")
	return engine.encode(record, packet)
end

function zproto:tag(typ)
	assert(type(typ) == "string")
	local tag = self.nametag[typ]
	if not tag then
		query(self, typ)
		tag = self.nametag[typ]
	end
	assert(tag > 0, "only can query proto")
	return tag
end

function zproto:decode(typ, data, sz, offset)
	local record = query(self, typ)
	return engine.decode(record, data, sz, offset)
end

function zproto:pack(data, sz)
	return engine.pack(data, sz)
end

function zproto:unpack(data, sz)
	return engine.unpack(data, sz);
end

return zproto

