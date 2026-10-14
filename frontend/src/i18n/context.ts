import { createContext } from 'react'
import type { CategoryName } from '../api/types'
import en from './en.json'

export type Language = 'en' | 'ar'

export type TranslationKey = keyof typeof en

export type TranslationVars = Record<string, string | number>

export interface I18nValue {
  language: Language
  toggleLanguage: () => void
  t: (key: TranslationKey, vars?: TranslationVars) => string
  categoryName: (category: CategoryName) => string
  formatSar: (halalas: number) => string
  formatDateTime: (iso: string) => string
}

export const I18nContext = createContext<I18nValue | null>(null)
