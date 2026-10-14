const SAR_AMOUNT_PATTERN = /^\d+(\.\d{1,2})?$/
const ARABIC_INDIC_ZERO = 0x0660
const EXTENDED_ARABIC_INDIC_ZERO = 0x06f0

export function normalizeDigits(input: string): string {
  return input
    .replace(/[٠-٩]/g, (digit) => String(digit.charCodeAt(0) - ARABIC_INDIC_ZERO))
    .replace(/[۰-۹]/g, (digit) => String(digit.charCodeAt(0) - EXTENDED_ARABIC_INDIC_ZERO))
    .replace(/٫/g, '.')
}

export function halalasToSar(halalas: number): string {
  const fraction = halalas % 100
  const whole = (halalas - fraction) / 100
  return `${whole}.${String(fraction).padStart(2, '0')}`
}

export function sarToHalalas(input: string): number | null {
  const trimmed = normalizeDigits(input).trim()
  if (!SAR_AMOUNT_PATTERN.test(trimmed)) {
    return null
  }

  const [whole, fraction = ''] = trimmed.split('.')
  const halalas = Number(whole) * 100 + Number(fraction.padEnd(2, '0'))
  return Number.isSafeInteger(halalas) ? halalas : null
}
