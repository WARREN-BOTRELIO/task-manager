import axios from 'axios'
import { env } from '@/app/config/env'
import { tokenStore } from '@/services/authStorage'

/**
 * On a 401 from a protected endpoint the token is expired/invalid:
 * clear the session and bounce to the login page.
 */
function handleUnauthorized(): void {
  tokenStore.clear()
  const current = window.location.pathname
  if (current !== '/login' && current !== '/register') {
    window.location.assign('/login')
  }
}

export const http = axios.create({
  baseURL: env.apiUrl,
  headers: { 'Content-Type': 'application/json' },
})

http.interceptors.request.use((config) => {
  const token = tokenStore.getToken()
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

http.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error?.response?.status === 401) {
      handleUnauthorized()
    }
    return Promise.reject(error)
  },
)