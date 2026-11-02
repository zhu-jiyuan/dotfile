require("tabfind")

-- ctrl+g is the prefix, like tmux's.
rex.bind("ctrl+g>w", "tabfind")
rex.bind("ctrl+g>c", "client.tab.new")
rex.bind("ctrl+g>x", "client.tab.close")
rex.bind("ctrl+g>p", "client.tab.previous")
rex.bind("ctrl+g>n", "client.tab.next")
