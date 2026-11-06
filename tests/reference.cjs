// Shared development-only bridge to the existing TypeScript engine.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const project = path.resolve(__dirname, '..');
const prototype = path.resolve(project, '../nilgiris-webtest');
require(path.join(prototype, 'scripts/game-test-runtime.cjs'));
const engine = require(path.join(prototype, 'lib/game/integrity/engine.ts'));
const { contentReadiness } = require(path.join(prototype, 'lib/game/integrity/catalog.ts'));
const files = {
  cards: 'integrity_cards.json', config: 'integrity_config.json',
  forestAttacks: 'integrity_forest_attacks.json', wildlife: 'integrity_wildlife.json',
};
const data = {};
for (const [key, file] of Object.entries(files)) {
  const source = fs.readFileSync(path.join(prototype, 'data', file));
  const local = fs.readFileSync(path.join(project, 'content/data', file));
  assert.ok(source.equals(local), `${file} differs from the prototype; review content drift`);
  data[key] = JSON.parse(local);
}

function snapshot(state, extraFields = []) {
  const fields = [
    'phase', 'roomIndex', 'roundNumber', 'roomRoundNumber', 'roundLimit',
    'integrity', 'bridgeProgress', 'gold', 'purchasedDrawsThisRound', 'weather',
    'deck', 'hand', 'drawPile', 'discardPile', 'nextInstanceId', 'nextOfferId',
    'rewardPoolId', 'constructOfferPoolId', 'rewardPool', 'rewardOffers',
    'rewardRoundType', 'intent', 'cells', 'randomSeed', ...extraFields,
  ];
  return structuredClone(Object.fromEntries(fields.map(key => [key, state[key]])));
}

function runHeadless(script, fixture, temporary, marker) {
  const godot = process.argv[2] || process.env.GODOT_BIN || 'godot';
  function run(args) {
    const result = spawnSync(godot, args, { encoding: 'utf8', timeout: 60000, maxBuffer: 4 * 1024 * 1024 });
    if (result.error) throw result.error;
    if (result.status !== 0 || /(?:SCRIPT ERROR|ERROR:)/.test(result.stderr)) {
      process.stdout.write(result.stdout || '');
      process.stderr.write(result.stderr || '');
      throw new Error(`Godot ${script} failed`);
    }
    return result;
  }
  run(['--headless', '--path', project, '--editor', '--import', '--quit', '--log-file', path.join(temporary, 'import.log')]);
  const result = run([
    '--headless', '--path', project, '--script', script,
    '--log-file', path.join(temporary, 'godot.log'), '--', fixture,
  ]);
  process.stdout.write(result.stdout || '');
  process.stderr.write(result.stderr || '');
  assert.ok(result.stdout.includes(marker), 'Godot did not finish the checks');
  console.log('Content copies match the prototype byte for byte.');
}

module.exports = { project, data, files, engine, contentReadiness, snapshot, runHeadless };
