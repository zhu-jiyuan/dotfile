
local M = {}
local option = vim.opt
local buffer = vim.b
local global = vim.g

M.option = option
M.buffer = buffer
M.global = global


-- 文件编码格式

option.encoding = "UTF-8"
buffer.fileencoding = "UTF-8"

-- tab设置为4个空格

option.tabstop = 4
option.softtabstop = 4
option.shiftround = true

option.undodir = os.getenv("HOME") .. "/.vim/undodir"
option.undofile = true
-- 显示行号

option.number = true

-- 使用相对行号

option.relativenumber = true

-- 剪切板设置

option.clipboard = "unnamedplus"

-- Preview substitutions live, as you type!
option.inccommand = "split"

-- 高亮所在行

option.cursorline = true

-- 显示左侧图标指示列

option.signcolumn = "yes"

-- 右侧参考线

option.colorcolumn = "160"

-- 自动加载外部修改
option.autoread = true
option.title = true

-- >> << 时移动长度

option.shiftwidth = 4

-- 空格替代

option.expandtab = true

-- 新行对齐当前行

option.autoindent = true
option.smartindent = true

-- 搜索大小写不敏感，除非包含大写

option.ignorecase = true
option.smartcase = true

-- 搜索高亮

option.hlsearch = true
option.incsearch = true

-- 命令模式行高

option.cmdheight = 1

-- 禁止创建备份文件

option.backup = false
option.writebackup = false
option.swapfile = false
-- 换行显示
option.wrap = false

-- smaller updatetime
option.updatetime = 300
option.timeoutlen = 500
option.splitbelow = true
option.splitright = true

-- 自动补全不自动选中

option.completeopt = "menu,menuone,noselect,noinsert"
option.termguicolors = true

-- 样式

--opt.background = "dark"
--opt.termguicolors = true
--opt.termguicolors = true

-- 不可见字符的显示，这里只把空格显示为一个点

option.list = false
option.listchars = "space:·,tab:>-"
option.wildmenu = true
-- opt.shortmess = vim.o.shortmess .. "c"

-- 代码折叠
-- option.foldmethod = "expr"
-- option.foldexpr = "nvim_treesitter#foldexpr()"
-- option.foldcolumn = "1"
-- -- opt.foldtext = ""
--
-- option.foldnestmax = 3
-- option.foldlevel = 99
-- option.foldlevelstart = 10

-- option.exrc = true
-- 补全显示10行

-- opt.pumheight = 10

-- Leader键
--
global.mapleader = " "
global.maplocalleader = " "

-- vimgrep
global.grepprg = "rg --vimgrep --smart-case"
global.grepformat = "%f:%l:%c:%m"


return M

