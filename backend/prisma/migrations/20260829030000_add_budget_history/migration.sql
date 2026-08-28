-- CreateTable
CREATE TABLE "budget_history" (
    "month" TEXT NOT NULL,
    "monthly_limit" DOUBLE PRECISION NOT NULL,
    "category_limits" JSONB NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "budget_history_pkey" PRIMARY KEY ("month")
);
