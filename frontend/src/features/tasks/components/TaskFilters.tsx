import type { TaskStatus } from '@/types'
import { TASK_STATUSES } from '@/types'
import { cn } from '@/utils/cn'
import type { StatusFilter } from '@/features/tasks/hooks/useTasks'

interface TaskFiltersProps {
  status: StatusFilter
  search: string
  onStatusChange: (status: StatusFilter) => void
  onSearchChange: (search: string) => void
}

const tabs: Array<{ value: StatusFilter; label: string }> = [
  { value: 'ALL', label: 'All' },
  ...TASK_STATUSES.map((status: TaskStatus) => ({
    value: status as StatusFilter,
    label: status === 'IN_PROGRESS' ? 'In progress' : status.charAt(0) + status.slice(1).toLowerCase(),
  })),
]

export function TaskFilters({ status, search, onStatusChange, onSearchChange }: TaskFiltersProps) {
  return (
    <div className="space-y-3">
      <div className="relative">
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400"
          aria-hidden="true"
        >
          <circle cx="11" cy="11" r="7" stroke="currentColor" />
          <path strokeLinecap="round" d="M21 21l-4.3-4.3" />
        </svg>
        <input
          type="search"
          value={search}
          onChange={(event) => onSearchChange(event.target.value)}
          placeholder="Search tasks…"
          aria-label="Search tasks"
          className="w-full rounded-lg border border-slate-300 bg-white py-2.5 pl-9 pr-3 text-sm placeholder:text-slate-400 focus:outline-2 focus:outline-offset-1 focus:outline-slate-500"
        />
      </div>

      <div
        className="flex gap-1 overflow-x-auto rounded-lg border border-slate-300 bg-white p-1"
        role="tablist"
        aria-label="Filter by status"
      >
        {tabs.map((tab) => (
          <button
            key={tab.value}
            type="button"
            role="tab"
            aria-selected={status === tab.value}
            onClick={() => onStatusChange(tab.value)}
            className={cn(
              'shrink-0 rounded-md px-3 py-1.5 text-sm font-medium transition-colors',
              status === tab.value
                ? 'bg-slate-900 text-white'
                : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900',
            )}
          >
            {tab.label}
          </button>
        ))}
      </div>
    </div>
  )
}