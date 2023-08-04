--[[
    add a model to the application.
    todo:
]]
local ansicolors = require 'ansicolors'

local ModelFactory = {}
local controller_content = require 'gin.cli.templates.controller'
local model_content = require 'gin.cli.templates.model'
local route_content = require 'gin.cli.templates.route_content'

-- transform the underscore name to camel case name
-- e.g. user_name => UserName
local function camel_case_name(name)
    local camel_name = name:gsub("_%l", string.upper)
    return camel_name:gsub("^%l", string.upper) -- capitalize first letter
end


local function generate_file(file_path, file_content, file_type)
    local file = io.open(file_path, "w")
    if file == nil then
        print(ansicolors("%{red}can't open%{reset} " .. file_path))
        return false
    end
    file:write(file_content)
    file:close()
    print(ansicolors("%{green}create%{reset} " .. file_path .. " (" .. file_type .. ")"))
    return true
end
-- create model, controller and route
-- if the model already exists, do nothing
-- if model is a speical, try_require and write
-- if model is a normal, just create
function ModelFactory.new(name, ver)
    local cname = camel_case_name(name)
    ver = ver or 1
    -- create model
    local file_path = "app/models/" .. name .. ".lua"
    local f_exist = io.open(file_path, "r")
    if f_exist ~= nil then
        print(ansicolors("%{red}exist%{reset} " .. file_path))
        io.close(f_exist)
        return
    end
    -- check if the model is a special model, if so, can require the template as modules
    -- use try_require help method
    local helper = require 'gin.helpers.common'
    local special_model = helper.try_require('gin.cli.templates.' .. name .. '.model')
    local model_str, controller_str, route_str
    if special_model ~= nil then
        model_str = special_model
        controller_str = helper.try_require('gin.cli.templates.' .. name .. '.controller')
        route_str = helper.try_require('gin.cli.templates.' .. name .. '.routes')
    end
    -- create model
    local file_content = model_str or string.gsub(model_content, "{{MNAME}}", name)
    generate_file(file_path, file_content, "model")
    -- create controller
    file_path = "app/controllers/" .. ver .. "/" .. name .. "_controller.lua"
    file_content = controller_str or string.gsub(controller_content, "{{CNAME}}", cname)
    file_content = string.gsub(file_content, "{{MNAME}}", name)
    file_content = string.gsub(file_content, "{{item}}", name:sub(1, -2)) -- remove last s
    generate_file(file_path, file_content, "controller")
    -- create route
    file_path = "app/routes/" .. name .. "_routes.lua"
    file_content = route_str or string.gsub(route_content, "{{MNAME}}", name)
    generate_file(file_path, file_content, "route")
end

-- delete model, controller and route
function ModelFactory.delete(name, ver)
    ver = ver or 1
    -- delete model
    local file_path = "app/models/" .. name .. ".lua"
    local f_exist = io.open(file_path, "r")
    if f_exist == nil then
        print(ansicolors("%{red}not exist%{reset} " .. file_path))
        return
    end
    io.close(f_exist)
    local cmd = "rm " .. file_path
    os.execute(cmd)
    print(ansicolors("%{green}delete%{reset} " .. file_path))
    -- delete controller
    file_path = "app/controllers/" .. ver .. "/" .. name .. "_controller.lua"
    f_exist = io.open(file_path, "r")
    if f_exist == nil then
        print(ansicolors("%{red}not exist%{reset} " .. file_path))
        return
    end
    io.close(f_exist)
    cmd = "rm " .. file_path
    os.execute(cmd)
    print(ansicolors("%{green}delete%{reset} " .. file_path))
    -- delete route
    file_path = "app/routes/" .. name .. "_routes.lua"
    f_exist = io.open(file_path, "r")
    if f_exist == nil then
        print(ansicolors("%{red}not exist%{reset} " .. file_path))
        return
    end
    io.close(f_exist)
    cmd = "rm " .. file_path
    os.execute(cmd)
    print(ansicolors("%{green}delete%{reset} " .. file_path))
end

return ModelFactory
