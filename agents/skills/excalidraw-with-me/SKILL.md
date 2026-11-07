---
name: excalidraw-with-me
description: My personal Excalidraw drawing style, habits and caveats. Load whenever Excalidraw is involved — creating, editing or reviewing an Excalidraw+ scene or an .excalidraw file, or drawing any Excalidraw diagram.
---

# Excalidraw

## Style

- **Learning / analysis** (default): clear structure, smooth flows, simple, the key point stands out — but never monotonous.
- **Presentation / whiteboard**: the same, plus cute, hand-drawn touches.
- Handwriting fonts (Excalifont).
- For inspiration, look at Excalidraw's own showcase scenes in `examples/` ([flowchart](examples/flowchart.png), [mind map](examples/mindmap.png), [cards](examples/cards.png)). Take the feel, not the exact colors.

## Tools

- **Prefer the Excalidraw+ MCP** (`https://api.excalidraw.com/api/v1/mcp`, tools such as `create_diagram`, `edit_scene_content`, `take_screenshot`). Its text measurement is fixed, and it writes straight into Excalidraw+.
  - Before the first write, call the matching guide: `read_diagram_format`, `read_presentation_format` or `read_freeform_format`.
  - Flowcharts and architecture maps: `create_diagram` (it lays out the graph and binds the arrows). Tweaks, swimlanes, timelines: `edit_scene_content`. Presentations: one frame per slide via `create_slide`.
  - After substantial writes, `take_screenshot` and fix clipping, overlaps or arrow routing before handing over.
- **The open-source Excalidraw MCP doesn't count** (`create_view` / `read_me`): it only renders in the chat and can't save into Excalidraw+.
- **Fall back to an `.excalidraw` file** when the Excalidraw+ MCP isn't connected.

## Caveats

- **Excalidraw clips text wider than its stored width**, so size text generously.
- **Keep text and arrows bound**, or they come apart when a box is moved. MCP: put shape text in `label`, and give arrows `startBinding` / `endBinding` (`tempId` for shapes added in the same call). File: bind both ways (`containerId` ↔ `boundElements`, `startBinding` / `endBinding` ↔ `boundElements`).
- **Deliver to Excalidraw+**: the scene goes into the user's `byclaude` collection, and the user gets the scene link. MCP: create it there (`list_collections` → `create_collection_scene`). Don't turn on public sharing unless asked. File: import it into `byclaude`; if that isn't possible, save it locally, give the path, and say it still needs to go into `byclaude`.
