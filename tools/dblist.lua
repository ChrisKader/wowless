return function(product)
  local dbset = {
    GlobalStrings = true,
    ManifestInterfaceTOCData = true,
  }
  local sqls = {}
  for _, v in pairs(require('wowapi.data').apis) do
    local products = {}
    for _, f in ipairs(v.products or {}) do
      products[f] = true
    end
    if not v.products or products[product] then
      for _, db in ipairs(v.dbs or {}) do
        dbset[db.name] = true
      end
      for _, sql in ipairs(v.sqls or {}) do
        local kk, vv = next(sql)
        table.insert(sqls, kk .. '/' .. vv)
      end
    end
  end
  for _, sql in ipairs(sqls) do
    -- We are fortunate that sqlite complains about missing tables first.
    local sqltext = assert(require('pl.file').read('data/sql/' .. sql .. '.sql'))
    local db = require('lsqlite3').open_memory()
    while not db:prepare(sqltext) do
      local t = db:errmsg():match('^no such table: (%a+)$')
      if t then
        dbset[t] = true
        assert(db:exec('CREATE TABLE ' .. t .. ' (moo INTEGER)') == 0)
      else
        break
      end
    end
  end
  local dblist = {}
  for db in pairs(dbset) do
    table.insert(dblist, db)
  end
  table.sort(dblist)
  return dblist
end
