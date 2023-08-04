local migrations_new = [====[
local SqlMigration = {}

-- specify the database used in this migration (needed by the Gin migration engine)
SqlMigration.db = require 'db.mysql'

function SqlMigration.up()
    -- Run your migration
    SqlMigration.db:execute([[
        -- Your SQL here
    ]])
end

function SqlMigration.down()
    -- Run your rollback
    SqlMigration.db:execute([[
        -- Your SQL here
    ]])
end

return SqlMigration
]====]

return migrations_new
