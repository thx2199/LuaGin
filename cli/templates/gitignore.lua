-- .gitignore template
local gitignore = [[
# gin
client_body_temp
fastcgi_temp
logs
proxy_temp
tmp
uwsgi_temp

# vim
.*.sw[a-z]
*.un~
Session.vim

# textmate
*.tmproj
*.tmproject
tmtags

# OSX
.DS_Store
._*
.Spotlight-V100
.Trashes
*.swp
# db
db/schemas/*.lua
]]

return gitignore
