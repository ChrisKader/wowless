rockspec_format = '3.0'
package = 'wowless'
version = 'scm-0'
source = {
  url = 'git+https://github.com/wowless/wowless.git',
}
build_dependencies = {
  'lsqlite3',
  'lua-cjson',
  'luacasc >= 1.15',
  'luacheck',
  'luadbc',
  'luadbd',
  'luaexpat < 1.5.0',
  'luamagick',
  'luasql-sqlite3',
  'lyaml',
  'vstruct',
}
dependencies = {
  'lua-path',
  'lua-resty-tsort',
  'penlight',
}
build = {
  type = 'builtin',
  modules = {},
}
