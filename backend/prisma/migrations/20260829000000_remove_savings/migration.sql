-- The app tracks spending only, so the savings goals, their movements and the balance go away.

-- DropTable
DROP TABLE "savings_movements";

-- DropTable
DROP TABLE "savings_goals";

-- AlterTable
ALTER TABLE "budget_state" DROP COLUMN "savings_balance";

-- DropEnum
DROP TYPE "MovementKind";
