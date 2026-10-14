const SAR_AMOUNT_PATTERN = /^\d+(\.\d{1,2})?$/

export function halalasToSar(halalas: number): string {
  const fraction = halalas % 100
  const whole = (halalas - fraction) / 100
  return `${whole}.${String(fraction).padStart(2, '0')}`
}

export function sarToHalalas(input: string): number | null {
  const trimmed = input.trim()
  if (!SAR_AMOUNT_PATTERN.test(trimmed)) {
    return null
  }

  const [whole, fraction = ''] = trimmed.split('.')
  const halalas = Number(whole) * 100 + Number(fraction.padEnd(2, '0'))
  return Number.isSafeInteger(halalas) ? halalas : null
}
