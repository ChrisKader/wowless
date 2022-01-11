local indir, outdir = unpack(arg)
local lfs = require('lfs')
local writeFile = require('pl.file').write
local pprintYaml = require('wowapi.yaml').pprint
local tags = {
  'wow',
  'wowt',
  'wow_classic',
  'wow_classic_era',
  'wow_classic_era_ptr',
  'wow_classic_ptr',
}
local docs = {}
local enum = {}
for _, tag in ipairs(tags) do
  local tagdir = indir .. '/' .. tag
  local docdir = tagdir .. '/Interface/AddOns/Blizzard_APIDocumentation'
  for f in lfs.dir(docdir) do
    if f:sub(-4) == '.lua' then
      pcall(setfenv(loadfile(docdir .. '/' .. f), {
        APIDocumentation = {
          AddDocumentationTable = function(_, t)
            docs[f] = docs[f] or {}
            docs[f][tag] = t
          end,
        }
      }))
    end
  end
  local env = {}
  setfenv(loadfile(tagdir .. '/Interface/GlobalEnvironment.lua'), env)()
  for en in pairs(env.Enum) do
    enum[en] = true
  end
end
lfs.mkdir(outdir)
local expectedTopLevelFields = {
  Events = true,
  Functions = true,
  Name = true,
  Namespace = true,
  Tables = true,
  Type = true,
}
local tabs, funcs = {}, {}
for f, envt in pairs(docs) do
  for _, t in pairs(envt) do
    for k in pairs(t) do
      assert(expectedTopLevelFields[k], ('unexpected field %q in %q'):format(k, f))
    end
    assert(not t.Type or t.Type == 'System', f)
    for _, tab in ipairs(t.Tables or {}) do
      local name = (t.Namespace and (t.Namespace .. '.') or '') .. tab.Name
      tabs[name] = tabs[name] or tab
    end
    for _, func in ipairs(t.Functions or {}) do
      local name = (t.Namespace and (t.Namespace .. '.') or '') .. func.Name
      funcs[name] = funcs[name] or func
    end
  end
end
local types = {
  bool = 'b',
  number = 'n',
  string = 's',
  table = 't',
}
local tables = {
  Constants = 'n',
  Enumeration = 'n',
  Structure = 't',
}
local tys = {}
for name, tab in pairs(tabs) do
  tys[name] = assert(tables[tab.Type])
end
for k, v in pairs(require('wowapi.data').structures) do
  if v.status == 'implemented' then
    tys[k] = 't'
  end
end
local expectedArgumentKeys = {
  Default = true,
  Documentation = true,
  InnerType = true,
  Mixin = true,
  Name = true,
  Nilable = true,
  Type = true,
}
local knownMixinStructs = {
  ColorMixin = 'Color',
  Vector2DMixin = 'Vector2D',
}
local function t2ty(t, ns, mixin)
  if enum[t] then
    return 'number'
  elseif t == 'table' then
    return mixin and knownMixinStructs[mixin] or t
  elseif types[t] then
    return t
  elseif ns and tys[ns .. '.' .. t] then
    local n = ns .. '.' .. t
    local b = tabs[n]
    return b and b.Type == 'Structure' and n or 'number'
  elseif tys[t] then
    return t
  else
    print('unknown type ' .. t)
    return 'unknown'
  end
end
local function insig(fn, ns)
  local t = {}
  for _, a in ipairs(fn.Arguments or {}) do
    for k in pairs(a) do
      assert(expectedArgumentKeys[k], ('invalid argument key %q in %q'):format(k, fn.Name))
    end
    table.insert(t, {
      default = a.Default,
      innerType = a.InnerType and t2ty(a.InnerType, ns),
      mixin = a.Mixin,
      name = a.Name,
      nilable = a.Nilable or nil,
      type = t2ty(a.Type, ns, a.Mixin),
    })
  end
  return t
end
local expectedReturnKeys = {
  Default = true,
  Documentation = true,
  InnerType = true,
  Mixin = true,
  Name = true,
  Nilable = true,
  StrideIndex = true,
  Type = true,
}
local function outsig(fn, ns)
  local outputs = {}
  for _, r in ipairs(fn.Returns or {}) do
    for k in pairs(r) do
      assert(expectedReturnKeys[k], ('unexpected key %q'):format(k))
    end
    table.insert(outputs, {
      default = r.Default,
      innerType = r.InnerType and t2ty(r.InnerType, ns),
      mixin = r.Mixin,
      name = r.Name,
      nilable = r.Nilable or nil,
      type = t2ty(r.Type, ns, r.Mixin),
    })
  end
  return outputs
end
local apis = require('wowapi.data').apis
for name, fn in pairs(funcs) do
  if not apis[name] or apis[name].status == 'autogenerated' then
    local dotpos = name:find('%.')
    local ns = dotpos and name:sub(1, dotpos-1)
    writeFile('data/api/' .. name .. '.yaml', pprintYaml({
      name = name,
      status = 'autogenerated',
      inputs = { insig(fn, ns) },
      outputs = outsig(fn, ns),
    }))
  end
end
local expectedStructureKeys = {
  Name = true,
  Type = true,
  Fields = true,
  Documentation = true,
}
local expectedStructureFieldKeys = {
  Name = true,
  Nilable = true,
  Type = true,
  InnerType = true,
  Mixin = true,
  Documentation = true,
  Default = true,
}
local structures = {}
for name, tab in pairs(tabs) do
  if tab.Type == 'Structure' then
    for k in pairs(tab) do
      assert(expectedStructureKeys[k], ('unexpected structure key %q in %q'):format(k, name))
    end
    local dotpos = name:find('%.')
    local ns = dotpos and name:sub(1, dotpos-1)
    structures[name] = structures[name] or {
      name = name,
      status = 'autogenerated',
      fields = (function()
        local ret = {}
        for _, field in ipairs(tab.Fields) do
          for k in pairs(field) do
            assert(expectedStructureFieldKeys[k], ('unexpected field key %q in %q'):format(k, name))
          end
          table.insert(ret, {
            name = field.Name,
            nilable = field.Nilable or nil,
            type = t2ty(field.Type, ns, field.Mixin),
            innerType = field.InnerType and t2ty(field.InnerType, ns),
            mixin = field.Mixin,
            default = field.Default,
          })
        end
        table.sort(ret, function(a, b) return a.name < b.name end)
        return ret
      end)(),
    }
  end
end
for k, v in pairs(structures) do
  writeFile('data/structures/' .. k .. '.yaml', pprintYaml(v))
end
