// Fixed action traces through several rounds, using the actual TypeScript rules.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { data, engine: e, contentReadiness, snapshot, runHeadless } = require('./reference.cjs');
const extra = [
  'constructsPlacedThisRound', 'playCounts', 'instancePlayCounts', 'roundInstancePlays',
  'selectedReward', 'pendingHabitatId', 'habitatBatch', 'habitatHistory',
  'roundResult', 'lossReason', 'log', 'forestImpacts', 'forestImpactSequence',
  'animalRoundPending', 'roomGoldPayouts', 'roomClearEvents',
];
const rewards = ['timber-plank', 'iron-spike', 'stone-footing', 'steel-girder', 'left-brace', 'staging-deck'];
const attacks = ['reward-01-first-drizzle', 'reward-02-passing-shower'];
function scenario(source) {
  const catalog = structuredClone(source);
  const pool = catalog.config.rewardPools[1];
  const removed = pool.cardIds.filter(id => !rewards.includes(id));
  catalog.config.rewardCardIds = catalog.config.rewardCardIds.filter(id => !removed.includes(id));
  pool.cardIds = [...rewards];
  pool.attackIds = [...attacks];
  assert.deepEqual(contentReadiness(catalog), []);
  return catalog;
}
const sources = [];
const cases = [];
const coverage = { buys: 0, flair: 0, rewardFlair: 0, spentCopiesReplayed: 0, normalDraw: 0, reshuffles: 0, next: 0, animalStops: 0, roomClears: 0, incomplete: 0, deadline: 0, wins: 0, rejected: 0 };
function trace(name, source, seed, policy, patch = {}) {
  const catalog = scenario(source);
  let state = e.createInitialState(catalog, { seed });
  if (patch.roundLimit) state.roundLimit = patch.roundLimit;
  if (patch.handSize) state.drawPile.unshift(...state.hand.splice(patch.handSize));
  const frames = [{ expected: snapshot(state, extra) }];
  function act(request) {
    const before = state;
    const oldSeed = state.randomSeed;
    const depleted = state.drawPile.length === 0 && state.discardPile.length > 0;
    const held = request.type === 'play' && state.hand.find(card => card.instanceId === request.instanceId);
    let previews = [];
    switch (request.type) {
      case 'choose': state = e.chooseReward(state, catalog, request.offerId); break;
      case 'play': {
        previews = state.cells.map((cell, slotIndex) => e.playError(state, catalog, { instanceId: request.instanceId, slotIndex })
          ? 0 : e.getCardIntegrity(state, catalog, catalog.cards.find(card => card.id === held.cardId), slotIndex, held.instanceId));
        state = e.playCard(state, catalog, { instanceId: request.instanceId, slotIndex: request.slotIndex });
        break;
      }
      case 'buy': state = e.purchaseDraw(state, catalog); break;
      case 'flair': state = e.activateFlair(state, catalog, request.instanceId); break;
      case 'next':
        // Explicit slice boundary; don't replace an animal round with a Construct round.
        if (!state.animalRoundPending && state.rewardPoolId === 1) state = e.startNextRound(state, catalog);
        break;
    }
    const rejected = state === before;
    if (rejected) coverage.rejected++;
    else {
      if (depleted && state.randomSeed !== oldSeed) coverage.reshuffles++;
      if (request.type === 'buy') coverage.buys++;
      if (request.type === 'flair') {
        coverage.flair++;
        if (request.instanceId === before.selectedReward?.instanceId) coverage.rewardFlair++;
      }
      if (held?.flairSpent) coverage.spentCopiesReplayed++;
      if (held?.cardId === 'staging-deck') coverage.normalDraw++;
      if (request.type === 'next') coverage.next++;
    }
    frames.push({ action: request, rejected, previews, expected: snapshot(state, extra) });
  }
  act({ type: 'buy' });
  act({ type: 'next' });
  let guard = 0;
  while (guard++ < 30) {
    const preferred = state.rewardOffers.find(offer => offer.cardId === 'staging-deck') || state.rewardOffers[0];
    act({ type: 'choose', offerId: preferred.offerId });
    let placed = 0;
    if (policy === 'capacity') {
      while (!e.purchaseDrawError(state, catalog)) act({ type: 'buy' });
      act({ type: 'buy' });
    }
    while (state.phase === 'playing') {
      const card = policy === 'last-staging' && placed < 4 ? state.hand[0]
        : state.hand.find(card => card.cardId === 'staging-deck') || state.hand[0];
      const slotIndex = [0, 2, 4, 1, 3][placed++];
      act({ type: 'play', instanceId: card.instanceId, slotIndex });
      if (state.phase !== 'playing') break;
      if (['abilities', 'capacity'].includes(policy)) {
        if (policy === 'capacity' && !e.purchaseDrawError(state, catalog)) act({ type: 'buy' });
        for (const cell of [...state.cells]) {
          if (cell.construct && !e.flairError(state, catalog, cell.construct.instanceId)) {
            act({ type: 'flair', instanceId: cell.construct.instanceId });
            act({ type: 'flair', instanceId: cell.construct.instanceId });
          }
        }
        if (placed === 1) act({ type: 'buy' });
      }
    }
    act({ type: 'buy' });
    act({ type: 'flair', instanceId: 'card-1' });
    if (state.roundResult?.trialIncomplete) coverage.incomplete++;
    if (state.phase === 'roomComplete') coverage.roomClears++;
    if (state.phase === 'won') coverage.wins++;
    if (state.lossReason?.startsWith('Round limit')) coverage.deadline++;
    if (state.animalRoundPending) coverage.animalStops++;
    if (state.phase !== 'roundComplete' || state.animalRoundPending || state.rewardPoolId !== 1) {
      act({ type: 'next' });
      break;
    }
    act({ type: 'next' });
  }
  assert.ok(guard < 30, 'Trace did not reach a slice boundary');
  let sourceIndex = sources.indexOf(source);
  if (sourceIndex < 0) sourceIndex = sources.push(source) - 1;
  cases.push({ name, sourceIndex, seed, patch, frames });
}
for (let index = 0; index < 32; index++) {
  for (const policy of ['plain', 'abilities']) trace(`${policy} ${index}`, data, index * 65537, policy);
}
trace('final-slot Draw and Gold resolve before cleanup', data, 42, 'last-staging');
const rich = structuredClone(data);
rich.config.startingGold = 100;
rich.config.starterDeck = [{ cardId: 'starter-cross-tie', copies: 24 }];
trace('hand capacity and expensive draws', rich, 42, 'capacity');
const short = structuredClone(data);
short.config.starterDeck = [{ cardId: 'starter-timber-plank', copies: 3 }];
trace('short deck and incomplete cleanup', short, 42, 'plain');
trace('empty hand cannot buy rescue', data, 42, 'plain', { handSize: 1 });
trace('deadline defeat', data, 42, 'abilities', { roundLimit: 1 });
const room = structuredClone(data);
room.config.starterDeck = [{ cardId: 'starter-iron-spike', copies: 12 }];
room.config.rooms[0].requiredProgress = 1;
trace('room Gold payout', room, 42, 'plain');
const win = structuredClone(room);
for (const room of win.config.rooms) room.requiredProgress = 2;
trace('overflow payouts and deadline win precedence', win, 42, 'plain', { roundLimit: 1 });
for (const [name, count] of Object.entries(coverage)) assert.ok(count > 0, `Missing ${name} coverage`);

const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'nilgiris-slice-'));
try {
  const fixture = path.join(temporary, 'reference.json');
  fs.writeFileSync(fixture, JSON.stringify({ scenario: 'slice', sources, cases, unsupported: [] }));
  runHeadless('res://tests/check_round.gd', fixture, temporary, 'Round checks passed:');
  console.log(`Slice coverage: ${JSON.stringify(coverage)}`);
} finally {
  fs.rmSync(temporary, { recursive: true, force: true });
}
