import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react'
import { setUnauthorizedHandler, tokenStorage } from '../api/client'
import { fetchMe, login } from '../api/requests'
import type { User } from '../api/types'
import { AuthContext, type AuthValue } from './context'

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [restoring, setRestoring] = useState(() => tokenStorage.get() !== null)

  useEffect(() => {
    setUnauthorizedHandler(() => setUser(null))
  }, [])

  useEffect(() => {
    if (!tokenStorage.get()) {
      return
    }
    fetchMe()
      .then(setUser)
      .catch(() => {
        tokenStorage.clear()
        setUser(null)
      })
      .finally(() => setRestoring(false))
  }, [])

  const signIn = useCallback(async (email: string, password: string) => {
    const { token, user: signedInUser } = await login(email, password)
    tokenStorage.set(token)
    setUser(signedInUser)
    return signedInUser
  }, [])

  const signOut = useCallback(() => {
    tokenStorage.clear()
    setUser(null)
  }, [])

  const value = useMemo<AuthValue>(() => ({ user, restoring, signIn, signOut }), [user, restoring, signIn, signOut])

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
