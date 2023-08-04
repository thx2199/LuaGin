-- perf
local require = require
local function tappend(t, v) t[#t + 1] = v end


local SqlOrm = {}

--- Define a model.
-- The default primary key is set to 'id'
-- @param sql_database the sql database instance
-- @param table_name the name of the table to create a lightweight orm mapping for
-- @param id_col primary key,default is `id`
-- set to arbitrary string to use any other column as primary key
function SqlOrm.define_model(sql_database, table_name, excludes, id_col)
    local GinModel = {}
    GinModel.__index = GinModel
    -- primary key
    GinModel.__id_col = id_col or 'id'
    -- excludes columns
    GinModel.__excludes = excludes or {}
    -- init
    local function quote(str)
        return sql_database:quote(str)
    end
    local orm = require('gin.db.sql.' .. sql_database.options.adapter .. '.orm').new(table_name, quote)

    function GinModel.new(attrs)
        local instance = attrs or {}
        setmetatable(instance, GinModel)
        return instance
    end

    function GinModel.create(attrs)
        local sql = orm:create(attrs)
        local id_col = GinModel.__id_col
        local id = sql_database:execute_and_return_last_id(sql, id_col)
        local model = GinModel.new(attrs)
        model[id_col] = id

        return model
    end

    function GinModel.where(attrs, options)
        local sql = orm:where(attrs, options)
        local results = sql_database:execute(sql)
        local models = {}
        local cjson = require 'cjson.safe'
        cjson.encode_empty_table_as_object(true)
        -- 将可能转换为json字串的转换为table,这里有一个坑，例如字符串'NAN'会被decode为nan
        -- 应当只对包含{}的字符串进行decode
        for _, result in ipairs(results) do
            for k, v in pairs(result) do
                local smatch = string.match
                if type(v) == 'string' and smatch(v, '^%{.*%}$') then
                    local ok, json = pcall(cjson.decode, v)
                    if ok and json then
                        result[k] = json
                    end
                end
            end
            tappend(models, GinModel.new(result))
        end
        return models
    end

    function GinModel.all(options)
        return GinModel.where({}, options)
    end
    function GinModel.count(attrs)
        local sql = orm:count(attrs)
        local results = sql_database:execute(sql)
        return results[1].count
    end
    function GinModel.find_by(attrs, options)
        local merged_options = { limit = 1 }
        if options and options.order then
            merged_options.order = options.order
        end

        return GinModel.where(attrs, merged_options)[1]
    end

    function GinModel.delete_where(attrs, options)
        local sql = orm:delete_where(attrs, options)
        return sql_database:execute(sql)
    end

    function GinModel.delete_all(options)
        return GinModel.delete_where({}, options)
    end
    local cjson = require 'cjson.safe'
    -- foreign_keys query
    local function get_foreign_key_info()
        local db_name = sql_database.options.database
        local sql = string.format([[
            SELECT
                TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
            FROM
                information_schema.KEY_COLUMN_USAGE
            WHERE
                CONSTRAINT_SCHEMA = '%s' AND
                REFERENCED_TABLE_NAME = '%s';
        ]], db_name, table_name)
        local res = sql_database:execute(sql)
        return res
    end
    -- options is where_attrs
    function GinModel.update_where(attrs, options)
        -- get origin record
        local origin = GinModel.find_by(options)
        -- get foreign keys
        local foreign_keys = get_foreign_key_info()
        -- update foreign keys
        for _, foreign_key in ipairs(foreign_keys) do
            local v = attrs[foreign_key.COLUMN_NAME]
            local origin_v = origin[foreign_key.COLUMN_NAME]
            if not v or not origin_v or v == origin_v then
                -- value not change
                goto continue
            end
            v = (type(v)=='string' and quote(v)) or v
            origin_v = (type(origin_v)=='string' and quote(origin_v)) or origin_v
            local fsql = string.format("UPDATE %s SET %s = %s WHERE %s = %s;",
                foreign_key.TABLE_NAME,
                foreign_key.COLUMN_NAME,
                v,
                foreign_key.REFERENCED_COLUMN_NAME,
                origin_v)
            -- ngx.log(ngx.ERR,fsql)
            sql_database:execute(fsql)
            ::continue::
        end
        local sql = orm:update_where(attrs, options)
        return sql_database:execute(sql)
    end

    function GinModel:save()
        local id_col = GinModel.__id_col
        local id = self[id_col]
        if id ~= nil then
            self[id_col] = nil
            local result = GinModel.update_where(self, { [id_col] = id })
            self[id_col] = id
            return result
        else
            return GinModel.create(self)
        end
    end

    function GinModel:delete()
        local id_col = GinModel.__id_col
        local id = self[id_col]
        if id ~= nil then
            return GinModel.delete_where({ [id_col] = id })
        else
            error("cannot delete a model without an id")
        end
    end

    -- a filter used to customize the model view.
    -- @param filter a function that takes a model and returns a filtered model
    function GinModel:filter(filter)
        -- remove excludes
        local excludes = GinModel.__excludes
        for _, exclude in ipairs(excludes) do
            self[exclude] = nil
        end
        -- customize filter
        filter = filter or function(model) return model end
        return filter(self)
    end

    return GinModel
end

return SqlOrm
