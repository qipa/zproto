local zproto = require "zproto"
print("zproto", zproto.encode)
local proto = zproto.parse ([[
info {
        .name:string 1
        .age:integer 2
}

packet {
        phone {
                .home:integer 1
                .work:integer 2
        }
        .phone:phone 1
        .info:info[] 2
        .address:string 3
        .luck:integer[] 4
}
]])

local packet = {
        phone = {home=123456, work=654321},
        info = {{name = "lucy", age = 18}, {name="lilei", age = 24},},
        address = "China.shanghai",
        luck = {1, 3, 9},
}

local record = zproto.query(proto, "packet")
local data, sz = zproto.encode(proto, record, 8895, packet)

local protocol = zproto.protocol(data, sz)
print("protocol", protocol)

local unpack = zproto.decode(proto, record, data, sz);
local function dump_tbl(s, tbl, n)
        for k, v in pairs(tbl) do
                str = ""
                for i = 1, n do
                        str = str .. " "
                end
                str = str .. s .. k .. ":"
                
                if type(v) == "table" then
                        dump_tbl(str, v, n + 1)
                else
                        print(str, v)
                end
        end
end

dump_tbl("", unpack, 0)
