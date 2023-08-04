local settings = [[
--------------------------------------------------------------------------------
-- Settings defined here are environment dependent. Inside of your application,
-- `Gin.settings` will return the ones that correspond to the environment
-- you are running the server in.
--------------------------------------------------------------------------------

local Settings = {}

Settings.development = {
    code_cache = false,
    port = 7200,
    expose_api_console = true,
    jwt_secret = 'secret'
}

Settings.test = {
    code_cache = true,
    port = 7201,
    expose_api_console = false,
    jwt_secret = 'secret'
}

Settings.production = {
    code_cache = true,
    port = 80,
    expose_api_console = false,
    jwt_secret = 'secret'
}
return Settings
]]
return settings
