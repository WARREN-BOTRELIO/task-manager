import type { ApiError } from '@/types'

/**
 * JWT storage strategy (technical assessment):
 *
 * The access token is kept in localStorage so that the SPA survives full
 * page reloads without an auth exchange. This is a known trade-off:
 * localStorage is accessible to any script running on the same origin,
 * making it vulnerable to XSS. A production deployment should prefer
 * short-lived access tokens + HttpOnly Secure cookies. See README.
 */
const TOKEN_KEY = 'tm_token'
const EMAIL_KEY = 'tm_email'

export const tokenStore = {
  getToken(): string | null {
    return localStorage.getItem(TOKEN_KEY)
  },
  getEmail(): string | null {
    return localStorage.getItem(EMAIL_KEY)
  },
  set(token: string, email: string): void {
    localStorage.setItem(TOKEN_KEY, token)
    localStorage.setItem(EMAIL_KEY, email)
  },
  clear(): void {
    localStorage.removeItem(TOKEN_KEY)
    localStorage.removeItem(EMAIL_KEY)
  },
}

export function apiErrorMessage(error: unknown, fallback = 'Something went wrong'): string {
  if (typeof error === 'object' && error !== null) {
    const maybe = error as { response?: { data?: Partial<ApiError> } }
    if (maybe.response?.data?.message) {
      return maybe.response.data.message
    }
  }
  return fallback
}