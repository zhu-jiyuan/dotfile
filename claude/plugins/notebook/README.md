# Notebook

A personal Claude Code mod in the spirit of [Kevin Ngo's notebook screenshots](https://x.com/kevin_t_ngo/status/2122463487037464722). All art is original; nothing is copied from his mods.

In the desktop app it draws ruled notebook paper with a red margin and punch holes, puts your messages on yellow sticky notes, and gives every row a hand-drawn critter: inky (you), sunny (Claude), pip the hedgehog (reads and searches), kero the frog (edits), miso the cat (commands) and dot the snail (everything else).

The `this page` pane opens on its own and with `/notebook`: today's date, a taped polaroid of the day's critter, tallies of edits, reads, searches and runs, the live to-do list, and a pencil that shortens as context runs out.

Light mode only: the sticky notes are light paper, and the look sets the app to light.

In terminal Claude Code the same notes, critters and page draw too. The window takes the notebook's paper and ink colors while Claude runs (standard OSC 10/11/12 escapes, this window only) and gets the terminal's own back on exit. In fullscreen mode, terminals that speak the kitty graphics protocol (kitty, Rex) also get faint ruled lines and a red margin, laid under the text as pictures. Ghostty is left out: its own config in `dotfile/ghostty` already lays ruled paper under every window. These are written past Claude's renderer, so they are written only while Claude is idle; a write in the middle of a frame would tear it. The critters are pictures in terminals that draw images (Ghostty, kitty, iTerm2 3.5+) and emoji elsewhere, such as Rex: 🐙 inky, 🌻 sunny, 🦔 pip, 🐸 kero, 🐱 miso, 🐌 dot. In the terminal a critter sits over its row's bullet, so replies keep their full width for tables and code. The page docks on the right in fullscreen mode from 110 columns, and `/notebook` opens it anywhere.

`hooks/images.ts` holds the critters as PNGs for the terminal. After changing the art in `hooks/critters.ts`, rebuild it:

```bash
cd scripts && npm i && npx tsx build-images.ts
```

```bash
claude plugin install notebook@dotfile-local --scope user
```
