import { useCallback, useEffect, useState } from 'react'

export function useApiData<T>(load: () => Promise<T>) {
  const [data, setData] = useState<T | null>(null)
  const [error, setError] = useState<unknown>(null)
  const [loading, setLoading] = useState(true)
  const [version, setVersion] = useState(0)

  useEffect(() => {
    let active = true
    setLoading(true)
    load()
      .then((result) => {
        if (active) {
          setData(result)
          setError(null)
        }
      })
      .catch((caught: unknown) => {
        if (active) {
          setError(caught)
        }
      })
      .finally(() => {
        if (active) {
          setLoading(false)
        }
      })
    return () => {
      active = false
    }
  }, [load, version])

  const reload = useCallback(() => setVersion((current) => current + 1), [])

  return { data, setData, error, loading, reload }
}
