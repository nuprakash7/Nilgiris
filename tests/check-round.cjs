// Run: node tests/check-round.cjs /path/to/Godot
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { data, engine: e, contentReadiness, snapshot, runHeadless } = require('./reference.cjs');

const extra = [
  'constructsPlacedThisRound', 'playCounts', 'instancePlayCounts', 'roundInstancePlays',
  'selectedReward', 'pendingHabitatId', 'habitatBatch', 'habitatHistory',
  'roundResult', 'lossReason', 'log', 'forestImpacts',
];
const rewards = ['timber-plank', 'iron-spike', 'stone-footing', 'steel-girder', 'left-brace'];
const attackId = 'reward-01-first-drizzle';

function scenario(source) {
  const catalog = structuredClone(source);
  const pool = catalog.config.rewardPools[1];
  const removed = pool.cardIds.filter(id => !rewards.includes(id));
  catalog.config.rewardCardIds = catalog.config.rewardCardIds.filter(id => !removed.includes(id));
  pool.cardIds = [...rewards];
  pool.attackIds = [attackId];
  assert.deepEqual(contentReadiness(catalog), []);
  return catalog;
}

const outcomes = { survived: 0, lost: 0, exactZero: 0, incomplete: 0 };
const cases = [];
const sources = [];
function trace(name, source, seed, rewardIndex, fromEnd, invalidActions = false, rewardLast = false) {
  const catalog = scenario(source);
  let state = e.createInitialState(catalog, { seed });
  const frames = [{ expected: snapshot(state, extra) }];
  function action(request) {
    const before = state;
    const previews = request.type === 'play'
      ? state.cells.map((cell, slotIndex) => e.playError(state, catalog, { instanceId: request.instanceId, slotIndex })
        ? 0 : e.getCardIntegrity(state, catalog, catalog.cards.find(card => card.id === state.hand.find(held => held.instanceId === request.instanceId).cardId), slotIndex, request.instanceId))
      : [];
    state = request.type === 'choose'
      ? e.chooseReward(state, catalog, request.offerId)
      : e.playCard(state, catalog, { instanceId: request.instanceId, slotIndex: request.slotIndex });
    frames.push({ action: request, rejected: state === before, previews, expected: snapshot(state, extra) });
  }
  if (invalidActions) {
    action({ type: 'play', instanceId: state.hand[0].instanceId, slotIndex: 0 });
    action({ type: 'choose', offerId: 'missing' });
  }
  const offerId = state.rewardOffers[rewardIndex].offerId;
  action({ type: 'choose', offerId });
  if (invalidActions) action({ type: 'choose', offerId });
  const slots = fromEnd ? [4, 3, 2, 1, 0] : [0, 2, 4, 1, 3];
  let placed = 0;
  while (state.phase === 'playing') {
    const card = state.hand[fromEnd || (rewardLast && placed === 4) ? state.hand.length - 1 : 0];
    if (invalidActions) {
      action({ type: 'play', instanceId: 'missing', slotIndex: slots[placed] });
      action({ type: 'play', instanceId: card.instanceId, slotIndex: -1 });
      action({ type: 'play', instanceId: card.instanceId, slotIndex: 5 });
      if (placed) action({ type: 'play', instanceId: card.instanceId, slotIndex: slots[0] });
    }
    action({ type: 'play', instanceId: card.instanceId, slotIndex: slots[placed++] });
  }
  if (invalidActions) {
    action({ type: 'play', instanceId: 'card-1', slotIndex: 0 });
    action({ type: 'choose', offerId });
  }
  if (state.phase === 'lost') outcomes.lost++;
  else if (state.roundResult.trialIncomplete) outcomes.incomplete++;
  else {
    outcomes.survived++;
    if (state.roundResult.progress === 0) outcomes.exactZero++;
  }
  let sourceIndex = sources.indexOf(source);
  if (sourceIndex < 0) sourceIndex = sources.push(source) - 1;
  cases.push({ name, sourceIndex, seed, frames });
}

for (let seed = 0; seed < 32; seed++) {
  for (let reward = 0; reward < 4; reward++) {
    for (const fromEnd of [false, true]) {
      trace(`seed ${seed} offer ${reward} ${fromEnd ? 'reward first' : 'reward unplayed'}`, data, seed, reward, fromEnd);
    }
  }
}
trace('illegal actions are no-ops', data, 42, 0, false, true);
const short = structuredClone(data);
short.config.starterDeck = [{ cardId: 'starter-timber-plank', copies: 3 }];
for (let reward = 0; reward < 4; reward++) trace(`incomplete offer ${reward}`, short, 42, reward, false);

// A legal low-power hand: Cross Ties occupy alternate slots before Timber fills gaps.
const weak = structuredClone(data);
weak.config.starterDeck = [{ cardId: 'starter-cross-tie', copies: 3 }, { cardId: 'starter-timber-plank', copies: 2 }];
let weakCases = 0;
for (let offset = 0; offset < 256 && weakCases < 3; offset++) {
  const seed = offset * 65537;
  const opening = e.createInitialState(scenario(weak), { seed });
  if (!opening.hand.slice(0, 3).every(card => card.cardId === 'starter-cross-tie')) continue;
  trace(`weak hand ${seed}`, weak, seed, 0, false);
  const iron = opening.rewardOffers.findIndex(offer => offer.cardId === 'iron-spike');
  if (iron >= 0) trace(`exact-zero hand ${seed}`, weak, seed, iron, false, false, true);
  weakCases++;
}

// Exact-zero survival is reachable in unchanged authored content; prove coverage.
for (const [name, count] of Object.entries(outcomes)) assert.ok(count > 0, `Missing ${name} coverage`);

const unsupported = [
  ['normal effect', cat => { cat.cards.find(card => card.id === 'stone-footing').effects = [{ type: 'support', target: 'any', amount: 1 }]; }],
  ['position condition', cat => { cat.cards.find(card => card.id === 'left-brace').positionEffect.condition = 'bothNeighborsOccupied'; }],
  ['position params', cat => { cat.cards.find(card => card.id === 'left-brace').positionEffect.params = { unexpected: 1 }; }],
  ['checkpoint timing', cat => { cat.forestAttacks[0].hits[0].when = { type: 'everySlotFilled', from: 3 }; }],
  ['conditional hit', cat => { cat.forestAttacks[0].hits[0].conditionalReduction = { type: 'supportUsed', amount: 1 }; }],
  ['invalid weather gain', cat => { cat.forestAttacks[0].weatherDelta.wet = -1; }],
  ['forest event', cat => { cat.forestAttacks[0].midRoundEffects = []; }],
  ['card Retain', cat => { cat.cards.find(card => card.id === 'stone-footing').retain = true; }],
  ['targeted Flair', cat => { cat.cards[0].flair = { type: 'bounce', count: 2 }; }],
  ['invalid Flair amount', cat => { cat.cards[0].flair.amount = -1; }],
  ['conditional Draw', cat => { cat.cards.find(card => card.id === 'stone-footing').draw = { trigger: 'centerSlot', amount: 1 }; }],
  ['boolean Draw', cat => { cat.cards.find(card => card.id === 'stone-footing').draw = { trigger: 'onPlacement', amount: true }; }],
  ['zero Gold effect', cat => { cat.cards.find(card => card.id === 'stone-footing').effects = [{ type: 'gold', amount: 0 }]; }],
].map(([name, change]) => {
  const source = structuredClone(data);
  change(source);
  return { name, source };
});

const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'nilgiris-round-'));
try {
  const fixture = path.join(temporary, 'reference.json');
  fs.writeFileSync(fixture, JSON.stringify({ sources, cases, unsupported, outcomes }));
  runHeadless('res://tests/check_round.gd', fixture, temporary, 'Round checks passed:');
  console.log(`Coverage: ${JSON.stringify(outcomes)}`);
} finally {
  fs.rmSync(temporary, { recursive: true, force: true });
}
