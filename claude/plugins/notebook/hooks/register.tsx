import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, RenderComponent, RenderElement, RenderNode, ResolveInputOf } from 'claude-code'
import type { ActivityState, ActivityTask } from '../types'

import { AVATAR_PX, EMOJI, MASCOTS, MASCOT_PX, avatar, critterFor, pencil, tally } from './critters'
import type { Critter } from './critters'
import { AVATAR_PNG, MASCOT_PNG } from './images'
import { COLOR_PROBLEMS, LOOK, PAPER, SCENE_ID } from './look'
import { TASK_TOOLS, TOOL_KIND, taskChange } from './tasks'
import { LINES_OFF, PAPER_OFF, PAPER_ON, paintTerminal, ruledLines, terminalTraits } from './terminal-paper'

const PANE = 'notebook-page'
const PANE_OPTIONS = { id: PANE, title: 'this page', backgroundColor: '#f6f4ee' }
const TAPE = `<svg xmlns="http://www.w3.org/2000/svg" width="64" height="12" viewBox="0 0 64 12"><defs><pattern id="g" width="6" height="6" patternUnits="userSpaceOnUse"><rect width="6" height="6" fill="#cfe8d2"/><rect width="3" height="3" fill="#b4dbb9"/><rect x="3" y="3" width="3" height="3" fill="#b4dbb9"/></pattern></defs><path d="M1 1L63 0L62 11L2 12Z" fill="url(#g)" opacity="0.9"/></svg>`
const TYPED = new Set(['composer', 'bridge', 'sdk', 'unclassified'])
// A terminal pane docks beside the transcript only in fullscreen from 110 columns.
const DOCK_COLUMNS = 110
const QUIET_MS = 1200

const NOTE = '#f8eba6'
const NOTE_INK = '#2f4f9f'
const TODO = '#f6d9d5'
const PAPER_INK = '#2f2c28'

const activity = atom(
  { plugin: 'notebook', key: 'activity' } as const,
  {
    counts: { read: 0, edit: 0, search: 0, run: 0 },
    phase: 'idle',
    contextLeft: null,
    tasks: [],
    taskSource: null,
  } as ActivityState,
  { shape: 'activity-1' },
)

const DAYS = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
const MONTHS = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec']

function today(): { label: string; seed: number } {
  const d = new Date()
  return { label: `${DAYS[d.getDay()]}, ${MONTHS[d.getMonth()]} ${d.getDate()}`, seed: d.getDate() }
}

const isApp = (surface: string) => surface === 'desktop' || surface === 'mobile'

const VERB: Record<string, [string, string]> = {
  run: ['ran', 'command'],
  read: ['read', 'file'],
  search: ['searched', 'pattern'],
  edit: ['edited', 'file'],
}

function summarize(tools: readonly string[]): string {
  const counts = new Map<string, number>()
  for (const tool of tools) {
    const kind = TOOL_KIND[tool] ?? 'run'
    counts.set(kind, (counts.get(kind) ?? 0) + 1)
  }
  const parts = [...counts].map(([kind, n]) => {
    const [verb, noun] = VERB[kind] ?? ['used', 'tool']
    return `${verb} ${n} ${noun}${n === 1 ? '' : 's'}`
  })
  const line = parts.join(', ')
  return line.charAt(0).toUpperCase() + line.slice(1)
}

function taskMark(task: ActivityTask): { mark: string; color: string } {
  if (task.status === 'completed') return { mark: '☑', color: '#4f8a3b' }
  if (task.status === 'in_progress') return { mark: '▸', color: '#b8382e' }
  return { mark: '☐', color: '#6b5a50' }
}

const tallyText = (n: number) => {
  const shown = Math.min(n, 20)
  return [...Array(Math.ceil(shown / 5)).keys()]
    .map(g => (shown - g * 5 >= 5 ? '卌' : '|'.repeat(shown - g * 5)))
    .join(' ')
}

const pencilText = (percentLeft: number, width: number) => {
  const length = Math.max(1, Math.round(((width - 3) * percentLeft) / 100))
  return { eraser: '█', body: '█'.repeat(length), tip: '▶' }
}

const png = (who: Critter) => ({ png: AVATAR_PNG[who] ?? '' })

// The engine lays a row's text out for the full width, so the critter sits over the row's
// two-cell bullet instead of beside it: anything beside it breaks tables and code.
function inGutter(
  $: EngineInterface,
  e: ResolveInputOf<RenderComponent, 'terminal'>,
  who: Critter,
  row: RenderNode,
  pictures: boolean,
  // Rows open with a one-line gap, so the bullet sits on the second line.
  top = 1,
): RenderElement {
  const { Box, Text, Image } = $.ui.resolve(e)
  return (
    <Box flexDirection="column">
      {row}
      <Box position="absolute" top={top} left={0} width={2} height={1} backgroundColor="#f4f2ec">
        {pictures ? <Image source={png(who)} columns={2} rows={1} alt={EMOJI[who]} /> : <Text>{EMOJI[who]}</Text>}
      </Box>
    </Box>
  )
}

// What the window should show, and what was last written to it. The paper is written past the
// engine, so it waits for a quiet moment: a write in the middle of a frame tears it.
type Ink = { paper: { rows: number; columns: number; ruled: boolean } | null; written: string; transmitted: boolean }

async function paperWhenIdle($: EngineInterface, ink: Ink): Promise<void> {
  if (!ink.paper || (await read($, activity)).phase === 'working') return
  const key = `${ink.paper.rows}x${ink.paper.columns}:${ink.paper.ruled}`
  if (key === ink.written) return
  const first = ink.written === ''
  ink.written = key
  const lines = ink.paper.ruled ? ruledLines(ink.paper.rows, ink.paper.columns, !ink.transmitted) : ''
  ink.transmitted ||= ink.paper.ruled
  await paintTerminal($, (first ? PAPER_ON : '') + lines).catch(() => undefined)
}

export const register: Register = on => {
  let docking = false
  let pictures = false
  let ownPaper = false
  const ink: Ink = { paper: null, written: '', transmitted: false }

  on('session.start', async ($, e, next) => {
    const unpainted = COLOR_PROBLEMS.find(line => line.startsWith("Desktop won't paint"))
    if (unpainted !== undefined) $.ui.toast(unpainted)

    const set = await $.theme.set(LOOK)
    const inApp = (await $.session.surfaces()).some(isApp)
    if (!set.isDrawn && inApp) $.ui.status(set.reason)
    const traits = await terminalTraits($).catch(() => ({ pictures: false, ownPaper: false }))
    pictures = traits.pictures
    ownPaper = traits.ownPaper

    await $.command.register({ name: 'notebook', description: 'Open the notebook page: today, tallies, to-do and pencil left' })
    const { context } = await $.session.usage()
    await update($, activity, state => ({
      ...state,
      contextLeft: context.percent === undefined ? null : 100 - context.percent,
    }))
    if (inApp) void $.ui.open(PANE_OPTIONS)
    return next(e)
  })

  on('session.end', async ($, e, next) => {
    if (ink.written) await paintTerminal($, (ink.transmitted ? LINES_OFF : '') + PAPER_OFF).catch(() => undefined)
    return next(e)
  })

  on('command.run', { command: 'notebook' }, async $ => {
    await $.ui.open(PANE_OPTIONS)
    return {}
  })

  on('turn.start', async ($, e, next) => {
    if (e.agentId === undefined) await update($, activity, state => ({ ...state, phase: 'working' as const }))
    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    if (e.agentId === undefined) {
      await update($, activity, state => ({ ...state, phase: 'idle' as const }))
      if (ink.paper) $.clock.after(QUIET_MS, () => paperWhenIdle($, ink))
    }
    return next(e)
  })

  on('session.measure', async ($, e, next) => {
    if (e.changed.includes('context')) {
      const contextLeft = e.context.percent === undefined ? null : 100 - e.context.percent
      await update($, activity, state => ({ ...state, contextLeft }))
    }
    return next(e)
  })

  on('tool.call', async ($, e, next) => {
    if (e.agentId !== undefined || next.origin.plugin !== 'engine') return next(e)
    const kind = TOOL_KIND[e.tool]
    if (kind) {
      await update($, activity, state => ({ ...state, counts: { ...state.counts, [kind]: state.counts[kind] + 1 } }))
    }
    const ran = await next(e)
    if (TASK_TOOLS.has(e.tool)) await update($, activity, state => taskChange(state, e, ran))
    return ran
  })

  // The terminal says whether a pane can dock only while drawing, so the page opens from here, once.
  on('ui.render', { component: 'AbovePrompt' }, ($, e, next) => {
    if (e.surface === 'terminal' && e.viewport) {
      // Only the fullscreen layout holds still; on the main screen the lines would scroll away.
      const want = { rows: e.viewport.rows, columns: e.viewport.columns, ruled: e.viewport.isFullscreen === true && !ownPaper }
      const was = ink.paper
      if (!was || was.rows !== want.rows || was.columns !== want.columns || was.ruled !== want.ruled) {
        ink.paper = want
        $.clock.after(QUIET_MS, () => paperWhenIdle($, ink))
      }
    }
    const canDock = e.surface === 'terminal' && e.viewport?.isFullscreen === true && e.viewport.columns >= DOCK_COLUMNS
    if (canDock && !docking && !e.props.view.agentId) {
      docking = true
      $.clock.after(0, () => { void $.ui.open(PANE_OPTIONS) })
    }
    return next(e)
  })

  on('ui.render', { component: 'Backdrop' }, ($, e, next) => {
    if (e.props.scene !== SCENE_ID || (e.surface !== 'desktop' && e.surface !== 'mobile')) return next(e)
    const { Svg } = $.ui.resolve(e)
    return <Svg source={PAPER} alt="Ruled notebook paper with a red margin and punch holes" isInteractive />
  })

  on('ui.render', { component: 'UserMessage' }, async ($, e, next) => {
    // The note writes the words itself, so the app's own bubble does not sit inside it.
    if (!TYPED.has(e.props.origin.kind) || e.props.text.trim() === '') return next(e)

    if (e.surface === 'terminal') {
      // ctrl+o shows the row as stored.
      if (e.props.isExpanded) return next(e)
      const { Box, Text, Image } = $.ui.resolve(e)
      return (
        <Box flexDirection="row" alignItems="flex-start" gap={1} marginY={1}>
          {pictures ? <Image source={png('inky')} columns={4} rows={2} alt={EMOJI.inky} /> : <Text>{EMOJI.inky}</Text>}
          <Box flexDirection="column" alignItems="flex-start" flexShrink={1}>
            <Box paddingLeft={4}><Text color="#9fcfa6">{'▄▄▄▄▄▄▄'}</Text></Box>
            <Box backgroundColor={NOTE} paddingX={2}>
              <Text color={NOTE_INK}>{e.props.text}</Text>
            </Box>
          </Box>
        </Box>
      )
    }

    // The desktop has no ctrl+o view, so it reports every row as expanded.
    if (e.surface !== 'desktop' && e.surface !== 'mobile') return next(e)
    const { Box, Svg, Text } = $.ui.resolve(e)
    return (
      <Box flexDirection="row" alignItems="flex-start" gap="sm" marginY="sm">
        <Svg source={avatar('inky')} alt="inky" width={AVATAR_PX} height={AVATAR_PX} />
        <Box flexDirection="column" alignItems="flex-start" flexShrink={1}>
          <Box paddingLeft={6}><Svg source={TAPE} alt="washi tape" width={64} height={12} /></Box>
          <Box backgroundColor={NOTE} paddingX="md" paddingY="sm">
            <Text color={NOTE_INK} mono>{e.props.text}</Text>
          </Box>
        </Box>
      </Box>
    )
  })

  on('ui.render', { component: 'AssistantMessage' }, async ($, e, next) => {
    if (e.surface === 'terminal') return e.props.isFirstOfReply ? inGutter($, e, 'sunny', await next(e), pictures) : next(e)
    if (e.surface !== 'desktop' && e.surface !== 'mobile') return next(e)
    const { Box, Svg } = $.ui.resolve(e)
    return (
      <Box flexDirection="row" alignItems="flex-start" gap="sm">
        <Svg source={avatar('sunny')} alt="sunny" width={AVATAR_PX} height={AVATAR_PX} />
        <Box flexGrow={1} flexShrink={1}>{await next(e)}</Box>
      </Box>
    )
  })

  on('ui.render', { component: 'ToolGroup' }, async ($, e, next) => {
    if (e.props.isExpanded) return next(e)
    const first = e.props.calls[0]
    const who = first ? critterFor(first.tool) : 'dot'

    if (e.surface === 'terminal') return inGutter($, e, who, await next(e), pictures)
    // The desktop draws its own group line beside a hook's tree, so the hook draws the whole line.
    if (e.surface !== 'desktop' && e.surface !== 'mobile') return next(e)
    const { Box, Svg, Text } = $.ui.resolve(e)
    return (
      <Box flexDirection="row" alignItems="center" gap="sm">
        <Svg source={avatar(who)} alt={who} width={AVATAR_PX} height={AVATAR_PX} />
        <Text color="#69645b">{summarize(e.props.calls.map(call => call.tool))}</Text>
      </Box>
    )
  })

  on('ui.render', { component: 'ToolUse' }, async ($, e, next) => {
    const who = critterFor(e.props.tool)
    if (e.surface === 'terminal') return inGutter($, e, who, await next(e), pictures)
    if (e.surface !== 'desktop' && e.surface !== 'mobile') return next(e)
    const { Box, Svg } = $.ui.resolve(e)
    return (
      <Box flexDirection="row" alignItems="flex-start" gap="sm">
        <Svg source={avatar(who)} alt={who} width={AVATAR_PX} height={AVATAR_PX} />
        <Box flexGrow={1} flexShrink={1}>{await next(e)}</Box>
      </Box>
    )
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const state = await read($, activity)
    const { label, seed } = today()
    const mascot = MASCOTS[seed % MASCOTS.length] ?? MASCOTS[0]!
    const doing = state.phase === 'working' ? 'is thinking it over' : 'is keeping watch'
    const { counts, tasks, contextLeft } = state
    const rows: [string, number][] = [['edits', counts.edit], ['reads', counts.read], ['searches', counts.search], ['runs', counts.run]]
    const shownTasks = tasks.slice(0, 8)

    if (e.surface === 'terminal') {
      const { Box, Text, Image } = $.ui.resolve(e)
      if (e.props.view.agentId) return <Text color="inactive">The page follows the main conversation.</Text>
      const width = e.props.bodyColumns
      if (e.props.placement === 'inline') {
        return <Text color="inactive" wrap="truncate-end">{`${label} · ${mascot.name} ${doing} · ${rows.map(([name, n]) => `${name} ${n}`).join(' · ')}`}</Text>
      }
      const art = Math.min(width - 2, 22)
      const pen = contextLeft === null ? null : pencilText(contextLeft, Math.min(width, 30))
      return (
        <Box flexDirection="column" width={width} gap={1}>
          <Box justifyContent="center"><Text color="inactive">{label}</Text></Box>
          <Box flexDirection="column" alignItems="center">
            <Text color="#d9c88f">{'▄▄▄▄▄▄'}</Text>
            <Box flexDirection="column" alignItems="center" backgroundColor="#fffdf8" paddingX={1}>
              {pictures
                ? <Image source={{ png: MASCOT_PNG[mascot.name] ?? '' }} columns={art} rows={Math.round(art * 0.4)} alt={mascot.name} />
                : <Text>{EMOJI[mascot.name as Critter] ?? ''}</Text>}
              <Text color={PAPER_INK}>{mascot.name}</Text>
            </Box>
            <Text>{doing}</Text>
          </Box>
          <Box flexDirection="column">
            <Text color="inactive">{'this page ~~~~~~'}</Text>
            {rows.map(([name, n]) => (
              <Box flexDirection="row" justifyContent="space-between">
                <Box flexDirection="row">
                  <Box width={10}><Text>{name}</Text></Box>
                  <Text color="#b8382e">{tallyText(n)}</Text>
                </Box>
                <Text>{String(n)}</Text>
              </Box>
            ))}
          </Box>
          <Box flexDirection="column">
            <Box paddingLeft={8}><Text color="#efb3c3">{'▄▄▄▄▄▄'}</Text></Box>
            <Box flexDirection="column" backgroundColor={TODO} paddingX={1}>
              <Text color="#b8382e" bold>to do</Text>
              {shownTasks.length === 0 && <Text color="#6b5a50">nothing yet</Text>}
              {shownTasks.map(task => {
                const { mark, color } = taskMark(task)
                return (
                  <Box flexDirection="row" gap={1}>
                    <Text color={color}>{mark}</Text>
                    <Text color={task.status === 'completed' ? '#6b5a50' : '#3a2f2a'}>{task.text}</Text>
                  </Box>
                )
              })}
              {tasks.length > shownTasks.length && <Text color="#6b5a50">{`+${tasks.length - shownTasks.length} more`}</Text>}
            </Box>
          </Box>
          {pen && (
            <Box flexDirection="column">
              <Box flexDirection="row" justifyContent="space-between">
                <Text>pencil left</Text>
                <Text>{`${contextLeft}%`}</Text>
              </Box>
              <Text>
                <Text color="#e98a8a">{pen.eraser}</Text>
                <Text color="#e0b23c">{pen.body}</Text>
                <Text color="#8a7a66">{pen.tip}</Text>
              </Text>
            </Box>
          )}
        </Box>
      )
    }

    if (e.surface !== 'desktop' && e.surface !== 'mobile') {
      const { Text } = $.ui.resolve(e)
      return <Text color="inactive">{`${label} · ${mascot.name} ${doing}`}</Text>
    }
    const { Box, Text, Svg } = $.ui.resolve(e)
    if (e.props.view.agentId) return <Text color="inactive">The page follows the main conversation.</Text>
    return (
      <Box flexDirection="column" paddingX="md" paddingY="sm" gap="lg">
        <Box flexDirection="row" justifyContent="center"><Text color="#55514a" mono>{label}</Text></Box>

        <Box flexDirection="column" alignItems="center" gap="sm">
          <Box position="relative" paddingTop="sm">
            <Box position="absolute" top={0} left={7} width={7} height={1} backgroundColor="#e6d7a8" />
            <Box flexDirection="column" alignItems="center" backgroundColor="#fffdf8" paddingX="lg" paddingY="md">
              <Svg source={mascot.art} alt={mascot.name} width={MASCOT_PX.width} height={MASCOT_PX.height} />
              <Text color={PAPER_INK} mono>{mascot.name}</Text>
            </Box>
          </Box>
          <Text color={PAPER_INK} mono>{doing}</Text>
        </Box>

        <Box flexDirection="column">
          <Text color="#69645b" mono>{'this page ~~~~~~'}</Text>
          {rows.map(([name, n]) => (
            <Box flexDirection="row" alignItems="center" justifyContent="space-between">
              <Box flexDirection="row" alignItems="center" gap="sm">
                <Box width={10}><Text color={PAPER_INK} mono>{name}</Text></Box>
                {n > 0 && <Svg source={tally(n)} alt={`${n} ${name}`} width={Math.ceil(Math.min(n, 20) / 5) * 26} height={20} />}
              </Box>
              <Text color={PAPER_INK} mono tabular>{String(n)}</Text>
            </Box>
          ))}
        </Box>

        <Box position="relative" paddingTop="sm" width="100%">
          <Box position="absolute" top={0} left={12} width={8} height={1} backgroundColor="#f2b8c8" />
          <Box flexDirection="column" width="100%" backgroundColor={TODO} paddingX="md" paddingY="md" gap="xs">
            <Text color="#b8382e" weight="semibold" mono>to do</Text>
            {shownTasks.length === 0 && <Text color="#6b5a50" mono>nothing yet</Text>}
            {shownTasks.map(task => {
              const { mark, color } = taskMark(task)
              return (
                <Box flexDirection="row" gap="xs" alignItems="flex-start">
                  <Text color={color} mono>{mark}</Text>
                  <Text color={task.status === 'completed' ? '#6b5a50' : '#3a2f2a'} mono>{task.text}</Text>
                </Box>
              )
            })}
            {tasks.length > shownTasks.length && <Text color="#6b5a50" mono>{`+${tasks.length - shownTasks.length} more`}</Text>}
          </Box>
        </Box>

        {contextLeft !== null && (
          <Box flexDirection="column" gap="xs">
            <Box flexDirection="row" justifyContent="space-between">
              <Text color={PAPER_INK} mono>pencil left</Text>
              <Text color={PAPER_INK} mono tabular>{`${contextLeft}%`}</Text>
            </Box>
            <Svg source={pencil(contextLeft)} alt={`${contextLeft}% of context left`} width={200} height={18} />
          </Box>
        )}
      </Box>
    )
  })
}
