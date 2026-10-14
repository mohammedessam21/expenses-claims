import axios from 'axios'

const TOKEN_KEY = 'expense-claims-token'

export const tokenStorage = {
  get: () => localStorage.getItem(TOKEN_KEY),
  set: (token: string) => localStorage.setItem(TOKEN_KEY, token),
  clear: () => localStorage.removeItem(TOKEN_KEY),
}

export const api = axios.create({ baseURL: '/api/v1' })

let handleUnauthorized = () => {}

export function setUnauthorizedHandler(handler: () => void) {
  handleUnauthorized = handler
}

api.interceptors.request.use((config) => {
  const token = tokenStorage.get()
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

api.interceptors.response.use(
  (response) => response,
  (error) => {
    const isLoginRequest = error.config?.url === '/auth/login'
    if (axios.isAxiosError(error) && error.response?.status === 401 && !isLoginRequest) {
      tokenStorage.clear()
      handleUnauthorized()
    }
    return Promise.reject(error)
  },
)

export function serverErrorMessage(error: unknown): string | null {
  if (axios.isAxiosError(error)) {
    const data = error.response?.data as { error?: unknown } | undefined
    if (typeof data?.error === 'string') {
      return data.error
    }
  }
  return null
}
