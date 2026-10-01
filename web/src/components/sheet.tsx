import { t } from '@core/i18n';
import { X } from 'lucide-react';
import { useEffect, useRef, type JSX, type ReactNode } from 'react';

/**
 * @interface SheetProps
 * @description A modal sheet.
 */
interface SheetProps {
    open: boolean; /*!< Whether it is shown */
    title: string; /*!< Its title */
    onClose: () => void; /*!< Called when it is dismissed */
    children: ReactNode; /*!< Its content, only mounted while open so it starts fresh each time */
    footer?: ReactNode; /*!< What stays pinned under the scrolling content */
}

/**
 * @function SheetComponent
 * @description A sheet on the native dialog element: centred on a wide screen, rising from the bottom on a phone.
 * Escape, the close button and a click beside it dismiss it.
 */
function SheetComponent({ open, title, onClose, children, footer }: SheetProps): JSX.Element {
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
            className="sheet"
            aria-label={title}
            onCancel={(event) => {
                event.preventDefault();
                onClose();
            }}
            onClick={(event) => {
                if (event.target === dialog.current) {
                    onClose();
                }
            }}
        >
            {open && (
                <>
                    <header className="flex items-center justify-between px-6 pb-2 pt-5">
                        <h2 className="text-[20px] font-semibold tracking-tight">{title}</h2>
                        <button type="button" onClick={onClose} aria-label={t('common.close')} className="flex h-8 w-8 items-center justify-center rounded-full bg-fill text-ink-secondary transition hover:bg-fill-strong">
                            <X size={17} strokeWidth={2.4} />
                        </button>
                    </header>
                    <div className="flex-1 overflow-y-auto px-6 pb-6 pt-2">{children}</div>
                    {footer !== undefined && <footer className="border-t border-hairline px-6 pb-[max(1.25rem,env(safe-area-inset-bottom))] pt-4">{footer}</footer>}
                </>
            )}
        </dialog>
    );
}

export default SheetComponent;
