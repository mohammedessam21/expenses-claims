export type Role = 'employee' | 'approver'

export const CLAIM_STATUSES = ['submitted', 'under_review', 'approved', 'rejected', 'returned', 'withdrawn'] as const

export type ClaimStatus = (typeof CLAIM_STATUSES)[number]

export type ClaimAction = 'start_review' | 'approve' | 'reject' | 'return' | 'resubmit' | 'withdraw'

export type EventAction = ClaimAction | 'submit'

export interface User {
  id: number
  email: string
  name: string
  role: Role
  company: { id: number; name: string }
}

export interface Category {
  id: number
  name_en: string
  name_ar: string
  limit_halalas: number
  active: boolean
}

export interface CategoryName {
  id: number
  name_en: string
  name_ar: string
}

export interface Person {
  id: number
  name: string
}

export interface ClaimEvent {
  id: number
  action: EventAction
  from_status: ClaimStatus | null
  to_status: ClaimStatus
  comment: string | null
  created_at: string
  actor: Person & { role: Role }
}

export interface Claim {
  id: number
  reference_code: string
  status: ClaimStatus
  amount_halalas: number
  limit_halalas_at_submission: number
  description: string
  spent_on: string
  created_at: string
  category: CategoryName
  employee: Person
  reviewer: Person | null
}

export interface ClaimDetail extends Claim {
  available_actions: ClaimAction[]
  events: ClaimEvent[]
}

export interface NewClaim {
  category_id: number
  amount_halalas: number
  description: string
  spent_on: string
}

export interface ClaimEdits {
  amount_halalas: number
  description: string
}

export interface CategoryInput {
  name_en: string
  name_ar: string
  limit_halalas: number
  active: boolean
}
