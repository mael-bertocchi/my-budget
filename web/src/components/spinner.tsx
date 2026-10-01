import { t } from '@core/i18n';
import type { JSX } from 'react';

/**
 * @function SpinnerComponent
 * @description A small activity indicator.
 */
function SpinnerComponent({ size = 22 }: { size?: number }): JSX.Element {
    return (
        <span
            role="status"
            aria-label={t('common.loading')}
            className="inline-block animate-spin rounded-full border-[2.5px] border-fill-strong border-t-ink-tertiary"
            style={{ width: size, height: size }}
        />
    );
}

export default SpinnerComponent;
