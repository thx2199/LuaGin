-- perf
local next = next
local pairs = pairs
local setmetatable = setmetatable
local tconcat = table.concat
local type = type
local function tappend(t, v) t[#t + 1] = v end
local cjson = require 'cjson.safe'
local ngx_re = require 'ngx.re'
-- field and values helper, for update
local function kv_update_helper(quote, attrs, concat)
    local fav = {}
    for field, value in pairs(attrs) do
        local key_pair = {}
        tappend(key_pair, field)
        if value and type(value) ~= 'userdata' then
            if type(value) == "table" then
                value = "'"..cjson.encode(value).."'" -- json字段不使用quote，因为quote会把json的双引号转义
            elseif type(value) ~= 'number' then
                value = quote(value)
            end -- json字段
            tappend(key_pair, "=")
            tappend(key_pair, value)
            tappend(fav, tconcat(key_pair))
        end
    end
    return tconcat(fav, concat)
end
-- field and values helper, for where
-- support more logical operator, like 'like', 'in', 'between', 'not in', 'not between' and so on
-- use __ for split the key and operator
local function kv_where_helper(quote, attrs, concat)
    local fav = {}
    for field, value in pairs(attrs) do
        local key_pair = {}
        if value and type(value) ~= 'userdata' then
            local kop = ngx_re.split(field, '__') or {}
            local fkey, op = kop[1], kop[2]
            op = 'not' == op and '!=' or op -- 'not' operator is '!=
            op = 'lk' == op and 'LIKE' or op -- 'lk' operator is 'LIKE' 
            op = 'nlk' == op and 'NOT LIKE' or op -- 'nlk' operator is 'NOT LIKE'
            op = 'in' == op and 'IN' or op -- 'in' operator is 'IN'
            op = 'nin' == op and 'NOT IN' or op -- 'nin' operator is 'NOT IN'
            op = 'btw' == op and 'BETWEEN' or op -- 'btw' operator is 'BETWEEN'
            op = 'nbtw' == op and 'NOT BETWEEN' or op -- 'nbtw' operator is 'NOT BETWEEN'
            op = 'gt' == op and '>' or op -- 'gt' operator is '>'
            op = 'lt' == op and '<' or op -- 'lt' operator is '<'
            op = 'gte' == op and '>=' or op -- 'gte' operator is '>='
            op = 'lte' == op and '<=' or op -- 'lte' operator is '<='
            -- that's all
            op = op or '=' -- default operator is '='
            tappend(key_pair, fkey)
            -- 处理value
            if type(value) == "table" then
                if op == 'IN' or op == 'NOT IN' then
                    value = "("..tconcat(value, ',')..")"
                elseif op == 'BETWEEN' or op == 'NOT BETWEEN' then
                    value = value[1].." AND "..value[2]
                else -- 此时只能假设其为json
                    value = "'"..cjson.encode(value).."'" -- json字段不使用quote，因为quote会把json的双引号转义
                end
            elseif type(value) ~= 'number' then
                value = quote(value)
            end -- json字段
            tappend(key_pair, op)
            tappend(key_pair, value)
            tappend(fav, tconcat(key_pair, ' '))
        end
    end
    return tconcat(fav, concat)
end
-- where
local function build_where(self, sql, attrs)
    if attrs ~= nil then
        if type(attrs) == 'table' then
            if next(attrs) ~= nil then -- not empty table
                tappend(sql, " WHERE (")
                tappend(sql, kv_where_helper(self.quote, attrs, ' AND '))
                tappend(sql, ")")
            end
        else
            tappend(sql, " WHERE (")
            tappend(sql, attrs)
            tappend(sql, ")")
        end
    end
end


local SqlCommonOrm = {}
SqlCommonOrm.__index = SqlCommonOrm

function SqlCommonOrm.new(table_name, quote_fun)
    -- init instance
    local instance = {
        table_name = table_name,
        quote = quote_fun
    }
    setmetatable(instance, SqlCommonOrm)

    return instance
end

function SqlCommonOrm:create(attrs)
    -- health check
    if attrs == nil or next(attrs) == nil then
        error("no attributes were specified to create new model instance")
    end
    -- init sql
    local sql = {}
    -- build fields
    local fields = {}
    local values = {}
    for field, value in pairs(attrs) do
        tappend(fields, field)
        if type(value) == "table" then
            value = "'"..cjson.encode(value).."'" -- json字段不使用quote，因为quote会把json的双引号转义
        elseif type(value) ~= 'number' then
            value = self.quote(value)
        end -- json字段
        tappend(values, value)
    end
    -- build sql
    tappend(sql, "INSERT INTO ")
    tappend(sql, self.table_name)
    tappend(sql, " (")
    tappend(sql, tconcat(fields, ','))
    tappend(sql, ") VALUES (")
    tappend(sql, tconcat(values, ','))
    tappend(sql, ");")
    -- hit server
    return tconcat(sql)
end

-- count statement
function SqlCommonOrm:count(attrs)
    -- init sql
    local sql = {}
    -- start
    tappend(sql, "SELECT COUNT(*) AS count FROM ")
    tappend(sql, self.table_name)
    -- where
    build_where(self, sql, attrs)
    -- close
    tappend(sql, ";")
    -- execute
    -- ngx.log(ngx.ERR, tconcat(sql))
    return tconcat(sql)
end
function SqlCommonOrm:where(attrs, options)
    -- init sql
    local sql = {}
    -- start
    tappend(sql, "SELECT * FROM ")
    tappend(sql, self.table_name)
    -- where
    build_where(self, sql, attrs)
    -- options
    if options then
        -- order
        if options.order ~= nil then
            tappend(sql, " ORDER BY ")
            tappend(sql, options.order)
        end
        -- limit
        if options.limit ~= nil then
            tappend(sql, " LIMIT ")
            tappend(sql, options.limit)
        end
        -- offset
        if options.offset ~= nil then
            tappend(sql, " OFFSET ")
            tappend(sql, options.offset)
        end
    end
    -- close
    tappend(sql, ";")
    -- execute
    -- ngx.log(ngx.ERR, tconcat(sql))
    return tconcat(sql)
end

function SqlCommonOrm:delete_where(attrs, options)
    -- init sql
    local sql = {}
    -- start
    tappend(sql, "DELETE FROM ")
    tappend(sql, self.table_name)
    -- where
    build_where(self, sql, attrs)
    -- options
    if options then
        -- limit
        if options.limit ~= nil then
            tappend(sql, " LIMIT ")
            tappend(sql, options.limit)
        end
    end
    -- close
    tappend(sql, ";")
    -- execute
    return tconcat(sql)
end

function SqlCommonOrm:update_where(attrs, where_attrs)
    -- health check
    if attrs == nil or next(attrs) == nil then
        error("no attributes were specified to create new model instance")
    end
    -- init sql
    local sql = {}
    -- start
    tappend(sql, "UPDATE ")
    tappend(sql, self.table_name)
    tappend(sql, " SET ")
    -- updates
    tappend(sql, kv_update_helper(self.quote, attrs, ','))
    -- where
    build_where(self, sql, where_attrs)
    -- close
    tappend(sql, ";")
    -- execute
    return tconcat(sql)
end


return SqlCommonOrm
