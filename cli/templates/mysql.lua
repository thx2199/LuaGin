local mysql = [[
local SqlDatabase = require 'gin.db.sql'
local Gin = require 'gin.core.gin'

-- First, specify the environment settings for this database, for instance:
local DbSettings = {
    development = {
        adapter = 'mysql',
        host = "127.0.0.1",
        port = 3306,
        database = "{{DBNAME}}_dev",
        user = "{{DBUSER}}",
        password = "{{DBPASS}}",
        pool = 5
    },

    test = {
        adapter = 'mysql',
        host = "127.0.0.1",
        port = 3306,
        database = "{{DBNAME}}_test",
        user = "{{DBUSER}}",
        password = "{{DBPASS}}",
        pool = 5
    },

    production = {
        adapter = 'mysql',
        host = "127.0.0.1",
        port = 3306,
        database = "{{DBNAME}}_prod",
        user = "{{DBUSER}}",
        password = "{{DBPASS}}",
        pool = 5
    }
}

-- Then initialize and return your database:
local MySql = SqlDatabase.new(DbSettings[Gin.env])

return MySql
]]

return mysql
