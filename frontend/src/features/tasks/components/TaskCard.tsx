import type { Task } from '@/types'
import { StatusBadge } from '@/components/ui/StatusBadge'

function formatDate(iso: string): string {
  const date = new Date(iso)
  return date.toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' })
}

interface TaskCardProps {
  task: Task
  onEdit: (task: Task) => void
  onDelete: (task: Task) => void
}

function CheckIcon({ done }: { done: boolean }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      className={done ? 'h-5 w-5 text-green-600' : 'h-5 w-5 text-slate-300'}
      aria-hidden="true"
    >
      <circle cx="12" cy="12" r="9" stroke="currentColor" />
      <path strokeLinecap="round" strokeLinejoin="round" d="M8.5 12.5l2.5 2.5 4.5-5" />
    </svg>
  )
}

export function TaskCard({ task, onEdit, onDelete }: TaskCardProps) {
  const done = task.status === 'DONE'

  return (
    <li className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex items-start gap-3">
        <div className={`mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full border ${done ? 'border-green-500 bg-green-50' : 'border-slate-300'}`}>
          <CheckIcon done={done} />
        </div>

        <div className="min-w-0 flex-1">
          <p className={`text-sm font-semibold ${done ? 'text-slate-400 line-through' : 'text-slate-900'}`}>
            {task.title}
          </p>
          {task.description ? (
            <p className="mt-0.5 line-clamp-2 text-sm text-slate-500">{task.description}</p>
          ) : null}
          <div className="mt-2 flex flex-wrap items-center gap-2">
            <StatusBadge status={task.status} />
            <span className="text-xs text-slate-400">Created {formatDate(task.createdAt)}</span>
          </div>
        </div>

        <div className="flex shrink-0 items-center gap-1">
          <button
            type="button"
            onClick={() => onEdit(task)}
            aria-label={`Edit ${task.title}`}
            className="rounded-lg p-2 text-slate-400 transition-colors hover:bg-slate-100 hover:text-slate-700"
          >
            <svg viewBox="0 0 20 20" fill="currentColor" className="h-4 w-4" aria-hidden="true">
              <path d="M5.433 13.917l1.262-3.155a4 4 0 01.914-1.343l4.1-4.1a2.4 2.4 0 013.394 3.394l-4.1 4.1a4 4 0 01-1.343.914l-3.155 1.262a.5.5 0 01-.662-.662zM13.673 4.53l1.797 1.797-.53.53-1.797-1.797.53-.53z" />
            </svg>
          </button>
          <button
            type="button"
            onClick={() => onDelete(task)}
            aria-label={`Delete ${task.title}`}
            className="rounded-lg p-2 text-slate-400 transition-colors hover:bg-red-50 hover:text-red-600"
          >
            <svg viewBox="0 0 20 20" fill="currentColor" className="h-4 w-4" aria-hidden="true">
              <path
                fillRule="evenodd"
                d="M8.75 1A2.75 2.75 0 006 3.75v.443c-.795.077-1.584.176-2.365.298a.75.75 0 10.23 1.482l.149-.022.841 10.518A2.75 2.75 0 007.596 19h4.807a2.75 2.75 0 002.742-2.53l.841-10.52.149.023a.75.75 0 00.23-1.482A41.03 41.03 0 0014 4.193V3.75A2.75 2.75 0 0011.25 1h-2.5zM10 4c.84 0 1.673.025 2.5.075V3.75c0-.69-.56-1.25-1.25-1.25h-2.5c-.69 0-1.25.56-1.25 1.25v.325C8.327 4.025 9.16 4 10 4zM8.58 7.72a.75.75 0 00-1.5.06l.3 7.5a.75.75 0 101.5-.06l-.3-7.5zm4.34.06a.75.75 0 10-1.5-.06l-.3 7.5a.75.75 0 101.5.06l.3-7.5z"
                clipRule="evenodd"
              />
            </svg>
          </button>
        </div>
      </div>
    </li>
  )
}