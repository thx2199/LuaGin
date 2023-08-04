local routes = [[
local routes = require 'gin.core.routes'
local helpers = require 'gin.helpers.common'
local Gin = require 'gin.core.gin'
-- define version
local v1 = routes.version(1)
local route_modules = helpers.module_names_in_path(Gin.app_dirs.routes)
for _, route_module in ipairs(route_modules) do
    local sub_routes = require(route_module)
    for _,r in ipairs(sub_routes) do
        v1:add(r.method,r.pattern,r.route_info)
    end
end
-- others routes
-- v1:add('GET','/hello',function()
--     return 'hello world'
-- end)
return routes
]]

return routes