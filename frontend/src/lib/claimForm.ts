import type { TranslationKey } from '../i18n/context'
import { sarToHalalas } from './money'

export type AmountCheck = { ok: true; halalas: number } | { ok: false; error: TranslationKey }

export function checkAmount(input: string, limitHalalas: number | null): AmountCheck {
  const halalas = sarToHalalas(input)
  if (halalas === null) {
    return { ok: false, error: 'validation.amountInvalid' }
  }
  if (halalas <= 0) {
    return { ok: false, error: 'validation.amountPositive' }
  }
  if (limitHalalas !== null && halalas > limitHalalas) {
    return { ok: false, error: 'validation.amountOverLimit' }
  }
  return { ok: true, halalas }
}
