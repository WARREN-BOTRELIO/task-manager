import { http } from '@/services/http'
import type { AuthResponse } from '@/types'

export interface Credentials {
  email: string
  password: string
}

export function loginApi(payload: Credentials): Promise<AuthResponse> {
  return http.post<AuthResponse>('/api/auth/login', payload).then((r) => r.data)
}

export function registerApi(payload: Credentials): Promise<AuthResponse> {
  return http.post<AuthResponse>('/api/auth/register', payload).then((r) => r.data)
}