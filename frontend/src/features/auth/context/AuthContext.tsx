import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import { loginApi, registerApi, type Credentials } from '@/features/auth/api/authApi'
import { tokenStore } from '@/services/authStorage'

interface AuthContextValue {
  token: string | null
  email: string | null
  isAuthenticated: boolean
  login: (credentials: Credentials) => Promise<void>
  register: (credentials: Credentials) => Promise<void>
  logout: () => void
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(() => tokenStore.getToken())
  const [email, setEmail] = useState<string | null>(() => tokenStore.getEmail())

  useEffect(() => {
    if (!tokenStore.getToken()) {
      tokenStore.clear()
    }
  }, [])

  const applySession = useCallback((auth: { token: string; email: string }) => {
    setToken(auth.token)
    setEmail(auth.email)
    tokenStore.set(auth.token, auth.email)
  }, [])

  const login = useCallback(
    async (credentials: Credentials) => {
      const auth = await loginApi(credentials)
      applySession(auth)
    },
    [applySession],
  )

  const register = useCallback(
    async (credentials: Credentials) => {
      const auth = await registerApi(credentials)
      applySession(auth)
    },
    [applySession],
  )

  const logout = useCallback(() => {
    setToken(null)
    setEmail(null)
    tokenStore.clear()
  }, [])

  const value = useMemo(
    () => ({
      token,
      email,
      isAuthenticated: Boolean(token),
      login,
      register,
      logout,
    }),
    [token, email, login, register, logout],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}