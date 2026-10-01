import { t } from '@core/i18n';
import { useEffect, useRef, type JSX } from 'react';

/**
 * @interface AlertProps
 * @description A confirmation.
 */
interface AlertProps {
    open: boolean; /*!< Whether it is shown */
    title: string; /*!< The question */
    message?: string; /*!< More about it */
    action: string; /*!< The destructive button's label */
    onConfirm: () => void; /*!< Called when confirmed */
    onCancel: () => void; /*!< Called when cancelled */
}

/**
 * @function AlertComponent
 * @description An iOS-style alert asking before something that can't be undone.
 */
function AlertComponent({ open, title, message, action, onConfirm, onCancel }: AlertProps): JSX.Element {
    const dialog = useRef<HTMLDialogElement>(null);

    useEffect(() => {
        const element = dialog.current;

        if (element === null) {
            return;
        }

        if (open && !element.open) {
            element.showModal();
        } else if (!open && element.open) {
            element.close();
        }
    }, [open]);

    return (
        <dialog
            ref={dialog}
            className="alert"
            onCancel={(event) => {
                event.preventDefault();
                onCancel();
            }}
        >
            <div className="px-5 pb-4 pt-5 text-center">
                <h3 className="text-[17px] font-semibold">{title}</h3>
                {message !== undefined && <p className="mt-1 text-[13px] text-ink-secondary">{message}</p>}
            </div>
            <div className="grid grid-cols-2 border-t border-hairline">
                <button type="button" onClick={onCancel} className="h-11 text-[17px] text-accent transition hover:bg-fill">{t('common.cancel')}</button>
                <button type="button" onClick={onConfirm} className="h-11 border-l border-hairline text-[17px] font-semibold text-negative-text transition hover:bg-fill">{action}</button>
            </div>
        </dialog>
    );
}

export default AlertComponent;
