# GIN

fork from github.
[GIN](https://github.com/ostinelli/gin)

## bugfixes

1. Fixed the adapter's col_id bug.

## add features

1. Add excluded columns and model filter to customize model view.
2. Add model generation helpers,add model/controller/route automaticly.
3. Add JWT access.
4. 支持添加系统内置的常用model，这些model的template内置再gin.cli.templates内
   - 支持增加migrate sql
5. 修改conf模版，增加更多的api router入口以及静态资源入口
6. 增加查询语句类型的支持，可支持类似Django的 `field__gt`、`field__lk` 查询
## todo

1. ORM's powerful search,like Q.


## 注意
0. 部署
~~~
apt install -y luarocks lua5.1-dbi-mysql
luarocks install luafilesystem
luarocks install ansicolors
luarocks install luadbi
cd /usr/local/openresty
git clone https://github.com/thx2199/LuaGin.git
ln -s /usr/local/openresty/gin /usr/local/openresty/lualib
ln -s /usr/local/openresty/gin/bin/gin /usr/local/bin
ln -s /usr/local/openresty/gin /usr/local/share/lua/5.1
opm install spacewander/lua-resty-rsa
opm install SkyLothar/lua-resty-jwt
opm install ledgetech/lua-resty-http
~~~
   - 运行出现`ERROR: Could not start Gin app on port 3001 (is it running already?).`提示
   请检查`nginx`命令是否在全局路径里？可以考虑替换为openresty
   - fix：替换为openresty

1. migrate模块

由于migrate模块在cli中使用，因此没办法使用ngx下的resty.mysql模块，
需要使用Adapter_detached （require 'gin.core.detached'）即luadbi
-- **坑** --
原项目只安装了老版本的luadbi，会报错误：` /usr/local/share/lua/5.1/DBI.lua:53: Cannot load driver MySQL. Available drivers are: (None)`，缺少mysql驱动
需要：
```bash
# 安装luadbi新版本
sudo luarocks install luadbi  
# 安装dbi-mysql
sudo apt install lua5.1-dbi-mysql
```
考虑用resty运行命令行，则可不需要luadbi的依赖 (已经测试！）
但resty命令行运行nginx会有问题
`ERROR: Could not start Gin app on port 7200 (is it running already?).`
实际运行成功。即调用os.excute返回有问题

2. opm安装0.22版本的openresty/lua-resty-mysql，会报
`failed to connect to mysql: Client does not support authentication protocol requested by server; consider upgrading MySQL client` 
卸载后ok！注意依赖问题；
3. config未设置resolver，因此host如果不是127.0.0.1而是localhost将连接失败。


## TODO

- ~~cli 在生成model时，对应生成一下model的migration模板；~~ 应当重写使schema可用。
- 精简掉detached，全部使用resty-cli，修复resty启动项目的报错。预计会减少项目复杂度和依赖

## changelog
2023.4.4 增加命令 `gin del model ***`，删除一个模型及路由
2023.4.5 增加一个start指令:`gin start --cors`，使服务端能够接受跨域请求，以利于调试；修改launcher的代码，去除之前无用的env参数，使代码易于理解。