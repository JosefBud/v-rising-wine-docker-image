#!/bin/sh

# cd /saves/Settings
# cp -ft / launch-server.ts package.json bun.lock tsconfig.json
# cd /
# bun install --frozen-lockfile
bun migrate
bun start