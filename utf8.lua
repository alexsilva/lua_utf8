bit32 = bit32 or bit

local _longEncode = function(codepoint)
    local chars = ""
    local trailers = 0
    local ocodepoint = codepoint

    -- feckin backwards compatability
    if codepoint < 128 then return strchar(codepoint) end

    topspace = 32 -- we lose a bit of space left on the top every time

    -- even if the codepoint is <0x40 and will fit inside 10xxxxxx,
    -- we add a 11100000  byte in front, because it won't fit inside
    -- 0x20 xxxxx so we need a blank top and an extra continuation.
    -- example: 0x90b
    -- bit.rshift(0x90b,6) => 0x24
    -- 0x24 = 00100100
    -- top =  11100000
    --          ^ oh noes info lost
    -- thus we do:
    --        11100000 - 10100100 - ...
    --
    while codepoint > topspace do -- as long as there's too much for the top
        local derp = bit32.bor(bit32.band(codepoint, 63), 128)
        chars = strchar(derp) .. chars

        codepoint = bit32.blogic_rshift(codepoint,6)

        trailers = trailers + 1
        topspace = bit32.blogic_rshift(topspace,1)
    end

    -- is there a better way to make 0xFFFF0000 from 4 than lshift/rshift?
    local mask = bit32.blshift(bit32.blogic_rshift(255, 7-trailers), 7-trailers)
    local last = bit32.bor(mask, codepoint)

    return strchar(last) .. chars
end

local _encode = function(targ)
    local str = {s = ''}
    longEncode = %_longEncode
    foreachi(targ, function(i, codepoint)
        -----
        -- manually doing the common codepoints to avoid calling logarithm
        -----
        local derp = ''
        if codepoint < 128 then
            derp = strchar(codepoint)

        elseif codepoint < 2048 then
            derp = strchar(bit32.bor(bit32.blogic_rshift(codepoint,6), 192)) ..
                   strchar(bit32.bor(bit32.band(codepoint, 63), 128))

        elseif codepoint < 65536 then
            derp = strchar(bit32.bor(bit32.blogic_rshift(codepoint,12), 224)) ..
                   strchar(bit32.bor(bit32.band(bit32.blogic_rshift(codepoint,6), 63), 128)) ..
                   strchar(bit32.bor(bit32.band(codepoint, 63), 128))

        elseif codepoint < 2097152 then
            derp = strchar(bit32.bor(bit32.blogic_rshift(codepoint, 18), 240)) ..
                   strchar(bit32.bor(bit32.band(bit32.blogic_rshift(codepoint,12), 63), 128)) ..
                   strchar(bit32.bor(bit32.band(bit32.blogic_rshift(codepoint,6), 63), 128)) ..
                   strchar(bit32.bor(bit32.band(codepoint, 63), 128))
        else
            -- alpha centauri?!
            derp = %longEncode(codepoint)
        end
        %str.s = %str.s .. derp
    end)
    return str.s
end

return {
    longEncode = function (...)
        local str = {s = ''}
        longEncode = %_longEncode
        foreachi(arg, function(i, codepoint)
            %str.s = %str.s .. %longEncode(codepoint)
        end)
        return str.s
    end,
    encode_args = function(...)
        return %_encode(arg)
    end,
    encode = function(targs)
        return %_encode(targs)
    end
    -- got decode from http://lua-users.org/wiki/LuaUnicode
--     decode = function(s)
--         assert(type(s) == "string")
--         local res, seq, val = {}, 0, nil
--         for i = 1, #s do
--             local c = string.byte(s, i)
--             if seq == 0 then
--                 table.insert(res, val)
--                 seq = c < 0x80 and 1 or c < 0xE0 and 2 or c < 0xF0 and 3 or
--                       c < 0xF8 and 4 or c < 0xFC and 5 or c < 0xFE and 6 or
--                       error("invalid UTF-8 character sequence")
--                 val = bit32.band(c, 2^(8-seq) - 1)
--             else
--                 val = bit32.bor(bit32.lshift(val, 6), bit32.band(c, 0x3F))
--             end
--             seq = seq - 1
--         end
--         table.insert(res, val)
--         --table.insert(res, 0)
--         return res
--     end
}
