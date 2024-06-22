
-- 添加lua搜索路径

--local home = os.getenv("HOME")
--local path = home .. "/.config/nvim/"
--package.path = path .. "?.lua;"

-- 导入键位&&设置&&插件

require "settings"
require "lazynvim"
require "keymaps"
require "autocmd"
