export type TaskStatus = 'pending' | 'in_progress' | 'completed'
export type ActivityTask = { id: string; text: string; status: TaskStatus }
export type ToolCounts = { read: number; edit: number; search: number; run: number }
export type ActivityState = {
  counts: ToolCounts
  phase: 'working' | 'idle'
  contextLeft: number | null
  tasks: ActivityTask[]
  taskSource: 'desktop' | 'cli' | 'todo' | null
}

declare module 'claude-code' {
  interface PluginState {
    notebook: { activity: Shaped<ActivityState> }
  }
}
