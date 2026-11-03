---
name: excalidraw-with-me
description: My personal Excalidraw drawing style, habits and caveats. Load whenever Excalidraw is involved — creating, editing or reviewing an .excalidraw file, or drawing any Excalidraw diagram.
---

# Excalidraw

## Style

- **Learning / analysis** (default): clear structure, smooth flows, simple, the key point stands out — but never monotonous.
- **Presentation / whiteboard**: the same, plus cute, hand-drawn touches.
- Handwriting fonts (Excalifont).
- For inspiration, look at Excalidraw's own showcase scenes in `examples/` ([flowchart](examples/flowchart.png), [mind map](examples/mindmap.png), [cards](examples/cards.png)). Take the feel, not the exact colors.

## Caveats

- **Prefer an `.excalidraw` file over the Excalidraw MCP.** The MCP measures text before the font loads, so its labels come out clipped or overlapping and have to be fixed one by one in the browser (double-click the text, then Esc).
- **Excalidraw clips text wider than its stored width**, so size text generously.
- **Bind text and arrows both ways** (`containerId` ↔ `boundElements`, `startBinding` / `endBinding` ↔ `boundElements`), or they come apart when a box is moved.
- **Deliver to Excalidraw+**: import the file into the user's `byclaude` collection and give the scene link. If that isn't possible, save it locally, give the path, and say it still needs to go into `byclaude`.
