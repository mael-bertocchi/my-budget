-- Every write to the budget document bumps its revision, so a client pushing an edit made
-- against an older copy is turned away instead of silently erasing what it never saw.

-- AlterTable
ALTER TABLE "budget_state" ADD COLUMN "revision" INTEGER NOT NULL DEFAULT 0;
