import { useEffect, useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import type { Task, TaskStatus } from '@/types'
import { TASK_STATUSES } from '@/types'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Textarea } from '@/components/ui/Textarea'
import { Select } from '@/components/ui/Select'
import { Alert } from '@/components/ui/Alert'
import { Modal } from '@/components/ui/Modal'
import { Spinner } from '@/components/ui/Spinner'
import { apiErrorMessage } from '@/services/authStorage'
import { STATUS_LABELS } from '@/components/ui/StatusBadge'

const schema = z.object({
  title: z
    .string()
    .min(1, 'Task title is required')
    .max(120, 'Task title must not exceed 120 characters'),
  description: z
    .string()
    .max(1000, 'Task description must not exceed 1000 characters')
    .optional()
    .or(z.literal('')),
  status: z.enum(TASK_STATUSES),
})

type TaskFormValues = z.infer<typeof schema>

interface TaskFormModalProps {
  open: boolean
  task: Task | null
  submitting: boolean
  error: string | null
  onClose: () => void
  onSubmit: (payload: { title: string; description: string | null; status: TaskStatus }) => Promise<void>
}

const statusOptions = TASK_STATUSES.map((status) => ({ value: status, label: STATUS_LABELS[status] }))

export function TaskFormModal({ open, task, submitting, error, onClose, onSubmit }: TaskFormModalProps) {
  const [serverError, setServerError] = useState<string | null>(null)

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<TaskFormValues>({
    resolver: zodResolver(schema),
    defaultValues: { title: '', description: '', status: 'TODO' },
  })

  useEffect(() => {
    setServerError(null)
    if (open) {
      reset({
        title: task?.title ?? '',
        description: task?.description ?? '',
        status: task?.status ?? 'TODO',
      })
    }
  }, [open, task, reset])

  const onLocalSubmit = handleSubmit(async (values) => {
    setServerError(null)
    try {
      await onSubmit({
        title: values.title.trim(),
        description: values.description?.trim() ? values.description.trim() : null,
        status: values.status,
      })
      onClose()
    } catch (submitError) {
      setServerError(apiErrorMessage(submitError, error ?? 'Unable to save the task.'))
    }
  })

  return (
    <Modal open={open} title={task ? 'Edit task' : 'New task'} onClose={onClose}>
      {error && !serverError ? <div className="mb-4"><Alert tone="error">{error}</Alert></div> : null}
      {serverError ? (
        <div className="mb-4">
          <Alert tone="error">{serverError}</Alert>
        </div>
      ) : null}

      <form onSubmit={onLocalSubmit} className="space-y-4" noValidate>
        <Input
          label="Title"
          placeholder="What needs to be done?"
          error={errors.title?.message}
          {...register('title')}
        />
        <Textarea
          label="Description"
          placeholder="Optional details…"
          error={errors.description?.message}
          {...register('description')}
        />
        <Select
          label="Status"
          options={statusOptions}
          error={errors.status?.message}
          {...register('status')}
        />

        <div className="flex justify-end gap-3 pt-2">
          <Button type="button" variant="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" disabled={submitting}>
            {submitting ? <Spinner size="sm" light /> : task ? 'Save changes' : 'Create task'}
          </Button>
        </div>
      </form>
    </Modal>
  )
}