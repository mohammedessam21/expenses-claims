import { api } from './client'
import type {
  Category,
  CategoryInput,
  Claim,
  ClaimDetail,
  ClaimEdits,
  ClaimStatus,
  NewClaim,
  User,
} from './types'

export async function login(email: string, password: string) {
  const { data } = await api.post<{ token: string; user: User }>('/auth/login', { email, password })
  return data
}

export async function fetchMe() {
  const { data } = await api.get<{ user: User }>('/me')
  return data.user
}

export async function fetchActiveCategories() {
  const { data } = await api.get<{ categories: Category[] }>('/categories')
  return data.categories
}

export async function fetchMyClaims() {
  const { data } = await api.get<{ claims: Claim[] }>('/claims')
  return data.claims
}

export async function fetchMyClaim(id: string) {
  const { data } = await api.get<{ claim: ClaimDetail }>(`/claims/${id}`)
  return data.claim
}

export async function createClaim(claim: NewClaim) {
  const { data } = await api.post<{ claim: ClaimDetail }>('/claims', { claim })
  return data.claim
}

export async function resubmitClaim(id: number, claim: ClaimEdits) {
  const { data } = await api.post<{ claim: ClaimDetail }>(`/claims/${id}/resubmit`, { claim })
  return data.claim
}

export async function withdrawClaim(id: number) {
  const { data } = await api.post<{ claim: ClaimDetail }>(`/claims/${id}/withdraw`)
  return data.claim
}

export async function fetchReviewClaims(status: ClaimStatus | '') {
  const { data } = await api.get<{ claims: Claim[] }>('/review/claims', { params: status ? { status } : {} })
  return data.claims
}

export async function fetchReviewClaim(id: string) {
  const { data } = await api.get<{ claim: ClaimDetail }>(`/review/claims/${id}`)
  return data.claim
}

export async function startReview(id: number) {
  const { data } = await api.post<{ claim: ClaimDetail }>(`/review/claims/${id}/start_review`)
  return data.claim
}

export async function approveClaim(id: number) {
  const { data } = await api.post<{ claim: ClaimDetail }>(`/review/claims/${id}/approve`)
  return data.claim
}

export async function rejectClaim(id: number, reason: string) {
  const { data } = await api.post<{ claim: ClaimDetail }>(`/review/claims/${id}/reject`, { reason })
  return data.claim
}

export async function returnClaim(id: number, comment: string) {
  const { data } = await api.post<{ claim: ClaimDetail }>(`/review/claims/${id}/return`, { comment })
  return data.claim
}

export async function fetchReviewCategories() {
  const { data } = await api.get<{ categories: Category[] }>('/review/categories')
  return data.categories
}

export async function createCategory(category: CategoryInput) {
  const { data } = await api.post<{ category: Category }>('/review/categories', { category })
  return data.category
}

export async function updateCategory(id: number, category: CategoryInput) {
  const { data } = await api.patch<{ category: Category }>(`/review/categories/${id}`, { category })
  return data.category
}
