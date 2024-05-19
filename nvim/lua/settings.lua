local opt = vim.opt
-- 文件编码格式

opt.encoding = "UTF-8"
opt.fileencoding = "UTF-8"

-- tab设置为4个空格

opt.tabstop = 4
opt.softtabstop = 4
opt.shiftround = true

opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.undofile = true
-- 显示行号

opt.number = true

-- 使用相对行号

opt.relativenumber = true

-- 剪切板设置

opt.clipboard = "unnamedplus"

-- Preview substitutions live, as you type!
opt.inccommand = "split"

-- 高亮所在行

opt.cursorline = true

-- 显示左侧图标指示列

opt.signcolumn = "yes"

-- 右侧参考线

opt.colorcolumn = "160"

-- 自动加载外部修改
opt.autoread = true

-- >> << 时移动长度

opt.shiftwidth = 4

-- 空格替代

opt.expandtab = true

-- 新行对齐当前行

opt.autoindent = true
opt.smartindent = true

-- 搜索大小写不敏感，除非包含大写

opt.ignorecase = true
opt.smartcase = true

-- 搜索高亮

opt.hlsearch = true
opt.incsearch = true

-- 命令模式行高

opt.cmdheight = 1

-- 禁止创建备份文件

opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.wrap = false

-- smaller updatetime
opt.updatetime = 300
opt.timeoutlen = 500
opt.splitbelow = true
opt.splitright = true

-- 自动补全不自动选中

opt.completeopt = "menu,menuone,noselect,noinsert"

-- 样式

--opt.background = "dark"
--opt.termguicolors = true
--opt.termguicolors = true

-- 不可见字符的显示，这里只把空格显示为一个点

opt.list = false
opt.listchars = "space:·,tab:>-"
opt.wildmenu = true
-- opt.shortmess = vim.o.shortmess .. "c"

-- 代码折叠
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldcolumn = "1"
-- opt.foldtext = ""

opt.foldnestmax = 3
opt.foldlevel = 99
opt.foldlevelstart = 99
-- 补全显示10行

-- opt.pumheight = 10

-- Leader键
--
vim.g.mapleader = " "
vim.g.maplocalleader = " "
