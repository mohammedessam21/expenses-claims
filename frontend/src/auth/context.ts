import { createContext } from 'react'
import type { User } from '../api/types'

export interface AuthValue {
  user: User | null
  restoring: boolean
  signIn: (email: string, password: string) => Promise<User>
  signOut: () => void
}

export const AuthContext = createContext<AuthValue | null>(null)
