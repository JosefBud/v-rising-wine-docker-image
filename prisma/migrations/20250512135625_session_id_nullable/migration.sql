-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "characterName" TEXT,
    "lastSessionId" TEXT,
    "lastConnectedAt" DATETIME NOT NULL,
    "lastDisconnectedAt" DATETIME,
    "numOfSpawns" INTEGER NOT NULL DEFAULT 0,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);
INSERT INTO "new_User" ("characterName", "createdAt", "id", "lastConnectedAt", "lastDisconnectedAt", "lastSessionId", "numOfSpawns", "updatedAt") SELECT "characterName", "createdAt", "id", "lastConnectedAt", "lastDisconnectedAt", "lastSessionId", "numOfSpawns", "updatedAt" FROM "User";
DROP TABLE "User";
ALTER TABLE "new_User" RENAME TO "User";
CREATE UNIQUE INDEX "User_lastSessionId_key" ON "User"("lastSessionId");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
