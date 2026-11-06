// Run from any directory: node tests/check-setup.cjs /path/to/Godot
// The prototype is a development oracle, never a runtime dependency.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { project, data, files, engine: { createInitialState }, contentReadiness, snapshot, runHeadless } = require('./reference.cjs');

const seeds = [
  -4294967297, -1, 0, 1, 42, 2147483647, 2147483648,
  4294967295, 4294967296, 4294967297, Number.MAX_SAFE_INTEGER,
  Number.MIN_SAFE_INTEGER, ...Array.from({ length: 64 }, (_, i) => i * 65537),
];
const variants = [
  ['authored', () => {}],
  ['pool attack IDs reversed', cat => cat.config.rewardPools[1].attackIds.reverse()],
  ['catalog attack order reversed', cat => cat.forestAttacks.reverse()],
  ['weather-gated candidates', cat => {
    for (const attack of cat.forestAttacks.slice(0, 7)) attack.requires.wet = 1;
  }],
  ['short starter deck and zero Gold', cat => {
    cat.config.starterDeck = [{ cardId: cat.config.starterDeck[0].cardId, copies: 3 }];
    cat.config.startingGold = 0;
  }],
  ['default Gold', cat => { delete cat.config.startingGold; }],
];
const scenarios = variants.map(([name, change]) => {
  const catalog = structuredClone(data);
  change(catalog);
  assert.deepEqual(contentReadiness(catalog), [], `${name}: invalid reference scenario`);
  return { name, data: catalog, cases: seeds.map(seed => ({ seed, expected: snapshot(createInitialState(catalog, { seed })) })) };
});

const corruptions = [
  ['missing root data', cat => { delete cat.config; }],
  ['non-object wildlife', cat => { cat.wildlife = []; }],
  ['empty cards', cat => { cat.cards = []; }],
  ['non-object card', cat => { cat.cards[0] = 7; }],
  ['duplicate card ID', cat => { cat.cards[1].id = cat.cards[0].id; }],
  ['fractional power', cat => { cat.cards[0].baseIntegrity = 1.5; }],
  ['duplicate habitat', cat => { cat.wildlife.habitats[1].id = cat.wildlife.habitats[0].id; }],
  ['empty habitats', cat => { cat.wildlife.habitats = []; }],
  ['bad hand limit', cat => { cat.config.handLimit = 99; }],
  ['negative Gold', cat => { cat.config.startingGold = -1; }],
  ['unsafe Gold', cat => { cat.config.startingGold = 2 ** 53; }],
  ['boolean Gold', cat => { cat.config.startingGold = true; }],
  ['fractional copies', cat => { cat.config.starterDeck[0].copies = 2.5; }],
  ['unknown starter', cat => { cat.config.starterDeck[0].cardId = 'missing'; }],
  ['starter offered as reward', cat => { cat.config.rewardCardIds.push(cat.cards[0].id); }],
  ['missing rooms', cat => { cat.config.rooms = []; }],
  ['invalid room progress', cat => { cat.config.rooms[0].requiredProgress = 0; }],
  ['duplicate reward', cat => { cat.config.rewardCardIds.push(cat.config.rewardCardIds[0]); }],
  ['unknown pool card', cat => { cat.config.rewardPools[1].cardIds[0] = 'missing'; }],
  ['unknown pool attack', cat => { cat.config.rewardPools[1].attackIds[0] = 'missing'; }],
  ['no active pools', cat => { cat.config.rewardPools = [cat.config.rewardPools[0]]; }],
  ['out of order pools', cat => { cat.config.rewardPools[2].id = 1; }],
  ['no spare offer', cat => { cat.config.rewardPools[1].cardIds = cat.config.rewardPools[1].cardIds.slice(0, 4); }],
  ['no eligible initial attack', cat => {
    for (const attack of cat.forestAttacks.slice(0, 15)) attack.requires.wet = 1;
  }],
  ['invalid requirements', cat => { cat.forestAttacks[0].requires = null; }],
  ['invalid board width', cat => { cat.forestAttacks[0].boardSize = 6; }],
];
const invalid = corruptions.map(([name, change]) => {
  const catalog = structuredClone(data);
  change(catalog);
  return { name, data: catalog };
});

// Exercise successive LCG overflow, including signed and wrapped initial seeds.
const randomCases = seeds.slice(0, 12).map(seed => {
  let current = seed >>> 0;
  const values = Array.from({ length: 100 }, () => {
    current = (Math.imul(current, 1664525) + 1013904223) >>> 0;
    return { seed: current, roll: current / 4294967296 };
  });
  return { seed, values };
});

const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'nilgiris-setup-'));
try {
  const badDirectory = path.join(temporary, 'invalid-json');
  fs.mkdirSync(badDirectory);
  for (const file of Object.values(files)) {
    fs.copyFileSync(path.join(project, 'content/data', file), path.join(badDirectory, file));
  }
  fs.writeFileSync(path.join(badDirectory, files.config), '{ invalid JSON');
  const fixture = path.join(temporary, 'reference.json');
  fs.writeFileSync(fixture, JSON.stringify({ scenarios, invalid, randomCases, badDirectory }));
  runHeadless('res://tests/check_setup.gd', fixture, temporary, 'Setup checks passed:');
} finally {
  fs.rmSync(temporary, { recursive: true, force: true });
}
