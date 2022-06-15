local function mixin(t, ...)
  for _, kv in ipairs({ ... }) do
    for k, v in pairs(kv) do
      t[k] = v
    end
  end
  return t
end

local function recursiveMixin(t, u, failOnOverwrite)
  for k, v in pairs(u) do
    local tv = t[k]
    if tv == nil or type(tv) ~= 'table' or type(v) ~= 'table' then
      assert(tv == nil or not failOnOverwrite, ('overwriting %q'):format(k))
      t[k] = v
    else
      recursiveMixin(tv, v, failOnOverwrite)
    end
  end
  return t
end

local readfile = (function()
  local lfs = require('lfs')
  local path = require('path')
  local cachedDirs = {}
  local nameCache = {}
  local function cacheDir(dir)
    if not cachedDirs[dir] then
      cachedDirs[dir] = true
      cacheDir(path.dirname(dir))
      if dir == '' then
        for f in lfs.dir('.') do
          nameCache[f:lower()] = f
        end
      else
        local rdir = assert(nameCache[dir], 'unknown directory ' .. dir)
        for f in lfs.dir(rdir) do
          local fn = path.join(rdir, f)
          nameCache[fn:lower()] = fn
        end
      end
    end
  end
  local function resolveCase(name)
    local lname = name:lower()
    cacheDir(path.dirname(lname))
    return assert(nameCache[lname], 'unknown file ' .. name)
  end
  return function(filename)
    local fn = resolveCase(path.normalize(filename))
    local f = assert(io.open(fn:gsub('\\', '/'), 'rb'))
    local content = f:read('*all')
    f:close()
    if content:sub(1, 3) == '\239\187\191' then
      content = content:sub(4)
    end
    return content
  end
end)()

local date = require('date')

local function calendarTimeToDate(ct)
  return date(ct.year, ct.month, ct.monthDay, ct.hour, ct.minute)
end

local function dateToCalendarTime(d)
  return {
    hour = d:gethours(),
    minute = d:getminutes(),
    month = d:getmonth(),
    monthDay = d:getday(),
    weekday = d:getweekday(),
    year = d:getyear(),
  }
end

local productToFlavorMap = {
  wow = 'Mainline',
  wowt = 'Mainline',
  wow_classic = 'TBC',
  wow_classic_era = 'Vanilla',
  wow_classic_era_ptr = 'Vanilla',
  wow_classic_ptr = 'TBC',
}

local function productToFlavor(p)
  return assert(productToFlavorMap[p], 'invalid product')
end

local function productList()
  local t = {}
  for k in pairs(productToFlavorMap) do
    table.insert(t, k)
  end
  return t
end

return {
  calendarTimeToDate = calendarTimeToDate,
  dateToCalendarTime = dateToCalendarTime,
  mixin = mixin,
  productList = productList,
  productToFlavor = productToFlavor,
  readfile = readfile,
  recursiveMixin = recursiveMixin,
}
