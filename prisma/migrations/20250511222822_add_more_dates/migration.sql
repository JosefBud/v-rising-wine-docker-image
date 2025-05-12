/*
  Warnings:

  - Added the required column `lastConnectedAt` to the `User` table without a default value. This is not possible if the table is not empty.
  - Added the required column `lastDisconnectedAt` to the `User` table without a default value. This is not possible if the table is not empty.

*/
-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "characterName" TEXT NOT NULL,
    "lastSessionId" TEXT NOT NULL,
    "lastConnectedAt" DATETIME NOT NULL,
    "lastDisconnectedAt" DATETIME NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);
INSERT INTO "new_User" ("characterName", "createdAt", "id", "lastSessionId", "updatedAt") SELECT "characterName", "createdAt", "id", "lastSessionId", "updatedAt" FROM "User";
DROP TABLE "User";
ALTER TABLE "new_User" RENAME TO "User";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
