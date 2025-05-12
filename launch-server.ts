import fsP from 'node:fs/promises';
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { isTypedArray } from 'node:util/types';
import { PrismaClient } from '@prisma/client';

/**
 * Captures: [session ID, platform ID, character name]
 * @example
 * User '{Steam 1211981043}' '76561198087774767', approvedUserIndex: 0, Character: 'Xallie' connected as ID '0,1', Entity '327688,1'.
 */
const CHARACTER_JOINED_REGEX =
  /User '{.* (\d*)}' '(\d*)', .* Character: '(.*)' connected as ID/;
/**
 * Captures: [platform ID]
 * @example
 * PlatformSystemBase - EndAuthSession platformId: 76561198087774767
 */
const CHARACTER_DISCONNECTED_REGEX = /PlatformSystemBase - EndAuthSession platformId: (\d*)/;
/**
 * Captures: [platform ID, character name]
 * @example
 * Spawned character at chunk '11,11' for user 76561198087774767 (Character: Xallie) entity '327688,1' hasCastleSpawn: True netherSpawnPositionEntity: 323292 spawnLocation: -1408:5:-1285.5 firstTimeSpawn: False
 */
const CHARACTER_SPAWNING_REGEX =
  /Spawned character at chunk '.*' for user (\d*) \(Character: (.*)\) entity/;
/**
 * Captures: none
 * @example
 * [Server] Startup Completed - Disabling Scene Loading Systems
 */
const SERVER_STARTED_REGEX = /\[Server\] Startup Completed/;

const COMMAND = '/launch_server.sh';

const prisma = new PrismaClient();
const playerIds = new Set<string>();
const sessionIds = new Set<string>();
let playerIdsRegex = new RegExp([...playerIds].join('|'));
let sessionIdsRegex = new RegExp([...sessionIds].join('|'));
const generateIdRegex = (ids: Set<string>) => new RegExp([...ids].join('|'), 'g');

const addPlayerId = (id: string) => {
  playerIds.add(id);
  playerIdsRegex = generateIdRegex(playerIds);
};
const deletePlayerId = (id: string) => {
  playerIds.delete(id);
  playerIdsRegex = generateIdRegex(playerIds);
};
const addSessionId = (id: string) => {
  sessionIds.add(id);
  sessionIdsRegex = generateIdRegex(sessionIds);
};
const deleteSessionId = (id: string) => {
  sessionIds.delete(id);
  sessionIdsRegex = generateIdRegex(sessionIds);
};

const handleCharacterJoined = async (message: string) => {
  try {
    const _matches = message.matchAll(new RegExp(CHARACTER_JOINED_REGEX, 'g'));
    const [matches] = _matches;
    if (!matches || !matches.length) return;

    const [, sessionId, id, characterName] = matches;
    if (!sessionId || !id || characterName === undefined) return;

    addPlayerId(id);
    addSessionId(sessionId);
    await prisma.user.upsert({
      where: { id },
      update: { lastSessionId: sessionId, characterName, lastConnectedAt: new Date() },
      create: { id, lastSessionId: sessionId, characterName, lastConnectedAt: new Date() },
    });
  } catch (error) {
    console.error('Error handling character joined:', error);
  }
};

const handleCharacterDisconnected = async (message: string) => {
  try {
    const [matches] = message.matchAll(new RegExp(CHARACTER_DISCONNECTED_REGEX, 'g'));
    if (!matches || !matches.length) return;

    const [, id] = matches;
    if (!id) return;

    const { lastSessionId = null } =
      (await prisma.user.findUnique({ where: { id }, select: { lastSessionId: true } })) ?? {};
    if (lastSessionId) {
      deleteSessionId(lastSessionId);
    }
    deletePlayerId(id);
    await prisma.user.upsert({
      where: { id },
      update: { lastSessionId, lastDisconnectedAt: new Date()},
      create: { id, lastSessionId, lastConnectedAt: new Date(), lastDisconnectedAt: new Date() },
    });
  } catch (error) {
    console.error('Error handling character disconnected:', error);
  }
};

const handleCharacterSpawning = async (message: string) => {
  try {
    const [matches] = message.matchAll(new RegExp(CHARACTER_SPAWNING_REGEX, 'g'));
    if (!matches || !matches.length) return;
    const [, id, characterName] = matches;
    if (!id || characterName === undefined) return;

    await prisma.user.upsert({
      where: { id },
      update: { characterName, numOfSpawns: { increment: 1 } },
      create: { id, characterName, lastConnectedAt: new Date(), numOfSpawns: 1 },
    });
  } catch (error) {
    console.error('Error handling character spawning:', error);
  }
};

const handleServerStarted = async (message: string) => {
  try {
    console.log('Server started');
  } catch (error) {
    console.error('Error handling server started:', error);
  }
};

const handleStdout = async (data: Buffer) => {
  const message = data.toString('ascii');
  console.log(message);

  if (CHARACTER_JOINED_REGEX.test(message)) {
    await handleCharacterJoined(message);
  } else if (CHARACTER_DISCONNECTED_REGEX.test(message)) {
    await handleCharacterDisconnected(message);
  } else if (CHARACTER_SPAWNING_REGEX.test(message)) {
    await handleCharacterSpawning(message);
  } else if (SERVER_STARTED_REGEX.test(message)) {
    await handleServerStarted(message);
  }
  try {
    if (playerIds.size < 1 && sessionIds.size < 1) return;

    if (playerIdsRegex.test(message)) {
      const [matches] = message.matchAll(new RegExp(playerIdsRegex, 'g'));
      if (!matches || !matches.length) return;
      const [userId] = matches;
      await prisma.userLog.create({ data: { userId, log: message } });
    } else if (sessionIdsRegex.test(message)) {
      const [matches] = message.matchAll(new RegExp(sessionIdsRegex, 'g'));
      if (!matches || !matches.length) return;
      const [sessionId] = matches;
      const { id: userId = null } =
        (await prisma.user.findUnique({
          where: { lastSessionId: sessionId },
          select: { id: true },
        })) ?? {};
      if (!userId) return;
      await prisma.userLog.create({ data: { userId, log: message } });
    }
  } catch (error) {
    console.error('Error adding user log:', error);
  }
};

async function main() {
  try {
    await prisma.$connect();
    console.log('Connected to SQLite database');

    const users = await prisma.user.findMany();
    users.forEach((user) => {
      addPlayerId(user.id);
    });
  } catch (error) {
    console.error('Error connecting to SQLite database and getting users:', error);
  }

  const serverProcess = spawn(COMMAND);

  serverProcess.stdout.on('data', (data: Buffer) => {
    if (!(data instanceof Buffer)) {
      console.error('Not a buffer:', data);
      return;
    }
    handleStdout(data);
  });
  serverProcess.stderr.on('data', (data) => {
    console.error(`stderr: ${typeof data} ${data}`);
  });
  serverProcess.on('close', async (code, signal) => {
    await prisma.$disconnect();
    console.log('Disconnected from SQLite database');
    console.log(`child process closed with code ${code} and signal ${signal}`);
  });
  serverProcess.on('exit', async (code, signal) => {
    await prisma.$disconnect();
    console.log('Disconnected from SQLite database');
    console.log(`child process exited with code ${code} and signal ${signal}`);
  });

  console.log('Script started');
}
main().catch(console.error);


    /**
     *
     * character joined:
     * 2025-05-11T21:22:08.601421793Z stdout: object User '{Steam 1211981043}'
     * '76561198087774767', approvedUserIndex: 0, Character: 'Xallie' connected
     * as ID '0,1', Entity '327688,1'.
     *
     * {Steam 1211981043} is generated every login, it's effectively a session ID
     * 76561198087774767 is the steam ID
     *
     *
     * server is up:
     * object EOS.Session - Entering ModifySessionAsync!
     *
     * respawning after a death:
     * 2025-05-11T21:26:25.413757953Z stdout: object Spawned character at chunk '11,11' for user 76561198087774767 (Character: Xallie) entity '327688,1' hasCastleSpawn: True netherSpawnPositionEntity: 323292 spawnLocation: -1408:5:-1285.5 firstTimeSpawn: False
     * 2025-05-11T21:26:25.447144684Z stdout: object User 76561198087774767 (Character: Xallie) has been hidden due to waiting for content!
     * 2025-05-11T21:26:26.416985358Z stdout: object User 76561198087774767 (Character: Xallie) has begun its spawn fadeout!
     *
     * user disconnected:
     * 2025-05-11T21:36:12.388733147Z stdout: object SteamNetworking - SteamNetConnections.ConnectionUpdate: k_ESteamNetworkingConnectionState_ClosedByPeer, 1211981043, 131073
     * 2025-05-11T21:36:12.389027247Z stdout: object SteamServerTransport - Update 1211981043 - k_ESteamNetworkingConnectionState_ClosedByPeer
     * 2025-05-11T21:36:12.390845368Z stdout: object User '{Steam 1211981043}' disconnected. approvedUserIndex: 0 Reason: LeftGame k_ESteamNetworkingConnectionState_ClosedByPeer
     * 2025-05-11T21:36:12.391038888Z stdout: object PlatformSystemBase - EndAuthSession platformId: 76561198087774767
     * 2025-05-11T21:36:12.391925069Z stdout: object EOS.Session - Entering UnregisterUser!
     * 2025-05-11T21:36:12.589278385Z stdout: object SteamNetworking - SteamNetConnections.ConnectionUpdate: k_ESteamNetworkingConnectionState_None, 1211981043, 131073
     * 2025-05-11T21:36:12.589705415Z stdout: object SteamServerTransport - Update 1211981043 - k_ESteamNetworkingConnectionState_None
     */