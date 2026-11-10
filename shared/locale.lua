-- Locale lookup. L('key', ...) formats the string with string.format when arguments are given.

local function strings()
    return Locales[config.locale] or Locales.en or {}
end

function L(key, ...)
    local s = strings()[key] or (Locales.en and Locales.en[key]) or key
    if select('#', ...) > 0 then
        local ok, out = pcall(string.format, s, ...)
        if ok then return out end
    end
    return s
end

-- The ui_* strings, for the NUI page.
function LootBoxUIStrings()
    local out = {}
    local base, active = Locales.en or {}, strings()
    for k, v in pairs(base) do
        if k:sub(1, 3) == 'ui_' then out[k:sub(4)] = active[k] or v end
    end
    return out
end
