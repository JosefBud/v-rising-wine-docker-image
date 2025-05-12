/*
  Warnings:

  - You are about to drop the column `sessionId` on the `UserLog` table. All the data in the column will be lost.

*/
-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_UserLog" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "log" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "UserLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_UserLog" ("createdAt", "id", "log", "updatedAt", "userId") SELECT "createdAt", "id", "log", "updatedAt", "userId" FROM "UserLog";
DROP TABLE "UserLog";
ALTER TABLE "new_UserLog" RENAME TO "UserLog";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
