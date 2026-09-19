-- CreateTable
CREATE TABLE "fixed_costs" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "position" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "fixed_costs_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "budget_history" ADD COLUMN "fixed_costs_total" DOUBLE PRECISION NOT NULL DEFAULT 0;
