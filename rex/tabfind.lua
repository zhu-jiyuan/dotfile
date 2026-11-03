-- Fuzzy-find any tab with fzf in a floating pane, like tmux popup + fzf.
-- This action only opens the pane; tabfind.sh does the rest.

local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local PICKER = config_home .. "/rex/tabfind.sh"
local TERMINAL = "com.superlogical.terminal"

-- The panel's share of the window, so the tab behind it stays visible.
local WIDTH, HEIGHT = 0.88, 0.9
-- Rows the panel needs around the tab's screen: search line, list, hint line.
local CHROME_ROWS = 9

-- How many points to shrink the panel's font so a tab's whole screen fits in it.
-- Returns the number of font steps (one point each) and the tab's rows.
local function shrink_steps(block_id)
	local size = block_id and rex.block.call(TERMINAL, "size", { block_id = block_id })
	if not size or not size.rows then
		return 0, nil
	end
	local r = rex.exec({ "defaults", "read", "com.superlogical.rex", "Workspace.terminalFontPointSize" })
	local points = r and r.ok and tonumber(r.stdout)
	if not points then
		return 0, size.rows
	end
	local scale = math.min(WIDTH, HEIGHT * size.rows / (size.rows + CHROME_ROWS))
	return math.ceil(points * (1 - scale)), size.rows
end

rex.action({
	name = "tabfind",
	title = "Find Tab…",
	description = "Fuzzy-find a tab in any session with fzf and go to it.",
	category = "Tab",
	keywords = "fzf fuzzy search switch jump goto window",
	run = function(ctx)
		-- From the CLI, the client is that short-lived command rather than an app,
		-- and it has no font to change.
		local from_app = ctx.origin == "key" or ctx.origin == "palette"
		local client = from_app and ctx.client_id or ""
		local steps, rows = shrink_steps(ctx.block_id)

		local _, err = rex.session.new_layer({
			bounds = { (1 - WIDTH) / 2, (1 - HEIGHT) / 2, WIDTH, HEIGHT },
			focus = true,
			layout = rex.layout.block({
				flavor = "com.superlogical.terminal.shell",
				options = { command = { "sh", PICKER, client, tostring(rows or "") } },
			}),
		})
		if err ~= nil then
			error(err, 0)
		end

		-- Font actions hit whichever pane has focus in the app. It only moves focus
		-- to the panel once it hears about the panel, so give it a moment first.
		if from_app and steps > 0 then
			rex.exec({ "sleep", "0.3" })
			for _ = 1, steps do
				rex.client.queue("client.font.decrease")
			end
		end
	end,
})
