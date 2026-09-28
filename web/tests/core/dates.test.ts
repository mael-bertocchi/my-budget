import { dayKey, isFutureDay, monthKey, parseDay, parseMonthKey, shiftMonth } from '@core/dates';
import { describe, expect, it } from 'vitest';

import { NOW } from '../support/fixtures';

describe('parseDay', () => {
    it('reads today and yesterday', () => {
        expect(dayKey(parseDay('Today', NOW) ?? new Date(0))).toBe('2026-09-27');
        expect(dayKey(parseDay('yesterday', NOW) ?? new Date(0))).toBe('2026-09-26');
    });

    it('reads ISO and written days', () => {
        expect(dayKey(parseDay('2026-09-25', NOW) ?? new Date(0))).toBe('2026-09-25');
        expect(dayKey(parseDay('25/09/2026', NOW) ?? new Date(0))).toBe('2026-09-25');
        expect(dayKey(parseDay('25.09.26', NOW) ?? new Date(0))).toBe('2026-09-25');
    });

    it('puts a day without a year in the most recent past occurrence', () => {
        expect(dayKey(parseDay('25/09', NOW) ?? new Date(0))).toBe('2026-09-25');
        expect(dayKey(parseDay('28/12', NOW) ?? new Date(0))).toBe('2025-12-28');
    });

    it('refuses what names no real day', () => {
        expect(parseDay('31/06/2026', NOW)).toBeNull();
        expect(parseDay('next tuesday', NOW)).toBeNull();
    });
});

describe('months', () => {
    it('keys and parses months', () => {
        expect(monthKey(NOW)).toBe('2026-09');
        expect(parseMonthKey('2026-09')?.getMonth()).toBe(8);
        expect(parseMonthKey('2026-13')).toBeNull();
    });

    it('steps across years', () => {
        expect(monthKey(shiftMonth(new Date(2026, 0, 15), -1))).toBe('2025-12');
    });

    it('spots a future day', () => {
        expect(isFutureDay(new Date(2026, 8, 28), NOW)).toBe(true);
        expect(isFutureDay(new Date(2026, 8, 27, 23, 59), NOW)).toBe(false);
    });
});
