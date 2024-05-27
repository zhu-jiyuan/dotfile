local map = vim.keymap.set
local Runcode = require("runcode")

-- opt args
local opt = { noremap = true, silent = true }

-- setting
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
map("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })
-- ESC
map("i", "<C-c>", "<ESC>", opt)

map("n", "<Esc>", "<cmd>noh<CR>")

-- map('i', '<CAPSLOCK>', '<ESC>', opt)
map("n", "j", [[v:count ? 'j' : 'gj']], { noremap = true, expr = true })
map("n", "k", [[v:count ? 'k' : 'gk']], { noremap = true, expr = true })
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

--- save
map("n", " ", "<NOP>", opt)

-- nvim-tree
map("n", "<leader>e", ":Oil<CR>", opt)

-- run code
map("n", "<F5>", Runcode.runcode, opt)


-- bufferline
-- map('n', '<leader>1' , ':BufferLineGoToBuffer 1<CR>', opt)
-- map('n', '<leader>2' , ':BufferLineGoToBuffer 2<CR>', opt)
-- map('n', '<leader>3' , ':BufferLineGoToBuffer 3<CR>', opt)
-- map('n', '<leader>4' , ':BufferLineGoToBuffer 4<CR>', opt)
-- map('n', '<leader>5' , ':BufferLineGoToBuffer 5<CR>', opt)
-- map('n', '<leader>6' , ':BufferLineGoToBuffer 6<CR>', opt)
-- map('n', '<leader>7' , ':BufferLineGoToBuffer 7<CR>', opt)
-- map('n', '<leader>8' , ':BufferLineGoToBuffer 8<CR>', opt)
-- map('n', '<leader>9' , ':BufferLineGoToBuffer 9<CR>', opt)
-- map('n', '<leader>$' , ':BufferLineGoToBuffer -1<CR>', opt)
-- map('n', '<C-h>', ':BufferLineCyclePrev<CR>', opt)
-- map('n', '<C-l>', ':BufferLineCycleNext<CR>', opt)
-- map('n', '<C-t>o', ':BufferLineCloseOthers<CR>', opt)
-- map('n', '<C-t>l', ':BufferLineCloseLeft<CR>', opt)
-- map('n', '<C-t>r', ':BufferLineCloseRight<CR>', opt)

-- telescope
-- see plugins/telescope.lua
-- map('n', '<leader>ff', ':Telescope find_files<CR>', opt)
-- map('n', '<leader>fg', ':Telescope live_grep<CR>', opt)
-- map('n', '<leader>fb', ':Telescope buffers<CR>', opt)
-- map('n', '<leader>fh', ':Telescope help_tags<CR>', opt)
