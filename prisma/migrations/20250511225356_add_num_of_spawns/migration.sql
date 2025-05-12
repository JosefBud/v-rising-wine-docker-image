-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "characterName" TEXT NOT NULL,
    "lastSessionId" TEXT NOT NULL,
    "lastConnectedAt" DATETIME NOT NULL,
    "lastDisconnectedAt" DATETIME,
    "numOfSpawns" INTEGER NOT NULL DEFAULT 0,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);
INSERT INTO "new_User" ("characterName", "createdAt", "id", "lastConnectedAt", "lastDisconnectedAt", "lastSessionId", "updatedAt") SELECT "characterName", "createdAt", "id", "lastConnectedAt", "lastDisconnectedAt", "lastSessionId", "updatedAt" FROM "User";
DROP TABLE "User";
ALTER TABLE "new_User" RENAME TO "User";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
