local um_content =[[
-- generated by gin
local MySql = require 'db.mysql'
local SqlOrm = require 'gin.db.sql.orm'
    
-- define
return SqlOrm.define_model(MySql, 'users', {'is_deleted','CreatedTime','UpdatedTime','password'})
]]

return um_content