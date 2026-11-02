-- Fuzzy-find any tab with fzf in a floating pane, like tmux popup + fzf.
-- This action only opens the pane; tabfind.sh does the rest.

local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local PICKER = config_home .. "/rex/tabfind.sh"
local PANEL_LABEL = "tabfind" -- tabfind-list.lua leaves panes with this label out.
-- The panel's shell doesn't load mise, which is where fzf comes from.
local MISE_SHIMS = os.getenv("HOME") .. "/.local/share/mise/shims"

-- The panel's share of the window, so the tab behind it stays visible.
local WIDTH, HEIGHT = 0.88, 0.9

-- Close any panel left open in this session, such as in a tab since switched
-- away from. Returns whether one was open in the tab being looked at.
local function close_panels(session_id)
	local view, err = rex.session.view({ session_id = session_id })
	if view == nil then
		error(err, 0)
	end
	local here = false
	for _, window in ipairs(view.windows) do
		for _, layer in ipairs(window.layers or {}) do
			for _, block in ipairs(layer.blocks or {}) do
				if block.label == PANEL_LABEL then
					rex.session.close_layer({ session_id = session_id, layer_id = layer.layer_id })
					here = here or window.window_id == view.active_window_id
					break
				end
			end
		end
	end
	return here
end

rex.action({
	name = "tabfind",
	title = "Find Tab…",
	description = "Fuzzy-find a tab in any session with fzf and go to it.",
	category = "Tab",
	keywords = "fzf fuzzy search switch jump goto window",
	run = function(ctx)
		-- The key closes the panel when it's already open.
		if close_panels(ctx.session_id) then
			return
		end

		-- From the CLI, the client is that short-lived command rather than an app,
		-- which can't show another session.
		local from_app = ctx.origin == "key" or ctx.origin == "palette"
		local client = from_app and ctx.client_id or ""

		local _, err = rex.session.new_layer({
			bounds = { (1 - WIDTH) / 2, (1 - HEIGHT) / 2, WIDTH, HEIGHT },
			focus = true,
			layout = rex.layout.block({
				flavor = "com.superlogical.terminal.shell",
				label = PANEL_LABEL,
				options = {
					command = { "sh", PICKER, client, ctx.block_id or "" },
					path_prepend = { MISE_SHIMS },
				},
			}),
		})
		if err ~= nil then
			error(err, 0)
		end
	end,
})
