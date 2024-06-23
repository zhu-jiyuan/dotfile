local config = {
    lua = "lua %",
    python = "python3 %",
    go = "go run %",
}

local M = {}

function M.vspilt()
    vim.cmd("set splitright")
    vim.cmd("vsplit")
end

function M.runcode()
	local file_type = vim.bo.filetype
    local cmd = config[file_type]

    if cmd then
        M.vspilt()
        vim.cmd("term " .. cmd)
    else
		vim.print(string.format("runcode is not supported for %s filetype.", file_type))
	end
end

return M
