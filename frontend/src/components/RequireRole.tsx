import type { ReactNode } from 'react'
import { Navigate } from 'react-router-dom'
import type { Role } from '../api/types'
import { homePathFor } from '../auth/homePath'
import { useAuth } from '../auth/useAuth'

export function RequireRole({ role, children }: { role: Role; children: ReactNode }) {
  const { user } = useAuth()

  if (!user) {
    return <Navigate to="/login" replace />
  }
  if (user.role !== role) {
    return <Navigate to={homePathFor(user.role)} replace />
  }
  return children
}
