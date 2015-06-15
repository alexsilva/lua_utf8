
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
        local derp = bor(band(codepoint, 63), 128)
        chars = strchar(derp) .. chars

        codepoint = brshift(codepoint,6)

        trailers = trailers + 1
        topspace = brshift(topspace,1)
    end

    -- is there a better way to make 0xFFFF0000 from 4 than lshift/rshift?
    local mask = blshift(brshift(255, 7-trailers), 7-trailers)
    local last = bor(mask, codepoint)

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
            derp = strchar(bor(brshift(codepoint,6), 192)) ..
                   strchar(bor(band(codepoint, 63), 128))

        elseif codepoint < 65536 then
            derp = strchar(bor(brshift(codepoint,12), 224)) ..
                   strchar(bor(band(brshift(codepoint,6), 63), 128)) ..
                   strchar(bor(band(codepoint, 63), 128))

        elseif codepoint < 2097152 then
            derp = strchar(bor(brshift(codepoint, 18), 240)) ..
                   strchar(bor(band(brshift(codepoint,12), 63), 128)) ..
                   strchar(bor(band(brshift(codepoint,6), 63), 128)) ..
                   strchar(bor(band(codepoint, 63), 128))
        else
            -- alpha centauri?!
            derp = %longEncode(codepoint)
        end
        %str.s = %str.s .. derp
    end)
    return str.s
end

local _decode = function(i, a, b, c, d)
    if a == nil then
        return nil
    elseif a <= 127 then
        return i + 1, a
    elseif 194 <= a then
        if a <= 223 then
            if b == nil or b < 128 or 191 < b then return nil end
            local a = mod(a, 32) * 64
            local b = mod(b, 64)
            return i + 2, a + b
    elseif a <= 239 then
        if a <= 236 then
            if a == 224 then
              --if b == nil or b < 160 or 191 < b then return nil end
            else
              --if b == nil or b < 128 or 191 < b then return nil end
            end
        else
            if a == 237 then
                --if b == nil or b < 128 or 159 < b then return nil end
            else
                --if b == nil or b < 128 or 191 < b then return nil end
            end
        end
            --if c == nil or c < 128 or 191 < c then return nil end
            local a = mod(a, 16) * 4096
            local b = mod(b, 64) * 64
            local c = mod(c, 64)
            return i + 3, a + b + c
        elseif a <= 244 then
            if a == 240 then
                --if b == nil or b < 144 or 191 < b then return nil end
            elseif a <= 243 then
                --if b == nil or b < 128 or 191 < b then return nil end
            else
                --if b == nil or b < 128 or 143 < b then return nil end
            end
                --if c == nil or c < 128 or 191 < c then return nil end
                --if d == nil or d < 128 or 191 < d then return nil end
                local a = mod(a,  8) * 262144
                local b = mod(b, 64) * 4096
                local c = mod(c, 64) * 64
                local d = mod(d, 64)
            return i + 4, a + b + c + d
        end
    end
    return nil
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
    end,
    decode = function(s, i)
        local strsize = strlen(s)
        local a = strbyte(s, i)
        local b, c, d
        if strsize > i + 0 then b = strbyte(s, i + 1) end -- byte or nil
        if strsize > i + 1 then c = strbyte(s, i + 2) end -- byte or nil
        if strsize > i + 2 then d = strbyte(s, i + 3) end -- byte or nil

        local x, y = %_decode(i, a, b, c, d)

        return x, y
    end
}
