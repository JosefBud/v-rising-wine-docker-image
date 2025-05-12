/*
  Warnings:

  - A unique constraint covering the columns `[lastSessionId]` on the table `User` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "User_lastSessionId_key" ON "User"("lastSessionId");
