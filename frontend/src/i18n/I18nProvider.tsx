import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react'
import type { CategoryName } from '../api/types'
import { halalasToSar } from '../lib/money'
import arJson from './ar.json'
import en from './en.json'
import { I18nContext, type I18nValue, type Language, type TranslationKey, type TranslationVars } from './context'

const ar: Record<TranslationKey, string> = arJson

const dictionaries: Record<Language, Record<TranslationKey, string>> = { en, ar }

const LANGUAGE_KEY = 'expense-claims-language'

const DATE_LOCALES: Record<Language, string> = { en: 'en-GB', ar: 'ar-u-ca-gregory-nu-latn' }

function initialLanguage(): Language {
  return localStorage.getItem(LANGUAGE_KEY) === 'ar' ? 'ar' : 'en'
}

function interpolate(template: string, vars: TranslationVars = {}) {
  return template.replace(/\{\{(\w+)\}\}/g, (match, name: string) => (name in vars ? String(vars[name]) : match))
}

export function I18nProvider({ children }: { children: ReactNode }) {
  const [language, setLanguage] = useState<Language>(initialLanguage)

  useEffect(() => {
    document.documentElement.lang = language
    document.documentElement.dir = language === 'ar' ? 'rtl' : 'ltr'
    localStorage.setItem(LANGUAGE_KEY, language)
  }, [language])

  const toggleLanguage = useCallback(() => setLanguage((current) => (current === 'en' ? 'ar' : 'en')), [])

  const t = useCallback(
    (key: TranslationKey, vars?: TranslationVars) => interpolate(dictionaries[language][key], vars),
    [language],
  )

  const value = useMemo<I18nValue>(
    () => ({
      language,
      toggleLanguage,
      t,
      categoryName: (category: CategoryName) => (language === 'ar' ? category.name_ar : category.name_en),
      formatSar: (halalas: number) => t('amount.sar', { amount: halalasToSar(halalas) }),
      formatDateTime: (iso: string) =>
        new Intl.DateTimeFormat(DATE_LOCALES[language], { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(iso)),
    }),
    [language, toggleLanguage, t],
  )

  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>
}
