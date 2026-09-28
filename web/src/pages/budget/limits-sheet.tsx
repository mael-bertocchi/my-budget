import { useDocument } from '@application/hooks';
import { useServices } from '@application/services';
import { CategoryIconComponent } from '@components/icon-tile';
import SheetComponent from '@components/sheet';
import { categoriesOf } from '@core/categories';
import { euro } from '@core/formatting';
import { amountInputOf, groupAmountInput, sanitizeAmountInput } from '@core/operations';
import { useState, type JSX } from 'react';

/**
 * @function parseLimit
 * @description Reads a limit field, where an empty one keeps the current value.
 */
function parseLimit(text: string): number | null {
    const cleaned = sanitizeAmountInput(text);

    return cleaned === '' ? null : Number(cleaned);
}

/**
 * @function LimitsForm
 * @description The sheet's content, mounted fresh each time it opens.
 */
function LimitsForm({ onDone }: { onDone: () => void }): JSX.Element {
    const document = useDocument();
    const { store } = useServices();
    const categories = categoriesOf(document.categories);
    const [monthly, setMonthly] = useState(amountInputOf(document.budget.monthlyLimit));
    const [limits, setLimits] = useState<Record<string, string>>(() => Object.fromEntries(categories.map((category) => [category.id, amountInputOf(category.monthlyLimit)])));

    const budget = parseLimit(monthly) ?? 0;
    const remaining = budget - categories.reduce((total, category) => total + (parseLimit(limits[category.id] ?? '') ?? 0), 0);

    let dispatch = { text: 'Fully dispatched', className: 'text-positive-text' };

    if (remaining > 0) {
        dispatch = { text: `${euro(remaining)} to dispatch`, className: 'text-accent' };
    } else if (remaining < 0) {
        dispatch = { text: `${euro(-remaining)} over budget`, className: 'text-negative-text' };
    }

    /**
     * @function save
     * @description Stores the limits, keeping any left empty as they were.
     */
    const save = (): void => {
        const monthlyLimit = parseLimit(monthly);
        const parsed = Object.fromEntries(Object.entries(limits).map(([id, text]) => [id, parseLimit(text)]));

        store.apply((current) => ({
            ...current,
            budget: { monthlyLimit: monthlyLimit ?? current.budget.monthlyLimit },
            categories: categoriesOf(current.categories).map((category) => ({ ...category, monthlyLimit: parsed[category.id] ?? category.monthlyLimit }))
        }));
        onDone();
    };

    return (
        <form
            id="limits-form"
            onSubmit={(event) => {
                event.preventDefault();
                save();
            }}
        >
            <label className="field-label" htmlFor="monthly-limit">Monthly budget</label>
            <div className="relative">
                <span className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-[15px] text-ink-tertiary">€</span>
                <input id="monthly-limit" className="field pl-8 text-[17px] font-semibold tabular-nums" inputMode="decimal" value={monthly} onChange={(event) => setMonthly(groupAmountInput(sanitizeAmountInput(event.target.value)))} placeholder="3000" />
            </div>

            <div className="mb-2 mt-7 flex items-baseline justify-between">
                <h3 className="text-[15px] font-semibold">Category limits</h3>
                <span className={`text-[13px] font-medium ${dispatch.className}`}>{dispatch.text}</span>
            </div>
            <div className="divide-y divide-hairline rounded-2xl bg-fill/60">
                {categories.map((category) => (
                    <label key={category.id} className="flex items-center gap-3 px-3.5 py-2.5">
                        <CategoryIconComponent category={category} size={30} />
                        <span className="flex-1 text-[15px]">{category.name}</span>
                        <span className="text-[15px] text-ink-tertiary">€</span>
                        <input
                            className="h-9 w-24 rounded-lg bg-white px-2.5 text-right text-[15px] font-medium tabular-nums outline-none ring-1 ring-hairline transition focus:ring-2 focus:ring-accent/50"
                            inputMode="decimal"
                            value={limits[category.id] ?? ''}
                            placeholder="0"
                            aria-label={`${category.name} limit`}
                            onChange={(event) => setLimits({ ...limits, [category.id]: groupAmountInput(sanitizeAmountInput(event.target.value)) })}
                        />
                    </label>
                ))}
            </div>
        </form>
    );
}

/**
 * @function LimitsSheet
 * @description The Edit limits sheet: the monthly budget, each category's limit, and what is left to dispatch.
 */
function LimitsSheet({ open, onClose }: { open: boolean; onClose: () => void }): JSX.Element {
    return (
        <SheetComponent open={open} title="Edit limits" onClose={onClose} footer={<button type="submit" form="limits-form" className="button-primary">Save limits</button>}>
            <LimitsForm onDone={onClose} />
        </SheetComponent>
    );
}

export default LimitsSheet;
