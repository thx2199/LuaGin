local Gin = require 'gin.core.gin'
local nginx_config = [[
pid ]] .. Gin.app_dirs.tmp .. [[/{{GIN_ENV}}-nginx.pid;

# This number should be at maxium the number of CPU on the server
worker_processes 1;

events {
    # Number of connections per worker
    worker_connections 4096;
}
http {
    # use sendfile
    sendfile on;

    # Gin initialization
    {{GIN_INIT}}
    init_worker_by_lua_file init/init.lua;
    server {
        # List port
        listen {{GIN_PORT}};

        # Access log with buffer, or disable it completetely if unneeded
        access_log logs/{{GIN_ENV}}-access.log combined buffer=16k;
        # access_log off;

        # Error log
        error_log logs/{{GIN_ENV}}-error.log;
        # cors should be enabled if cors is enabled in the config
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS, PUT, DELETE' always;
        # A custom API Entry.
        location ~ ^/api/append/([-_a-zA-Z0-9/]+) {
            # 准入阶段完成参数验证
            access_by_lua 'require(\"config/access\").auth()';
            # client_max_body_size 100M;
            #内容生成阶段
            content_by_lua_file ./lib/api/$1.lua;
        }
        # internal api entry
        location ~ ^/api/internal/([-_a-zA-Z0-9/]+) {
            internal;
            content_by_lua_file ./lib/api/internal/$1.lua;
        }
        # Gin runtime
        {{GIN_RUNTIME}}
        # Static files
        location /assets/ {
            alias ./files/;
            autoindex off;
            expires 30d;
        }
        #root
        location / {
            #下面的这行固定, 就这么写
            root ./web;
        }
    }

    # set temp paths
    proxy_temp_path tmp;
    client_body_temp_path tmp;
    fastcgi_temp_path tmp;
    scgi_temp_path tmp;
    uwsgi_temp_path tmp;
}
]]

return nginx_config
