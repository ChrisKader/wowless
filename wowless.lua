local function loadToc(toc)
  local result = {}
  for line in io.lines(toc) do
    line = line:match('^%s*(.-)%s*$'):gsub('\\', '/')
    if line ~= '' and line:sub(1, 1) ~= '#' then
      local f = assert(io.open(line, 'rb'))
      local content = f:read('*all')
      f:close()
      if content:sub(1, 3) == '\239\187\191' then
        content = content:sub(4)
      end
      if line:sub(-4) == '.lua' then
        table.insert(result, {
          filename = line,
          lua = assert(loadstring(content)),
        })
      elseif line:sub(-4) == '.xml' then
        -- TODO support xml
      else
        error('unknown file type ' .. line)
      end
    end
  end
  return result
end

local bitlib = require('bit')

local UNIMPLEMENTED = function() end

local env = {
  CreateFrame = function()
    return {
      RegisterEvent = UNIMPLEMENTED,
      SetForbidden = UNIMPLEMENTED,
      SetScript = UNIMPLEMENTED,
    }
  end,
  bit = {
    bor = bitlib.bor,
  },
  C_Timer = {
    After = UNIMPLEMENTED,
  },
  Enum = setmetatable({}, {
    __index = function(_, k)
      return setmetatable({}, {
        __index = function(_, k2)
          return 'AUTOGENERATED:Enum:' .. k .. ':' .. k2
        end,
      })
    end,
  }),
  FillLocalizedClassList = UNIMPLEMENTED,
  getfenv = getfenv,
  ipairs = ipairs,
  LE_EXPANSION_BURNING_CRUSADE = 'UNIMPLEMENTED:LE_EXPANSION_BURNING_CRUSADE',
  LE_EXPANSION_CLASSIC = 'UNIMPLEMENTED:LE_EXPANSION_CLASSIC',
  LE_LFG_CATEGORY_BATTLEFIELD = 'UNIMPLEMENTED:LE_LFG_CATEGORY_BATTLEFIELD',
  LE_LFG_CATEGORY_FLEXRAID = 'UNIMPLEMENTED:LE_LFG_CATEGORY_FLEXRAID',
  LE_LFG_CATEGORY_LFD = 'UNIMPLEMENTED:LE_LFG_CATEGORY_LFD',
  LE_LFG_CATEGORY_LFR = 'UNIMPLEMENTED:LE_LFG_CATEGORY_LFR',
  LE_LFG_CATEGORY_RF = 'UNIMPLEMENTED:LE_LFG_CATEGORY_RF',
  LE_LFG_CATEGORY_SCENARIO = 'UNIMPLEMENTED:LE_LFG_CATEGORY_SCENARIO',
  LE_LFG_CATEGORY_WORLDPVP = 'UNIMPLEMENTED:LE_LFG_CATEGORY_WORLDPVP',
  LE_ITEM_QUALITY_ARTIFACT = 'UNIMPLEMENTED:LE_ITEM_QUALITY_ARTIFACT',
  LE_ITEM_QUALITY_COMMON = 'UNIMPLEMENTED:LE_ITEM_QUALITY_COMMON',
  LE_ITEM_QUALITY_EPIC = 'UNIMPLEMENTED:LE_ITEM_QUALITY_EPIC',
  LE_ITEM_QUALITY_HEIRLOOM = 'UNIMPLEMENTED:LE_ITEM_QUALITY_HEIRLOOM',
  LE_ITEM_QUALITY_LEGENDARY = 'UNIMPLEMENTED:LE_ITEM_QUALITY_LEGENDARY',
  LE_ITEM_QUALITY_POOR = 'UNIMPLEMENTED:LE_ITEM_QUALITY_POOR',
  LE_ITEM_QUALITY_RARE = 'UNIMPLEMENTED:LE_ITEM_QUALITY_RARE',
  LE_ITEM_QUALITY_UNCOMMON = 'UNIMPLEMENTED:LE_ITEM_QUALITY_UNCOMMON',
  LE_ITEM_QUALITY_WOW_TOKEN = 'UNIMPLEMENTED:LE_ITEM_QUALITY_WOW_TOKEN',
  LE_QUEST_TAG_TYPE_DUNGEON = 'UNIMPLEMENTED:LE_QUEST_TAG_TYPE_DUNGEON',
  LE_QUEST_TAG_TYPE_RAID = 'UNIMPLEMENTED:LE_QUEST_TAG_TYPE_RAID',
  math = {},
  pairs = pairs,
  rawget = rawget,
  RegisterStaticConstants = UNIMPLEMENTED,
  select = select,
  setmetatable = setmetatable,
  string = {},
  table = {
    insert = table.insert,
  },
  type = type,
}

require('lfs').chdir('wowui/classic/FrameXML')
for _, code in ipairs(loadToc('FrameXML.toc')) do
  local success, err = pcall(setfenv(code.lua, env))
  if not success then
    error('failure loading ' .. code.filename .. ': ' .. err)
  end
end
for k in pairs(env) do
  print(k)
end
