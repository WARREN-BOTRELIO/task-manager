import { useDeferredValue, useState } from 'react'
import type { TaskPayload } from '@/types'
import type { Task } from '@/types'
import { TaskCard } from '@/features/tasks/components/TaskCard'
import { TaskFilters } from '@/features/tasks/components/TaskFilters'
import { TaskFormModal } from '@/features/tasks/components/TaskFormModal'
import { DeleteConfirmDialog } from '@/features/tasks/components/DeleteConfirmDialog'
import { useTasks, type StatusFilter, type TaskFilters as TaskFiltersState } from '@/features/tasks/hooks/useTasks'
import { Button } from '@/components/ui/Button'
import { Spinner } from '@/components/ui/Spinner'
import { EmptyState } from '@/components/ui/EmptyState'
import { ErrorState } from '@/components/ui/ErrorState'
import { apiErrorMessage } from '@/services/authStorage'

export function TasksPage() {
  const [status, setStatus] = useState<StatusFilter>('ALL')
  const [searchInput, setSearchInput] = useState('')
  const search = useDeferredValue(searchInput)

  const [formOpen, setFormOpen] = useState(false)
  const [editingTask, setEditingTask] = useState<Task | null>(null)
  const [deletingTask, setDeletingTask] = useState<Task | null>(null)

  const filters: TaskFiltersState = { status, search }
  const { tasks, total, isLoading, isFetching, isError, error, refetch, create, update, remove } =
    useTasks(filters)

  const openCreate = () => {
    setEditingTask(null)
    setFormOpen(true)
  }

  const openEdit = (task: Task) => {
    setEditingTask(task)
    setFormOpen(true)
  }

  const handleSubmit = async (payload: TaskPayload) => {
    if (editingTask) {
      await update.mutateAsync({ id: editingTask.id, payload })
    } else {
      await create.mutateAsync(payload)
    }
  }

  const mutationError =
    create.isError ? apiErrorMessage(create.error, 'Unable to create the task.')
    : update.isError ? apiErrorMessage(update.error, 'Unable to update the task.')
    : null

  const handleDelete = async () => {
    if (!deletingTask) return
    try {
      await remove.mutateAsync(deletingTask.id)
      setDeletingTask(null)
    } catch {
      setDeletingTask(null)
    }
  }

  const hasActiveFilters = status !== 'ALL' || search.trim().length > 0

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-bold text-slate-900 sm:text-2xl">My tasks</h1>
          <p className="mt-0.5 text-sm text-slate-500">
            {total} {total === 1 ? 'task' : 'tasks'}
          </p>
        </div>
        <Button onClick={openCreate} className="shrink-0">
          <svg viewBox="0 0 20 20" fill="currentColor" className="h-4 w-4" aria-hidden="true">
            <path d="M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z" />
          </svg>
          New task
        </Button>
      </div>

      <TaskFilters
        status={status}
        search={searchInput}
        onStatusChange={setStatus}
        onSearchChange={setSearchInput}
      />

      {isFetching ? (
        <div className="flex justify-center py-8" aria-live="polite">
          <Spinner />
        </div>
      ) : null}

      {isLoading ? (
        <div className="flex justify-center py-16">
          <Spinner />
        </div>
      ) : isError ? (
        <ErrorState message={apiErrorMessage(error, 'Failed to load your tasks.')} onRetry={() => refetch()} />
      ) : tasks.length === 0 ? (
        hasActiveFilters ? (
          <EmptyState
            title="No matching tasks"
            description="No tasks match your search or filter. Try clearing them."
            action={<Button variant="secondary" onClick={() => { setStatus('ALL'); setSearchInput('') }}>Clear filters</Button>}
          />
        ) : (
          <EmptyState
            title="No tasks yet"
            description="You're all caught up. Create your first task to get started."
            action={<Button onClick={openCreate}>Create a task</Button>}
          />
        )
      ) : (
        <ul className="space-y-3">
          {tasks.map((task) => (
            <TaskCard key={task.id} task={task} onEdit={openEdit} onDelete={setDeletingTask} />
          ))}
        </ul>
      )}

      <TaskFormModal
        open={formOpen}
        task={editingTask}
        submitting={create.isPending || update.isPending}
        error={mutationError}
        onClose={() => setFormOpen(false)}
        onSubmit={handleSubmit}
      />

      <DeleteConfirmDialog
        task={deletingTask}
        deleting={remove.isPending}
        onClose={() => setDeletingTask(null)}
        onConfirm={handleDelete}
      />
    </div>
  )
}