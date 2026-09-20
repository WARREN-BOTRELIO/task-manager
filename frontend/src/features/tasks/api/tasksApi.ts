import { http } from '@/services/http'
import type { PageResponse, Task, TaskPayload } from '@/types'

export interface TaskListParams {
  status?: Task['status']
  search?: string
  page?: number
  size?: number
}

export function listTasks(params: TaskListParams = {}): Promise<PageResponse<Task>> {
  return http
    .get<PageResponse<Task>>('/tasks', { params: { status: undefined, search: undefined, page: 0, size: 100, ...params } })
    .then((r) => r.data)
}

export function createTask(payload: TaskPayload): Promise<Task> {
  return http.post<Task>('/tasks', payload).then((r) => r.data)
}

export function updateTask(id: number, payload: TaskPayload): Promise<Task> {
  return http.put<Task>(`/tasks/${id}`, payload).then((r) => r.data)
}

export function deleteTask(id: number): Promise<void> {
  return http.delete(`/tasks/${id}`).then(() => undefined)
}