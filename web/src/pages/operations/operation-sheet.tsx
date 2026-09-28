import type { EditorRoute } from '@application/editor-context';
import { useDocument, useRates } from '@application/hooks';
import { useServices } from '@application/services';
import AlertComponent from '@components/alert';
import { CategoryIconComponent } from '@components/icon-tile';
import SheetComponent from '@components/sheet';
import SwitchComponent from '@components/switch';
import { latestLocation } from '@core/budget-math';
import { categoriesOf } from '@core/categories';
import { CURRENCIES, EURO } from '@core/currencies';
import { dayKey, isFutureDay, isSameDay, parseDay, withTimeOf } from '@core/dates';
import { euroPrecise, fieldDate, rate } from '@core/formatting';
import type { Operation } from '@core/models';
import { amountInputOf, deleteOperation, groupAmountInput, Limits, parseAmountInput, sanitizeAmountInput, toOperation, upsertOperation } from '@core/operations';
import { defaultCurrency, rememberCurrency } from '@core/preferences';
import { Globe, MapPin, Repeat, type LucideIcon } from 'lucide-react';
import { useEffect, useState, type JSX, type ReactNode } from 'react';

/**
 * @constant FORM_ID
 * @description Ties the sheet's pinned Save button to its form.
 */
const FORM_ID = 'operation-form';

/**
 * @function ToggleRow
 * @description A setting with an icon, a title, a hint and a switch.
 */
function ToggleRow({ icon: Icon, title, hint, checked, onChange }: { icon: LucideIcon; title: string; hint: string; checked: boolean; onChange: (checked: boolean) => void }): JSX.Element {
    return (
        <div className="flex items-center gap-3 rounded-2xl bg-fill px-4 py-3">
            <Icon size={19} className="shrink-0 text-accent" />
            <span className="flex-1">
                <span className="block text-[15px]">{title}</span>
                <span className="block text-[12px] text-ink-secondary">{hint}</span>
            </span>
            <SwitchComponent checked={checked} onChange={onChange} label={title} />
        </div>
    );
}

/**
 * @function Field
 * @description A labelled field.
 */
function Field({ label, htmlFor, aside, children }: { label: string; htmlFor: string; aside?: string; children: ReactNode }): JSX.Element {
    return (
        <div>
            <div className="flex items-baseline justify-between">
                <label className="field-label" htmlFor={htmlFor}>{label}</label>
                {aside !== undefined && <span className="text-[13px] text-ink-tertiary">{aside}</span>}
            </div>
            {children}
        </div>
    );
}

/**
 * @function OperationForm
 * @description The editor, mounted fresh each time the sheet opens. A foreign amount is priced at the rate of its own
 * day, markup included, and can't be saved until that rate is known — a guessed rate never passes for a published one.
 */
function OperationForm({ existing, onDone, onDelete, onValidityChange }: { existing: Operation | null; onDone: () => void; onDelete: () => void; onValidityChange: (isValid: boolean) => void }): JSX.Element {
    const document = useDocument();
    const rates = useRates();
    const { store } = useServices();
    const categories = categoriesOf(document.categories);
    const now = new Date();

    const [amountText, setAmountText] = useState(existing === null ? '' : amountInputOf(existing.amount));
    const [currencyCode, setCurrencyCode] = useState(existing?.currencyCode ?? defaultCurrency());
    const [categoryId, setCategoryId] = useState(existing?.categoryId ?? categories[0]?.id ?? '');
    const [name, setName] = useState(existing?.name ?? '');
    const [description, setDescription] = useState(existing?.description ?? '');
    const [location, setLocation] = useState(existing === null ? latestLocation(document.operations) ?? '' : existing.location ?? '');
    const [date, setDate] = useState(existing?.date ?? now);
    const [isOnline, setIsOnline] = useState(existing?.isOnline ?? false);
    const [isRecurring, setIsRecurring] = useState(existing?.isRecurring ?? false);

    const day = dayKey(date);
    const isForeign = currencyCode !== EURO.code;
    const amount = parseAmountInput(amountText);
    const storedRate = existing !== null && existing.currencyCode === currencyCode && dayKey(existing.date) === day ? existing.rateToEuro : null;
    const appliedRate = rates.rate(currencyCode, day) ?? storedRate;
    const isValid = amount !== null && name.trim() !== '' && categoryId !== '' && appliedRate !== null;

    useEffect(() => {
        if (isForeign) {
            void rates.load(day);
        }
    }, [rates, day, isForeign]);

    useEffect(() => {
        onValidityChange(isValid);
    }, [isValid, onValidityChange]);

    /**
     * @function pickDay
     * @description Moves the operation to another day. Its own day keeps its time; another day takes the current time
     * of day, as the app's date picker does. The future is out of reach.
     */
    const pickDay = (value: string): void => {
        const picked = parseDay(value, now);

        if (picked === null || isFutureDay(picked, now)) {
            return;
        }

        if (existing !== null && isSameDay(picked, existing.date)) {
            setDate(existing.date);
        } else {
            setDate(isSameDay(picked, now) ? now : withTimeOf(picked, now));
        }
    };

    /**
     * @function save
     * @description Stores the operation. An edit to one deleted on the phone in the meantime is dropped, with a notice.
     */
    const save = (): void => {
        if (!isValid || amount === null || appliedRate === null) {
            return;
        }

        const operation = toOperation({ name, description, amount, currencyCode, categoryId, date, location, isOnline, isRecurring }, appliedRate, existing?.id);

        store.apply((current) => {
            if (existing !== null && !current.operations.some((candidate) => candidate.id === existing.id)) {
                throw new Error('This operation was deleted on another device.');
            }

            return upsertOperation(current, operation);
        });
        rememberCurrency(currencyCode);
        onDone();
    };

    let rateLine = rates.failure(day) ?? 'Loading…';

    if (appliedRate !== null) {
        rateLine = `Rate ${rate(appliedRate)}`;
    }

    return (
        <form
            id={FORM_ID}
            onSubmit={(event) => {
                event.preventDefault();
                save();
            }}
            className="space-y-5"
        >
            <div className="flex flex-col items-center pb-2 pt-1">
                <label htmlFor="amount" className="eyebrow">Amount</label>
                <div className="mt-2 flex items-center gap-2">
                    <input
                        id="amount"
                        inputMode="decimal"
                        autoComplete="off"
                        placeholder="0.00"
                        value={amountText}
                        onChange={(event) => setAmountText(groupAmountInput(sanitizeAmountInput(event.target.value)))}
                        style={{ width: `${Math.max(4, amountText.length) * 0.6 + 0.3}em` }}
                        className="bg-transparent text-right text-[46px] font-semibold tracking-tight tabular-nums outline-none placeholder:text-ink-quaternary"
                    />
                    <select
                        aria-label="Currency"
                        value={currencyCode}
                        onChange={(event) => setCurrencyCode(event.target.value)}
                        className="h-9 cursor-pointer rounded-xl bg-fill px-2.5 text-[15px] font-semibold outline-none transition hover:bg-fill-strong focus:ring-2 focus:ring-accent/40"
                    >
                        {CURRENCIES.map((currency) => (
                            <option key={currency.code} value={currency.code}>{currency.code}</option>
                        ))}
                    </select>
                </div>
                {isForeign && (
                    <div className="mt-1 text-center">
                        {appliedRate !== null && amount !== null && <p className="text-[15px] font-medium text-accent tabular-nums">{euroPrecise(amount * appliedRate)}</p>}
                        <p className={`text-[12px] ${appliedRate === null ? 'text-warning-text' : 'text-ink-tertiary'}`}>{rateLine}</p>
                    </div>
                )}
            </div>

            <div className="border-t border-hairline pt-5">
                <p className="field-label">Category</p>
                <div className="grid grid-cols-4 gap-2 sm:grid-cols-5">
                    {categories.map((category) => {
                        const isSelected = category.id === categoryId;

                        return (
                            <button
                                key={category.id}
                                type="button"
                                aria-pressed={isSelected}
                                onClick={() => setCategoryId(category.id)}
                                className={`flex flex-col items-center gap-1.5 rounded-2xl px-1 pb-2 pt-2.5 transition ${isSelected ? 'bg-accent-soft ring-2 ring-accent' : 'bg-fill hover:bg-fill-strong'}`}
                            >
                                <CategoryIconComponent category={category} size={30} />
                                <span className="w-full truncate text-center text-[12px] font-medium">{category.name}</span>
                            </button>
                        );
                    })}
                </div>
            </div>

            <Field label="Name" htmlFor="name">
                <input id="name" className="field" value={name} maxLength={Limits.name} onChange={(event) => setName(event.target.value)} placeholder="Whole Foods" autoComplete="off" />
            </Field>

            <Field label="Description" htmlFor="description">
                <textarea id="description" className="field min-h-[76px] resize-none py-2.5 leading-snug" value={description} maxLength={Limits.description} onChange={(event) => setDescription(event.target.value)} placeholder="Weekly groceries with Anna" rows={2} />
            </Field>

            <Field label="Date" htmlFor="date" aside={fieldDate(date, now)}>
                <input id="date" type="date" className="field" value={day} max={dayKey(now)} onChange={(event) => pickDay(event.target.value)} />
            </Field>

            <ToggleRow icon={Globe} title="Online" hint="No physical location" checked={isOnline} onChange={setIsOnline} />

            {!isOnline && (
                <Field label="Location" htmlFor="location">
                    <div className="relative">
                        <MapPin size={16} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-accent" />
                        <input id="location" className="field pl-9" value={location} maxLength={Limits.location} onChange={(event) => setLocation(event.target.value)} placeholder="Berlin Mitte" />
                    </div>
                </Field>
            )}

            <ToggleRow icon={Repeat} title="Recurring" hint="Repeats monthly" checked={isRecurring} onChange={setIsRecurring} />

            {existing !== null && (
                <button type="button" onClick={onDelete} className="w-full py-2 text-[15px] font-medium text-negative-text transition hover:opacity-70">Delete operation</button>
            )}
        </form>
    );
}

/**
 * @function OperationSheet
 * @description The New operation and Edit operation sheet, with its delete confirmation.
 */
function OperationSheet({ route, onClose }: { route: EditorRoute | null; onClose: () => void }): JSX.Element {
    const document = useDocument();
    const { store } = useServices();
    const [isConfirmingDelete, setIsConfirmingDelete] = useState(false);
    const [canSave, setCanSave] = useState(false);
    const existing = route?.kind === 'edit' ? document.operations.find((operation) => operation.id === route.id) ?? null : null;
    const isMissing = route?.kind === 'edit' && existing === null;

    /**
     * @function confirmDelete
     * @description Deletes the operation once confirmed.
     */
    const confirmDelete = (): void => {
        if (existing !== null) {
            store.apply((current) => deleteOperation(current, existing.id));
        }

        setIsConfirmingDelete(false);
        onClose();
    };

    return (
        <>
            <SheetComponent
                open={route !== null}
                title={route?.kind === 'edit' ? 'Edit operation' : 'New operation'}
                onClose={onClose}
                footer={isMissing ? undefined : <button type="submit" form={FORM_ID} disabled={!canSave} className="button-primary">{route?.kind === 'edit' ? 'Save changes' : 'Save operation'}</button>}
            >
                {isMissing
                    ? <p className="py-10 text-center text-[15px] text-ink-secondary">This operation no longer exists.</p>
                    : <OperationForm key={route?.kind === 'edit' ? route.id : 'new'} existing={existing} onDone={onClose} onDelete={() => setIsConfirmingDelete(true)} onValidityChange={setCanSave} />}
            </SheetComponent>
            <AlertComponent
                open={isConfirmingDelete}
                title="Delete this operation?"
                message="This can't be undone."
                action="Delete"
                onConfirm={confirmDelete}
                onCancel={() => setIsConfirmingDelete(false)}
            />
        </>
    );
}

export default OperationSheet;
