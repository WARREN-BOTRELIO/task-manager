import { describe, expect, it, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { QueryClientProvider } from '@tanstack/react-query'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { TasksPage } from '@/features/tasks/pages/TasksPage'
import { ProtectedRoute } from '@/features/auth/components/ProtectedRoute'
import { AuthProvider } from '@/features/auth/context/AuthContext'
import { createTestQueryClient } from '@/test/testUtils'
import type { Task } from '@/types'

const mockListTasks = vi.fn()
const mockCreateTask = vi.fn()

vi.mock('@/features/tasks/api/tasksApi', () => ({
  listTasks: (...args: unknown[]) => mockListTasks(...args),
  createTask: (...args: unknown[]) => mockCreateTask(...args),
  updateTask: vi.fn(),
  deleteTask: vi.fn(),
}))

const sampleTask: Task = {
  id: 1,
  title: 'Write report',
  description: 'Quarterly summary',
  status: 'TODO',
  createdAt: '2026-09-19T10:00:00',
  updatedAt: '2026-09-19T10:00:00',
}

function renderTasksPage() {
  const queryClient = createTestQueryClient()
  render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>
        <AuthProvider>
          <TasksPage />
        </AuthProvider>
      </MemoryRouter>
    </QueryClientProvider>,
  )
  return queryClient
}

function renderProtected(initialEntries: string[] = ['/tasks']) {
  const queryClient = createTestQueryClient()
  render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={initialEntries}>
        <AuthProvider>
          <Routes>
            <Route
              path="/tasks"
              element={
                <ProtectedRoute>
                  <div>Tasks dashboard</div>
                </ProtectedRoute>
              }
            />
            <Route path="/login" element={<div>Login page</div>} />
          </Routes>
        </AuthProvider>
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('TasksPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
  })

  it('renders the empty state when there are no tasks', async () => {
    mockListTasks.mockResolvedValue({ content: [], totalElements: 0, page: 0, size: 100, totalPages: 0 })

    renderTasksPage()

    expect(await screen.findByText('No tasks yet')).toBeInTheDocument()
  })

  it('lists tasks returned by the API', async () => {
    mockListTasks.mockResolvedValue({
      content: [sampleTask],
      totalElements: 1,
      page: 0,
      size: 100,
      totalPages: 0,
    })

    renderTasksPage()

    expect(await screen.findByText('Write report')).toBeInTheDocument()
    expect(screen.getByText(/1 task/)).toBeInTheDocument()
  })

  it('creates a task through the modal', async () => {
    const user = (await import('@testing-library/user-event')).default.setup()
    mockListTasks.mockResolvedValue({ content: [], totalElements: 0, page: 0, size: 100, totalPages: 0 })
    mockCreateTask.mockResolvedValue({ ...sampleTask, title: 'Standup' })

    renderTasksPage()

    await user.click(await screen.findByRole('button', { name: /new task/i }))
    await user.type(screen.getByLabelText(/title/i), 'Standup')
    await user.click(screen.getByRole('button', { name: /create task/i }))

    expect(mockCreateTask).toHaveBeenCalledWith(
      expect.objectContaining({ title: 'Standup', status: 'TODO' }),
    )
  })
})

describe('ProtectedRoute', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('redirects to /login when unauthenticated', () => {
    renderProtected()

    expect(screen.getByText('Login page')).toBeInTheDocument()
    expect(screen.queryByText('Tasks dashboard')).not.toBeInTheDocument()
  })

  it('renders its children when a token exists', () => {
    localStorage.setItem('tm_token', 'jwt-token')
    localStorage.setItem('tm_email', 'user@example.com')
    renderProtected()

    expect(screen.getByText('Tasks dashboard')).toBeInTheDocument()
  })
})