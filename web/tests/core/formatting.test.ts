import { currencyNamed } from '@core/currencies';
import { amountInput, dayShort, euro, euroPrecise, fieldDate, money, monthWithYear, percent, rate, relativeDay, truncate } from '@core/formatting';
import { describe, expect, it } from 'vitest';

import { NOW } from '../support/fixtures';

describe('amounts', () => {
    it('rounds euros half away from zero with thousands separators', () => {
        expect(euro(1234.5)).toBe('€1,235');
        expect(euro(-2.5)).toBe('€-3');
        expect(euro(0)).toBe('€0');
    });

    it('keeps cents when asked to', () => {
        expect(euroPrecise(1234.5)).toBe('€1,234.50');
    });

    it('prints an amount in its own currency without a sign', () => {
        expect(money(48.9, currencyNamed('USD'))).toBe('$48.90');
        expect(money(-12, currencyNamed('CHF'))).toBe('CHF12.00');
        expect(money(5000, currencyNamed('KRW'))).toBe('₩5,000.00');
    });

    it('prints rates to five significant digits', () => {
        expect(rate(0.869032)).toBe('0.86903');
        expect(rate(0.000644721)).toBe('0.00064472');
        expect(rate(1)).toBe('1.0000');
    });

    it('prefills whole amounts without decimals', () => {
        expect(amountInput(400)).toBe('400');
        expect(amountInput(12.5)).toBe('12.50');
    });

    it('prints a percentage', () => {
        expect(percent(0.584)).toBe('58%');
    });
});

describe('dates', () => {
    it('names days relative to today', () => {
        expect(relativeDay(new Date(2026, 8, 27, 9), NOW)).toBe('Today');
        expect(relativeDay(new Date(2026, 8, 26, 9), NOW)).toBe('Yesterday');
        expect(relativeDay(new Date(2026, 8, 25, 9), NOW)).toBe('Fri 25 Sep');
    });

    it('prints the operation date field like the app', () => {
        expect(fieldDate(new Date(2026, 8, 27), NOW)).toBe('Today, 27 Sep');
        expect(fieldDate(new Date(2026, 8, 3), NOW)).toBe('Thu 3 Sep');
    });

    it('prints months and short days', () => {
        expect(monthWithYear(NOW)).toBe('September 2026');
        expect(dayShort(NOW)).toBe('27 Sep');
    });
});

describe('truncate', () => {
    it('cuts long text with an ellipsis and leaves short text alone', () => {
        expect(truncate('Whole Foods', 20)).toBe('Whole Foods');
        expect(truncate('Whole Foods Market', 10)).toBe('Whole Foo…');
    });
});
