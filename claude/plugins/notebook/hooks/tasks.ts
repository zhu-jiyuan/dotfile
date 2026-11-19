import type { ToolCallInput, ToolCallResult } from 'claude-code'
import type { ActivityState, ActivityTask, TaskStatus, ToolCounts } from '../types'

export const TOOL_KIND: Record<string, keyof ToolCounts> = {
  Read: 'read',
  WebFetch: 'read',
  Edit: 'edit',
  Write: 'edit',
  NotebookEdit: 'edit',
  Grep: 'search',
  Glob: 'search',
  WebSearch: 'search',
  ToolSearch: 'search',
  Bash: 'run',
  Agent: 'run',
}

type DesktopPlan = {
  items?: unknown
  advance?: unknown
  done?: unknown
  start?: unknown
}

function isStatus(value: unknown): value is TaskStatus {
  return value === 'pending' || value === 'in_progress' || value === 'completed'
}

function desktopTasks(state: ActivityState, input: DesktopPlan): ActivityTask[] {
  if (Array.isArray(input.items)) {
    return input.items.flatMap((item, index) =>
      item && typeof item.content === 'string' && isStatus(item.status)
        ? [{ id: String(index + 1), text: item.content, status: item.status }]
        : [],
    )
  }
  if (state.taskSource !== 'desktop') return state.tasks
  let tasks = state.tasks.map(task => ({ ...task }))
  if (input.advance === true) {
    const active = tasks.find(task => task.status === 'in_progress')
    if (active) active.status = 'completed'
    const pending = tasks.find(task => task.status === 'pending')
    if (pending) pending.status = 'in_progress'
  }
  if (Array.isArray(input.done)) {
    const done = input.done
    tasks = tasks.map((task, index) =>
      done.includes(index + 1) ? { ...task, status: 'completed' } : task,
    )
  }
  const started = typeof input.start === 'number' ? tasks[input.start - 1] : undefined
  if (started) started.status = 'in_progress'
  return tasks
}

export function taskChange(state: ActivityState, e: ToolCallInput, ran: ToolCallResult): ActivityState {
  if (ran.deny !== undefined || ran.isError) return state
  switch (e.tool) {
    case 'mcp__ccd_turn__update_plan': {
      const input = e as DesktopPlan
      if (!Array.isArray(input.items) && state.taskSource !== 'desktop') return state
      return { ...state, taskSource: 'desktop', tasks: desktopTasks(state, input) }
    }
    case 'mcp__ccd_turn__wrap_up':
      return state.taskSource === 'desktop'
        ? { ...state, tasks: state.tasks.map(task => ({ ...task, status: 'completed' })) }
        : state
    case 'TodoWrite': {
      const result = ran.result as { newTodos: { content: string; status: TaskStatus }[] }
      return {
        ...state,
        taskSource: 'todo',
        tasks: result.newTodos.map((task, index) => ({ id: String(index + 1), text: task.content, status: task.status })),
      }
    }
    case 'TaskList': {
      const result = ran.result as { tasks: { id: string; subject: string; status: TaskStatus }[] }
      return {
        ...state,
        taskSource: 'cli',
        tasks: result.tasks.map(task => ({ id: task.id, text: task.subject, status: task.status })),
      }
    }
    case 'TaskCreate': {
      const { task } = ran.result as { task: { id: string; subject: string } }
      const tasks = state.taskSource === 'cli' ? state.tasks.filter(one => one.id !== task.id) : []
      return { ...state, taskSource: 'cli', tasks: [...tasks, { id: task.id, text: task.subject, status: 'pending' }] }
    }
    case 'TaskUpdate': {
      const result = ran.result as { success: boolean; taskId: string; statusChange?: { to: string } }
      if (!result.success || state.taskSource !== 'cli') return state
      const status = result.statusChange?.to ?? e.status
      return {
        ...state,
        tasks: state.tasks.flatMap(task => {
          if (task.id !== result.taskId) return [task]
          if (status === 'deleted') return []
          return [{ ...task, text: e.subject ?? task.text, status: isStatus(status) ? status : task.status }]
        }),
      }
    }
    default:
      return state
  }
}

export const TASK_TOOLS = new Set([
  'mcp__ccd_turn__update_plan', 'mcp__ccd_turn__wrap_up',
  'TodoWrite', 'TaskList', 'TaskCreate', 'TaskUpdate',
])
