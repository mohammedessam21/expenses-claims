import type { Role } from '../api/types'

export function homePathFor(role: Role) {
  return role === 'approver' ? '/review/claims' : '/claims'
}
