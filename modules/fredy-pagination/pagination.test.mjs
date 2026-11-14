import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import vm from 'node:vm';
import { collectSearchPages } from './pagination.js';
const options = { delayMs: 0 };
const page = (ids, total, rest = {}) => ({ ids, items: ids.map(id => ({ id })), total, ...rest });
test('fetches beyond a full first page, deduplicates and reaches total', async () => {
  const seen = [];
  const result = await collectSearchPages(async n => { seen.push(n); return n === 1 ? page([1, 2], 3) : page([2, 3], 3); }, options);
  assert.deepEqual(seen, [1, 2]); assert.equal(result.complete, true);
  assert.deepEqual(result.items.map(x => x.id), [1, 2, 3]);
});
test('keeps pages and partial cards, stops at errors without retrying', async () => {
  const r = await collectSearchPages(async n => n === 1 ? page([1], 4) : page([2], 4, { error: 'search HTTP 429' }), options);
  assert.equal(r.complete, false); assert.equal(r.pages, 2); assert.equal(r.items.length, 2);
});
test('keeps successful pages after transport exception', async () => {
  const r = await collectSearchPages(async n => { if(n === 2) throw Error('timeout'); return page([1], 2); }, options);
  assert.equal(r.complete, false); assert.equal(r.items.length, 1);
});
test('repeated pages cannot loop indefinitely', async () => {
  const r = await collectSearchPages(async () => page([1], 99), options);
  assert.equal(r.reason, 'repeated page'); assert.equal(r.pages, 2);
});
test('page cap is explicit and never claims completeness', async () => {
  const r = await collectSearchPages(async n => page([n], 99), options);
  assert.equal(r.pages, 5); assert.equal(r.complete, false); assert.equal(r.reason, 'page limit');
});
test('empty first page with zero total is complete', async () => {
  assert.equal((await collectSearchPages(async () => page([], 0), options)).complete, true);
});
test('empty or reported final page before total is incomplete', async () => {
  for (const response of [page([], 4), page([1], 4, { pageCount: 1 })]) {
    assert.equal((await collectSearchPages(async () => response, options)).complete, false);
  }
});
test('counts cards a page reports missing without stopping', async () => {
  const r = await collectSearchPages(async n => n === 1 ? page([1, 2], 3, { missing: 1 }) : page([3], 3), options);
  assert.equal(r.complete, true); assert.equal(r.pages, 2); assert.equal(r.missing, 1);
});
test('deadline prevents another request', async () => {
  let clock = 0, calls = 0;
  const r = await collectSearchPages(async () => { calls++; clock=200000; return page([1], 20); }, { ...options, now: () => clock });
  assert.equal(calls, 1); assert.equal(r.reason, 'time budget');
});

// Load the actual patched provider modules with inert imports: no DB, browser,
// HTTP, tracking or notifications. page.evaluate executes its real callback.
async function loadProvider(relative, fetchImpl) {
  const warnings=[], calls=[], closed=[];
  const context=vm.createContext({ URL, AbortSignal, Date, console, fetch: fetchImpl, setTimeout: fn=>setTimeout(fn,0), clearTimeout });
  const logger={debug:()=>{},warn:m=>warnings.push(m),error:m=>warnings.push(m)};
  const fakePage={evaluate:async(fn,...args)=>{calls.push(args);return fn(...args);}};
  const values={
    '../../utils.js':{ buildHash:()=>'',isOneOf:()=>false,nullOrEmpty:x=>!x,randomBetween:()=>0,sleep:async()=>{} },
    '../listings/activeProbeBackoff.js':{MAX_PROBE_ATTEMPTS:1,backoffDelay:()=>0,retryAfterDelay:()=>0},
    './immoscout-web-translator.js':{convertImmoscoutListingToMobileListing:x=>x},
    '../logger.js':{default:logger},
    '../../utils/extract-number.js':{extractNumber:x=>x},
    '../../utils/buildingFacts.js':{normalizeBuildYear:x=>x,normalizeEnergyClass:x=>x},
    '../tracking/Tracker.js':{trackPoi:async()=>{}},
    '../../TRACKING_POIS.js':{TRACKING_POIS:{}},
    '../extractor/warmPages.js':{acquireWarmPage:async()=>fakePage,releaseWarmPage:async()=>closed.push(true)},
    './immowelt-search-model.js':{isochroneToPolylines:()=>[]},
    './site.js':{SITES:{'immowelt.de':{origin:'https://www.immowelt.de'}},linkedSiteOf:()=>null,siteOf:()=>null},
  };
  const root=process.env.FREDY_SOURCE;
  assert.ok(root,'Set FREDY_SOURCE to the patched source tree');
  const mod=new vm.SourceTextModule(await fs.readFile(`${root}/${relative}`,'utf8'),{context});
  await mod.link(async spec=>{
    if(spec==='../searchPagination.js') return new vm.SourceTextModule(await fs.readFile(new URL('./pagination.js',import.meta.url),'utf8'),{context});
    assert.ok(values[spec],`Unstubbed import ${spec}`);
    const data=values[spec];return new vm.SyntheticModule(Object.keys(data),function(){for(const [k,v] of Object.entries(data))this.setExport(k,v);},{context});
  });
  await mod.evaluate();return {exports:mod.namespace,warnings,calls,closed};
}
const response=(data,status=200)=>({ok:status===200,status,json:async()=>data});
const expose=id=>({type:'EXPOSE_RESULT',item:{id,title:`Flat ${id}`,attributes:[]}});
test('actual ImmoScout adapter requests 100/page, keeps filters, gets later listings',async()=>{
 const urls=[];
 const p=await loadProvider('lib/services/immoscout/mobileApi.js',async u=>{
  urls.push(new URL(u));const n=Number(u.searchParams.get('pagenumber'));
  return response({totalResults:2,numberOfPages:2,resultListItems:[expose(n)]});
 });
 const cfg=p.exports.buildImmoscoutProvider({toMobileSearchUrl:x=>x}).config;
 const rows=await cfg.getListings('https://api.mobile.immobilienscout24.de/search/list?price=-1500&sorting=-firstactivation');
 assert.equal(rows.length,2);assert.equal(urls.length,2);
 for(const u of urls){assert.equal(u.searchParams.get('pagesize'),'100');assert.equal(u.searchParams.get('price'),'-1500');assert.equal(u.searchParams.get('sorting'),'-firstactivation');}
});
test('actual ImmoScout adapter retains first page on 429 and warns',async()=>{
 let n=0;const p=await loadProvider('lib/services/immoscout/mobileApi.js',async()=>++n===1?response({totalResults:2,resultListItems:[expose(1)]}):response({},429));
 const rows=await p.exports.buildImmoscoutProvider({}).config.getListings('https://example.org/search');
 assert.equal(rows.length,1);assert.equal(n,2);assert.match(p.warnings.join(' '),/incomplete.*429/);
});
test('actual Immowelt adapter pages ids and keeps card batches at 30',async()=>{
 const searches=[],batches=[];
 const p=await loadProvider('lib/services/immowelt/immoweltBff.js',async(url,opts)=>{
  if(url==='/serp-bff/search'){
   const q=JSON.parse(opts.body);searches.push(q);
   const ids=q.paging.page===1?Array.from({length:31},(_,i)=>i+1):[31,32];
   return response({totalCount:32,classifieds:ids.map(id=>({id}))});
  }
  const ids=url.split('/').pop().split(',');batches.push(ids);return response(ids.map(id=>({id})));
 });
 const rows=await p.exports.searchClassifieds({}, {criteria:{priceMax:1500},paging:{page:8,size:100,order:'DateDesc'}},{host:'immowelt.de',origin:'https://www.immowelt.de',language:'de'});
 assert.equal(rows.length,32);assert.deepEqual(searches.map(q=>q.paging.page),[1,2]);
 assert.ok(batches.every(b=>b.length<=30));assert.ok(searches.every(q=>q.criteria.priceMax===1500));
});
test('actual Immowelt adapter retains partial batch and stops on blocked cards',async()=>{
 let batches=0,searches=0;
 const p=await loadProvider('lib/services/immowelt/immoweltBff.js',async(url)=>{
  if(url==='/serp-bff/search'){searches++;return response({totalCount:35,classifieds:Array.from({length:35},(_,i)=>({id:i+1}))});}
  if(++batches===2)return response({},403);
  return response(url.split('/').pop().split(',').map(id=>({id})));
 });
 const rows=await p.exports.searchClassifieds({}, {criteria:{},paging:{page:1,size:100}},{host:'immowelt.de',origin:'https://www.immowelt.de',language:'de'});
 assert.equal(rows.length,30);assert.equal(searches,1);assert.equal(batches,2);assert.equal(p.closed.length,1);
 assert.match(p.warnings.join(' '),/incomplete: cards HTTP 403/);
});
test('actual Immowelt adapter treats an empty card batch as incomplete',async()=>{
 let searches=0;
 const p=await loadProvider('lib/services/immowelt/immoweltBff.js',async(url)=>{
  if(url==='/serp-bff/search'){searches++;return response({totalCount:5,classifieds:Array.from({length:5},(_,i)=>({id:i+1}))});}
  return response([]);
 });
 const rows=await p.exports.searchClassifieds({}, {criteria:{},paging:{page:1,size:100}},{host:'immowelt.de',origin:'https://www.immowelt.de',language:'de'});
 assert.equal(rows.length,0);assert.equal(searches,1);
 assert.match(p.warnings.join(' '),/incomplete: empty card response/);
});
test('actual Immowelt adapter continues past a card that is no longer returned',async()=>{
 const searches=[],batches=[];
 const p=await loadProvider('lib/services/immowelt/immoweltBff.js',async(url,opts)=>{
  if(url==='/serp-bff/search'){
   const q=JSON.parse(opts.body);searches.push(q.paging.page);
   const ids=q.paging.page===1?Array.from({length:35},(_,i)=>i+1):[36];
   return response({totalCount:36,classifieds:ids.map(id=>({id}))});
  }
  const ids=url.split('/').pop().split(',');batches.push(ids.length);
  return response(ids.filter(id=>id!=='2').map(id=>({id})));
 });
 const rows=await p.exports.searchClassifieds({}, {criteria:{},paging:{page:1,size:100}},{host:'immowelt.de',origin:'https://www.immowelt.de',language:'de'});
 assert.equal(rows.length,35);assert.deepEqual(searches,[1,2]);assert.deepEqual(batches,[30,5,1]);
 assert.equal(p.closed.length,0);assert.match(p.warnings.join(' '),/1 listed cards were not returned/);
 assert.doesNotMatch(p.warnings.join(' '),/incomplete/);
});
test('ImmoScout block suppresses detail requests for that run',async()=>{
 let calls=0;
 const p=await loadProvider('lib/services/immoscout/mobileApi.js',async()=>{calls++;return response({},429);});
 const cfg=p.exports.buildImmoscoutProvider({}).config;
 // Fredy calls getListings with its pipeline instance and fetchDetails on config.
 await cfg.getListings.call({_providerConfig:cfg},'https://example.org/search');
 const listing={id:'old',link:'https://example.org/expose/1'};
 assert.equal(await cfg.fetchDetails(listing),listing);assert.equal(calls,1);
});
