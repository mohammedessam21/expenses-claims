import type { ClaimEvent } from '../api/types'
import { useI18n } from '../i18n/useI18n'

export function Timeline({ events }: { events: ClaimEvent[] }) {
  const { t, formatDateTime } = useI18n()

  return (
    <section className="card">
      <h2>{t('claim.timeline')}</h2>
      <ol className="timeline">
        {events.map((event) => (
          <li key={event.id}>
            <div>
              <strong>{event.actor.name}</strong> {t(`event.${event.action}`)}
            </div>
            <div className="muted">
              <time dateTime={event.created_at}>{formatDateTime(event.created_at)}</time>
              {event.from_status && (
                <>
                  {' · '}
                  {t('timeline.statusChange', {
                    from: t(`status.${event.from_status}`),
                    to: t(`status.${event.to_status}`),
                  })}
                </>
              )}
            </div>
            {event.comment && <blockquote className="comment">{event.comment}</blockquote>}
          </li>
        ))}
      </ol>
    </section>
  )
}
