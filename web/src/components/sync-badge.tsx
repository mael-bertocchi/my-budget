import type { SyncStatus } from '@core/budget-store';
import type { MessageKey } from '@core/i18n';
import { t } from '@core/i18n';
import type { JSX } from 'react';

/**
 * @constant LABELS
 * @description Each status, as the app's Settings badge words it.
 */
const LABELS: Record<SyncStatus, { label: MessageKey; color: string }> = {
    syncing: { label: 'sync.syncing', color: 'bg-ink-quaternary' },
    synced: { label: 'sync.synced', color: 'bg-positive' },
    offline: { label: 'sync.offline', color: 'bg-warning' },
    error: { label: 'sync.error', color: 'bg-negative' }
};

/**
 * @function SyncBadgeComponent
 * @description Where the page stands with the server.
 */
function SyncBadgeComponent({ status }: { status: SyncStatus }): JSX.Element {
    const { label, color } = LABELS[status];

    return (
        <span className="inline-flex items-center gap-1.5 text-[13px] text-ink-secondary">
            <span className={`h-2 w-2 rounded-full ${color} ${status === 'syncing' ? 'animate-pulse' : ''}`} />
            {t(label)}
        </span>
    );
}

export default SyncBadgeComponent;
