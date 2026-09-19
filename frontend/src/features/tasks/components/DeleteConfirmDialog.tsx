import type { Task } from '@/types'
import { Modal } from '@/components/ui/Modal'
import { Button } from '@/components/ui/Button'
import { Spinner } from '@/components/ui/Spinner'

interface DeleteConfirmDialogProps {
  task: Task | null
  deleting: boolean
  onClose: () => void
  onConfirm: () => void
}

export function DeleteConfirmDialog({ task, deleting, onClose, onConfirm }: DeleteConfirmDialogProps) {
  return (
    <Modal open={Boolean(task)} title="Delete task" onClose={onClose}>
      <p className="text-sm text-slate-600">
        Are you sure you want to delete{' '}
        <span className="font-semibold text-slate-900">“{task?.title}”</span>? This action cannot
        be undone.
      </p>
      <div className="mt-6 flex justify-end gap-3">
        <Button type="button" variant="secondary" onClick={onClose}>
          Cancel
        </Button>
        <Button type="button" variant="danger" onClick={onConfirm} disabled={deleting}>
          {deleting ? <Spinner size="sm" light /> : 'Delete'}
        </Button>
      </div>
    </Modal>
  )
}