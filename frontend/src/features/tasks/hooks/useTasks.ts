import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import {
  createTask,
  deleteTask,
  listTasks,
  updateTask,
  type TaskListParams,
} from '@/features/tasks/api/tasksApi'
import type { TaskPayload, TaskStatus } from '@/types'

export type StatusFilter = TaskStatus | 'ALL'

export interface TaskFilters {
  status: StatusFilter
  search: string
}

function toParams(filters: TaskFilters): TaskListParams {
  const params: TaskListParams = { page: 0, size: 100 }
  if (filters.status !== 'ALL') params.status = filters.status
  const search = filters.search.trim()
  if (search) params.search = search
  return params
}

export function useTasks(filters: TaskFilters) {
  const queryClient = useQueryClient()

  const { data, isLoading, isError, error, refetch, isFetching } = useQuery({
    queryKey: ['tasks', filters],
    queryFn: () => listTasks(toParams(filters)),
  })

  const invalidate = () => queryClient.invalidateQueries({ queryKey: ['tasks'] })

  const create = useMutation({
    mutationFn: (payload: TaskPayload) => createTask(payload),
    onSuccess: invalidate,
  })

  const update = useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: TaskPayload }) =>
      updateTask(id, payload),
    onSuccess: invalidate,
  })

  const remove = useMutation({
    mutationFn: (id: number) => deleteTask(id),
    onSuccess: invalidate,
  })

  return {
    tasks: data?.content ?? [],
    total: data?.totalElements ?? 0,
    isLoading,
    isFetching,
    isError,
    error,
    refetch,
    create,
    update,
    remove,
  }
}