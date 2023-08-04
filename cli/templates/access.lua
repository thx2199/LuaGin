-- ref:https://github.com/ubergarm/openresty-nginx-jwt/blob/master/bearer.lua
local access = [[
local cjson = require 'cjson'
local jwt = require 'resty.jwt'
local Gin = require 'gin.core.gin'
local ngx = ngx
-- screct
local secret = Gin.settings.jwt_secret
-- uri white list
local function ignore_uri(uri)
    local white_list = {
        ['/api/login'] = true,
        ['/api/register'] = true,
        ['/api/logout'] = true
    }
    if white_list[uri] then
        return true
    end
    return false
end

local _M = {}
function _M.auth()
    local uri = ngx.var.request_uri
    if ignore_uri(uri) then
        return
    end
    local auth_header = ngx.var.http_Authorization or ''
    local _, _, token = string.find(auth_header, "Bearer%s+(.+)")
    local errmsg = "missing JWT token or Authorization header"
    local ret = { code = 1, msg = errmsg }
    do
        if not token then
            goto not_authorized
        end
        -- validate any specific claims you need here
        -- https://github.com/SkyLothar/lua-resty-jwt#jwt-validators
        local validators = require "resty.jwt-validators"
        local claim_spec = {
            -- validators.set_system_leeway(15), -- time in seconds
            exp = validators.is_not_expired(),
            -- iat = validators.is_not_before(),
            -- iss = validators.opt_matches("^http[s]?://yourdomain.auth0.com/$"),
            -- sub = validators.opt_matches("^[0-9]+$"),
            -- name = validators.equals_any_of({ "John Doe", "Mallory", "Alice", "Bob" })
        }

        local jwt_obj = jwt:verify(secret, token, claim_spec)
        if jwt_obj["verified"] then
            return
        end
        ret.msg = jwt_obj.reason
    end
    ::not_authorized::
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.header.content_type = "application/json; charset=utf-8"
    ngx.say(cjson.encode(ret))
    -- ngx.exit(ngx.HTTP_UNAUTHORIZED)
    ngx.exit(200)
end

return _M
]]
return access
