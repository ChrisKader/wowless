local casc = require('casc')
local yaml = require('wowapi.yaml')
local builds = require('wowapi.data').builds
for p, b in pairs(builds) do
  local bkey, _, _, version = casc.cdnbuild('http://us.patch.battle.net:1119/' .. p, 'us')
  local v1, v2, v3, v4 = version:match('^(%d+)%.(%d+)%.(%d+)%.(%d+)$')
  b.build = v4
  b.hash = bkey
  b.version = ('%s.%s.%s'):format(v1, v2, v3)
  b.tocversion = tonumber(v1) * 10000 + tonumber(v2) * 100 + tonumber(v3)
  require('pl.file').write('data/products/' .. p .. '/build.yaml', yaml.pprint(b))
end
