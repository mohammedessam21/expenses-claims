export function ErrorAlert({ message }: { message: string | null }) {
  if (!message) {
    return null
  }
  return (
    <p role="alert" className="alert">
      {message}
    </p>
  )
}
