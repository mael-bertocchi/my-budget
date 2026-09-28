import type { SyncStatus } from '@core/budget-store';
import type { JSX } from 'react';

/**
 * @constant LABELS
 * @description Each status, as the app's Settings badge words it.
 */
const LABELS: Record<SyncStatus, { label: string; color: string }> = {
    syncing: { label: 'Syncing', color: 'bg-ink-quaternary' },
    synced: { label: 'Synced', color: 'bg-positive' },
    offline: { label: 'Offline', color: 'bg-warning' },
    error: { label: 'Error', color: 'bg-negative' }
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
            {label}
        </span>
    );
}

export default SyncBadgeComponent;
