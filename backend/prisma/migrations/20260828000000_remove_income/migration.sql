-- The app tracks spending only, so the income rows and their discriminator go away.
DELETE FROM "operations" WHERE "type" = 'INCOME';
DELETE FROM "categories" WHERE "type" = 'INCOME';

-- AlterTable
ALTER TABLE "categories" DROP COLUMN "type";

-- AlterTable
ALTER TABLE "operations" DROP COLUMN "type";

-- DropEnum
DROP TYPE "OperationType";
