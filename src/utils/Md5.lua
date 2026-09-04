local M = {}

-- ============================================================
-- MD5 core
-- ============================================================

local s = {
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
}

local K = {}
for i = 0, 63 do
    K[i + 1] = math.floor(math.abs(math.sin(i + 1)) * 4294967296.0) & 0xFFFFFFFF
end

local function leftrotate(x, c)
    x = x & 0xFFFFFFFF
    return ((x << c) | (x >> (32 - c))) & 0xFFFFFFFF
end

local function toBytesLE32(n)
    return string.char(
        n & 0xFF,
        (n >> 8) & 0xFF,
        (n >> 16) & 0xFF,
        (n >> 24) & 0xFF
    )
end

local function toHexLE32(n)
    local bytes = toBytesLE32(n)
    return string.format("%02x%02x%02x%02x",
        string.byte(bytes, 1), string.byte(bytes, 2),
        string.byte(bytes, 3), string.byte(bytes, 4))
end

-- Returns the MD5 hash of `message` (a Lua string) as a lowercase hex string
local function md5sum(message)
    local a0 = 0x67452301
    local b0 = 0xefcdab89
    local c0 = 0x98badcfe
    local d0 = 0x10325476

    local bitLen = #message * 8

    -- Pre-processing: append '1' bit (as 0x80 byte), pad with zero bytes
    message = message .. string.char(0x80)
    while (#message % 64) ~= 56 do
        message = message .. string.char(0x00)
    end

    -- Append original length in bits, 64-bit little-endian
    local lenLow = bitLen & 0xFFFFFFFF
    local lenHigh = (bitLen >> 32) & 0xFFFFFFFF
    message = message .. toBytesLE32(lenLow) .. toBytesLE32(lenHigh)

    -- Process each 512-bit (64-byte) chunk
    for chunkStart = 1, #message, 64 do
        local Mw = {}
        for j = 0, 15 do
            local offset = chunkStart + j * 4
            local b1, b2, b3, b4 = string.byte(message, offset, offset + 3)
            Mw[j] = b1 | (b2 << 8) | (b3 << 16) | (b4 << 24)
        end

        local A, B, C, D = a0, b0, c0, d0

        for i = 0, 63 do
            local F, g
            if i < 16 then
                F = (B & C) | ((~B & 0xFFFFFFFF) & D)
                g = i
            elseif i < 32 then
                F = (D & B) | ((~D & 0xFFFFFFFF) & C)
                g = (5 * i + 1) % 16
            elseif i < 48 then
                F = B ~ C ~ D
                g = (3 * i + 5) % 16
            else
                F = C ~ (B | (~D & 0xFFFFFFFF))
                g = (7 * i) % 16
            end

            F = (F + A + K[i + 1] + Mw[g]) & 0xFFFFFFFF
            A = D
            D = C
            C = B
            B = (B + leftrotate(F, s[i + 1])) & 0xFFFFFFFF
        end

        a0 = (a0 + A) & 0xFFFFFFFF
        b0 = (b0 + B) & 0xFFFFFFFF
        c0 = (c0 + C) & 0xFFFFFFFF
        d0 = (d0 + D) & 0xFFFFFFFF
    end

    return toHexLE32(a0) .. toHexLE32(b0) .. toHexLE32(c0) .. toHexLE32(d0)
end


-- Returns the MD5 hash of `input` as a lowercase hex string, or nil on failure
function M.md5(input)
    local ok, result = pcall(md5sum, input)
    if ok then
        return result
    else
        -- swap this for whatever logging your project uses
        io.stderr:write("MD5 hashing failed: " .. tostring(result) .. "\n")
        return nil
    end
end

-- Verifies that `password`'s MD5 hash matches `storedHash` (case-insensitive)
function M.verifyMD5(password, storedHash)
    local ok, hashOfInput = pcall(M.md5, password)
    if not ok or hashOfInput == nil or storedHash == nil then
        return false
    end
    return hashOfInput:lower() == storedHash:lower()
end

return M
