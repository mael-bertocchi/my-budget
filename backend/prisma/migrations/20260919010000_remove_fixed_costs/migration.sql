-- Fixed costs are gone: the budget counts every euro of the monthly limit again.

-- DropTable
DROP TABLE "fixed_costs";

-- AlterTable
ALTER TABLE "budget_history" DROP COLUMN "fixed_costs_total";
