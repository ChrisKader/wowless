local T = ...
local b = T.data.build
T.check7(b.version, b.build, b.date, b.tocversion, '', ' ', b.tocversion, T.env.GetBuildInfo())
