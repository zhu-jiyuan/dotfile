local map = vim.keymap.set

-- opt args
local opt = { noremap = true, silent = true }

-- setting
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- ESC
map('i', '<C-c>', '<ESC>', opt)



-- map('i', '<CAPSLOCK>', '<ESC>', opt)
map("n", "j", [[v:count ? 'j' : 'gj']], { noremap = true, expr = true })
map("n", "k", [[v:count ? 'k' : 'gk']], { noremap = true, expr = true })
--- save
map('n', '<C-s>', ':w<CR>', opt)
map('n', ' ', '<NOP>', opt)

-- nvim-tree 
map('n', '<leader>e' , ':NvimTreeToggle<CR>', opt)

-- bufferline
map('n', '<leader>1' , ':BufferLineGoToBuffer 1<CR>', opt)
map('n', '<leader>2' , ':BufferLineGoToBuffer 2<CR>', opt)
map('n', '<leader>3' , ':BufferLineGoToBuffer 3<CR>', opt)
map('n', '<leader>4' , ':BufferLineGoToBuffer 4<CR>', opt)
map('n', '<leader>5' , ':BufferLineGoToBuffer 5<CR>', opt)
map('n', '<leader>6' , ':BufferLineGoToBuffer 6<CR>', opt)
map('n', '<leader>7' , ':BufferLineGoToBuffer 7<CR>', opt)
map('n', '<leader>8' , ':BufferLineGoToBuffer 8<CR>', opt)
map('n', '<leader>9' , ':BufferLineGoToBuffer 9<CR>', opt)
map('n', '<leader>$' , ':BufferLineGoToBuffer -1<CR>', opt)
map('n', '<C-h>', ':BufferLineCyclePrev<CR>', opt)
map('n', '<C-l>', ':BufferLineCycleNext<CR>', opt)
map('n', '<C-t>o', ':BufferLineCloseOthers<CR>', opt)
map('n', '<C-t>l', ':BufferLineCloseLeft<CR>', opt)
map('n', '<C-t>r', ':BufferLineCloseRight<CR>', opt)

-- telescope
-- see plugins/telescope.lua
-- map('n', '<leader>ff', ':Telescope find_files<CR>', opt)
-- map('n', '<leader>fg', ':Telescope live_grep<CR>', opt)
-- map('n', '<leader>fb', ':Telescope buffers<CR>', opt)
-- map('n', '<leader>fh', ':Telescope help_tags<CR>', opt)
