const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { data, engine: e, snapshot, runHeadless } = require('./reference.cjs');
const sources = [], cases = [];
const common = data.wildlife.animals.filter(a => a.rarity === 'common');
const extra = ['constructsPlacedThisRound','playCounts','instancePlayCounts','roundInstancePlays','selectedReward','pendingHabitatId','habitatBatch','habitatHistory','roundResult','lossReason','log','forestImpacts','forestImpactSequence','animalRoundPending','roomGoldPayouts','roomClearEvents','animals','animalCapacity','nextAnimalInstanceId','pendingAnimal','animalOffers','selectedAnimalId','resumeConstructOffers','animalEncounters','sightings','nextHitReduction'];
const coverage = { cards: new Set(), attacks: new Set(), animals: new Set(), acquired: 0, choices: 0, trial: 0, rejected: 0, incomplete: 0 };
function snap(s) {
 const result = snapshot(s, extra);
 result.placementBonuses = structuredClone(s.animalRound.placementBonuses);
 const c = s.pendingChoice;
 result.choice = c ? { ids:c.cards.map(c=>c.instanceId), remaining:c.remaining, selected:c.selectedTargetIds, optional:c.optional, effect:structuredClone(c.animalEffect), title:c.title } : null;
 return result;
}
function trace(name, seed, patch={}, attackId=null) {
 const source = structuredClone(data);
 if (attackId) source.config.rewardPools[1].attackIds = [attackId];
 const sourceIndex = sources.push(source)-1;
 if(patch.nonNeutral) for(const [i,animal] of source.wildlife.animals.entries())for(const [j,h]of source.wildlife.habitats.entries())animal.habitatAffinities[h.id]=(i+j)%4;
 const catalog = structuredClone(source); catalog.wildlife.animals = catalog.wildlife.animals.filter(a=>a.rarity==='common');
 let s = e.createInitialState(catalog,{seed});
 if(patch.forceAnimal) {
  s.phase='roundComplete';s.animalRoundPending=true;s.habitatBatch=['woods','woods','canopies'];
  s.hand=[];s.drawPile=[];s.discardPile=[];s.deck=[];
 }
 if(patch.animals) s.animals=structuredClone(patch.animals);
 if(patch.capacity!==undefined) s.animalCapacity=patch.capacity;
 if(patch.cardId) {
  let card = [...s.hand,...s.drawPile].find(c=>c.instanceId==='card-1');
  s.drawPile=s.drawPile.filter(c=>c.instanceId!=='card-1');
  if(!s.hand.includes(card))s.hand.push(card);
  card.cardId=patch.cardId;
 }
 const frames=[{expected:snap(s)}];
 function act(action) {
  let before=s,previews=[];
  switch(action.type) {
   case 'choose':s=e.chooseReward(s,catalog,action.offerId);break;
   case 'animalReward':s=e.chooseAnimalReward(s,catalog,action.offerId);break;
   case 'animal':s=e.activateAnimal(s,catalog,action.instanceId);break;
   case 'choice':s=e.resolveChoice(s,catalog,action.instanceId||null);break;
   case 'acquire':s=e.resolveAnimalAcquisition(s,action.instanceId||null);break;
   case 'buy':s=e.purchaseDraw(s,catalog);break;
   case 'flair':s=e.activateFlair(s,catalog,action.instanceId);break;
   case 'next':if(s.rewardPoolId===1)s=e.startNextRound(s,catalog);break;
   case 'play': {
    const held=s.hand.find(c=>c.instanceId===action.instanceId);
    previews=s.cells.map((cell,slotIndex)=>e.playError(s,catalog,{instanceId:action.instanceId,slotIndex})?0:e.getCardIntegrity(s,catalog,catalog.cards.find(c=>c.id===held.cardId),slotIndex,held.instanceId));
    s=e.playCard(s,catalog,{instanceId:action.instanceId,slotIndex:action.slotIndex});break;
   }
  }
  if(s===before)coverage.rejected++;
  if(action.type==='choice'&&s!==before)coverage.choices++;
  if(action.type==='play'&&s!==before)coverage.cards.add(before.hand.find(c=>c.instanceId===action.instanceId).cardId);
  if(action.type==='animal'&&s!==before)coverage.animals.add(before.animals.find(a=>a.instanceId===action.instanceId).animalId);
  frames.push({action,previews,rejected:s===before,expected:snap(s)});
 }
 act({type:'buy'});
 if(patch.forceAnimal)act({type:'next'});
 let activated=false;
 for(let turn=0;turn<100;turn++) {
  if(s.phase==='roundChoice'){
   coverage.attacks.add(s.intent.attackId);
   if(s.rewardRoundType==='animal'){coverage.trial++;act({type:'animalReward',offerId:s.animalOffers[0].offerId});}
   else act({type:'choose',offerId:s.rewardOffers[0].offerId});
  } else if(s.pendingChoice){
   const c=s.pendingChoice;
   act({type:'buy'}); // Targeting locks paid Draw too.
   act({type:'choice',instanceId:'missing'});
   if(!c.optional)act({type:'choice'});
   if(c.optional&&patch.cancelChoice){act({type:'choice'});continue;}
   act({type:'choice',instanceId:c.cards[0].instanceId});
   if(s.pendingChoice?.optional)act({type:'choice'});
  } else if(s.phase==='playing') {
   if(!activated&&s.animals.length&&s.constructsPlacedThisRound>=2){act({type:'animal',instanceId:s.animals[0].instanceId});act({type:'animal',instanceId:s.animals[0].instanceId});activated=true;continue;}
   const flair=s.cells.find(c=>c.construct&&!e.flairError(s,catalog,c.construct.instanceId));
   if(flair){act({type:'flair',instanceId:flair.construct.instanceId});continue;}
   const card=s.hand.find(c=>c.instanceId==='card-1')||s.hand[0];
   if(!card)break;
   const choices=s.cells.filter(c=>!c.construct).map(c=>({slot:c.slotIndex,gain:e.getCardIntegrity(s,catalog,catalog.cards.find(d=>d.id===card.cardId),c.slotIndex,card.instanceId)})).sort((a,b)=>b.gain-a.gain||a.slot-b.slot);
   act({type:'play',instanceId:card.instanceId,slotIndex:choices[0].slot});
  } else if(s.pendingAnimal) {
   act({type:'next'});act({type:'acquire',instanceId:'missing'});act({type:'acquire',...(s.animals.length?{instanceId:s.animals[0].instanceId}:{})});
  } else if(s.phase==='roundComplete'&&s.rewardPoolId===1) {
   if(s.roundResult?.earnedAnimalId)coverage.acquired++;
   if(s.roundResult?.trialIncomplete)coverage.incomplete++;
   act({type:'next'});activated=false;
  } else break;
 }
 cases.push({name,sourceIndex,seed,patch,frames});
}
const pool=data.config.rewardPools[1];
for(const id of pool.cardIds)for(const attack of pool.attackIds)trace(`${id}/${attack}`,42,{cardId:id},attack);
for(const animal of common)for(const seed of [1,42,127])trace(`${animal.id}/${seed}`,seed,{animals:[{instanceId:'animal-test',animalId:animal.id,acquisitionRound:0,lastActivationRound:null,nextEligibleRound:1,effectState:{activations:0}}]});
for(let seed=0;seed<100;seed++)trace(`natural/${seed}`,seed,{capacity:seed%2?4:0});
for(let seed=0;seed<6;seed++)trace(`non-neutral/${seed}`,seed,{nonNeutral:true});
trace('empty animal trial retries',42,{forceAnimal:true});
for(const id of ['bonnet-macaque-troop','peafowl-flock','spotted-dove-pair'])trace(`cancel/${id}`,11,{cancelChoice:true,capacity:1,animals:[{instanceId:'animal-test',animalId:id,acquisitionRound:0,lastActivationRound:null,nextEligibleRound:1,effectState:{activations:0}}]});
assert.equal(coverage.attacks.size,15);assert.equal(coverage.animals.size,20);assert.ok(coverage.trial&&coverage.acquired&&coverage.choices&&coverage.rejected);
const invalidWildlife = [
 ['unknown effect',s=>s.wildlife.animals.find(a=>a.rarity==='common').effect={type:'invented',amount:3}],
 ['negative cooldown',s=>s.wildlife.animals.find(a=>a.rarity==='common').cooldown=-1],
 ['negative weight',s=>s.wildlife.rarityWeights.common=-1],
 ['bad affinity',s=>s.wildlife.animals.find(a=>a.rarity==='common').habitatAffinities.woods=-1],
 ['no eligible batch',s=>s.wildlife.animals.forEach(a=>a.habitatAffinities={})],
 ['invalid optional',s=>s.wildlife.animals.find(a=>a.id==='peafowl-flock').effect.optional='yes'],
 ['invalid look',s=>s.wildlife.animals.find(a=>a.id==='common-kingfisher').effect.lookCount=0],
 ['wrong choice parameter',s=>s.wildlife.animals.find(a=>a.id==='peafowl-flock').effect.amount=3],
 ['unknown definition field',s=>s.wildlife.animals.find(a=>a.rarity==='common').invented=true],
].map(([name,change])=>{const source=structuredClone(data);change(source);return {name,source};});
const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'nilgiris-pool-one-'));
try{
 const fixture=path.join(temporary,'reference.json');fs.writeFileSync(fixture,JSON.stringify({scenario:'pool1',sources,cases,unsupported:[],invalidWildlife}));
 runHeadless('res://tests/check_round.gd',fixture,temporary,'Round checks passed:');
 console.log('Pool 1 coverage:',JSON.stringify({...coverage,cards:coverage.cards.size,attacks:coverage.attacks.size,animals:coverage.animals.size}));
}finally{fs.rmSync(temporary,{recursive:true,force:true});}
