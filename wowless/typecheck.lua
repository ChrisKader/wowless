return function(api)
  local enumrev = {}
  for k, v in pairs(api.datalua.globals.Enum) do
    local t = {}
    for vk, vv in pairs(v) do
      t[vv] = vk
    end
    enumrev[k] = t
  end

  local function typestr(ty)
    if type(ty) == 'string' then
      return ty
    end
    if ty.structure then
      return ty.structure
    end
    if ty.arrayof then
      return typestr(ty.arrayof) .. ' array'
    end
    if ty.enum then
      return ty.enum
    end
    error('unable to typestr')
  end

  local function luatypecheck(basetype, value)
    return value, type(value) ~= basetype
  end

  local framepoints = {
    BOTTOM = true,
    BOTTOMLEFT = true,
    BOTTOMRIGHT = true,
    CENTER = true,
    LEFT = true,
    RIGHT = true,
    TOP = true,
    TOPLEFT = true,
    TOPRIGHT = true,
  }

  local scalartypechecks = {
    boolean = function(value)
      return luatypecheck('boolean', value)
    end,
    font = function(value)
      if type(value) == 'string' then
        value = api.env[value]
      end
      if type(value) ~= 'table' then
        return nil, true
      end
      local ud = api.UserData(value)
      return ud, ud == nil
    end,
    FramePoint = function(value)
      return value, not framepoints[value]
    end,
    ['function'] = function(value)
      return luatypecheck('function', value)
    end,
    number = function(value)
      return luatypecheck('number', type(value) == 'string' and tonumber(value) or value)
    end,
    oneornil = function(value)
      return value, value ~= 1
    end,
    string = function(value)
      return luatypecheck('string', type(value) == 'number' and tostring(value) or value)
    end,
    table = function(value)
      return luatypecheck('table', value)
    end,
    uiAddon = function(value)
      return api.states.Addons[tonumber(value) or tostring(value):lower()]
    end,
    unit = function(value)
      if type(value) ~= 'string' then
        return nil, true
      end
      -- TODO complete unit resolution
      local units = api.states.Units
      local guid = units.aliases[value:lower()]
      return guid and units.guids[guid] or nil
    end,
    unknown = function(value)
      return value
    end,
    userdata = function(value)
      return luatypecheck('userdata', value)
    end,
  }

  local function mismatch(spec, value)
    return nil, ('is of type %q, but %q was passed'):format(typestr(spec.type), type(value))
  end

  local nilables = {
    ['nil'] = true,
    oneornil = true,
  }

  local function typecheck(spec, value)
    if value == nil then
      if not spec.nilable and spec.default == nil and not nilables[spec.type] then
        return nil, 'is not nilable, but nil was passed'
      end
      return nil
    end
    local scalartypecheck = scalartypechecks[spec.type]
    if scalartypecheck then
      local v, err = scalartypecheck(value)
      if err then
        return mismatch(spec, value)
      else
        return v
      end
    end
    if spec.type.enum then
      local v = type(value) == 'string' and tonumber(value) or value
      if type(v) ~= 'number' then
        return mismatch(spec, value)
      end
      -- TODO handle flag-style enums more intelligently than this
      if spec.type.enum:sub(-4) == 'Flag' then
        return v
      end
      if not enumrev[spec.type.enum][v] then
        return v, ('is of enum type %q, which does not have value %d'):format(spec.type.enum, v), true
      end
      return v
    elseif spec.type.structure then
      if type(value) ~= 'table' then
        return mismatch(spec, value)
      end
      local st = api.datalua.structures[spec.type.structure]
      for fname, fspec in pairs(st.fields) do
        local _, err = typecheck(fspec, value[fname])
        if err then
          return nil, 'field ' .. fname .. ' ' .. err
        end
      end
      -- TODO assert presence of mixin
      return value
    elseif spec.type.arrayof then
      if type(value) ~= 'table' then
        return mismatch(spec, value)
      end
      local espec = { type = spec.type.arrayof }
      for i, v in ipairs(value) do
        local _, err = typecheck(espec, v)
        if err then
          return nil, 'element ' .. i .. ' ' .. err
        end
      end
      return value
    else
      return nil, 'invalid spec'
    end
  end

  return typecheck
end
