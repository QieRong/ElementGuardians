/* Reproducible static layout export. Uses the host's bundled Playwright. */
const fs = require('fs');
const path = require('path');
const http = require('http');
const { chromium } = require('playwright');
const root = path.resolve(__dirname, '../../..');
const output = path.resolve(__dirname, '..');
const evidence = path.join(root, 'logs/test_runs/20261021_visual_draft');
const mime = {'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.js':'text/javascript; charset=utf-8','.json':'application/json; charset=utf-8','.png':'image/png'};
const server = http.createServer((req,res)=>{
 const file = path.resolve(root, '.'+decodeURIComponent(new URL(req.url,'http://localhost').pathname));
 if(!file.startsWith(root+path.sep)){res.writeHead(403).end();return;}
 fs.readFile(file,(err,data)=>{if(err){res.writeHead(404).end();return;}res.setHeader('Content-Type',mime[path.extname(file)]||'application/octet-stream');res.end(data);});
});
const checks=[];
function check(id,ok,detail){checks.push({id,status:ok?'PASS':'FAIL',detail});}
async function layoutAudit(page,name){
 const result = await page.evaluate(()=>{
  const bounds=[...document.querySelectorAll('[data-fit]')].map(el=>({text:el.textContent,overflow:el.scrollWidth>el.clientWidth+1||el.scrollHeight>el.clientHeight+1}));
  const slots=[...document.querySelectorAll('[data-slot]')].map(el=>{const b=el.getBoundingClientRect();return {id:Number(el.dataset.slot),x:b.x,y:b.y,w:b.width,h:b.height};});
  return {bounds,slots,route:document.querySelector('[data-route]')?.getAttribute('points'),map:window.mapData,images:[...document.images].map(im=>({src:im.getAttribute('src'),ok:im.complete&&im.naturalWidth>0})),fonts:[...document.fonts].map(f=>({family:f.family,status:f.status})),text:document.body.innerText,sample:window.sampleData};
 });
 check(name+'-text',result.bounds.every(x=>!x.overflow),result.bounds);
 check(name+'-assets',result.images.every(x=>x.ok),result.images);
 if(result.map){
  check(name+'-geometry',result.slots.length===9&&result.slots.every(s=>{const m=result.map.slots[s.id];return s.x===m.center[0]-38&&s.y===m.center[1]-38&&s.w===76&&s.h===76;})&&result.route===result.map.path.map(p=>p.join(',')).join(' '),{slots:result.slots,route:result.route});
  if(name==='initial')check('initial-contract',result.sample.gold===60&&Object.keys(result.sample.occupants).length===0&&result.text.includes('10 / 10')&&result.text.includes('请先选择空格'),result.sample);
  if(name==='combat')check('combat-contract',result.sample.locked&&result.text.includes('战斗中不可召唤或合成')&&result.text.includes('本波进行中'),result.sample);
 }
 return result;
}
(async()=>{
 fs.mkdirSync(path.join(output,'states'),{recursive:true});fs.mkdirSync(path.join(output,'previews'),{recursive:true});
 await new Promise(r=>server.listen(0,'127.0.0.1',r));
 const base=`http://127.0.0.1:${server.address().port}/output/visuals/sources/ui.html`;
 let browser;
 try{
  browser=await chromium.launch({headless:true,channel:'chrome'});
  const page=await browser.newPage({viewport:{width:720,height:1280},deviceScaleFactor:1});
  page.on('pageerror',err=>check('browser-error',false,String(err)));
  const names=['menu','combat','initial','selected','poor','merge','merged','type','level','max','occupied','full'];
  for(const name of names){
   await page.goto(base+(name==='menu'?'?page=menu':`?page=battle&state=${name}`));await page.evaluate(()=>window.ready);
   const info=await layoutAudit(page,name);
   const filename=name==='menu'?'menu-v01.png':name==='combat'?'battle-v01.png':`states/${name}.png`;
   await page.screenshot({path:path.join(output,filename)});
   await page.addStyleTag({content:'#canvas{transform:scale(.75);transform-origin:top left}body{width:540px;height:960px;overflow:hidden}'});
   await page.setViewportSize({width:540,height:960});
   await page.screenshot({path:path.join(output,`previews/${name}-075.png`)});
   await page.setViewportSize({width:720,height:1280});
   fs.writeFileSync(path.join(evidence,`${name}-layout.json`),JSON.stringify(info,null,2));
  }
  await page.goto(base+'?page=inspect');await page.evaluate(()=>window.ready);
  await layoutAudit(page,'inspection');
  await page.locator('#canvas').screenshot({path:path.join(output,'states/inspection.png')});
  await page.addStyleTag({content:'#canvas{filter:grayscale(1)}'});
  await page.locator('#canvas').screenshot({path:path.join(output,'states/inspection-grayscale.png')});
  await page.goto(base+'?page=battle&state=combat');await page.evaluate(()=>window.ready);
  await page.addStyleTag({content:'.slot{outline:1px dashed #8bcad1}.slot:after{content:attr(data-slot);position:absolute;top:0;right:0;background:#101c29;font:12px monospace}.route{outline:1px solid #e8d9bc}'});
  await page.screenshot({path:path.join(evidence,'geometry-overlay.png')});
  const phones=[{w:320,h:568,top:0,bottom:0},{w:360,h:640,top:0,bottom:0},{w:390,h:844,top:47,bottom:34},{w:430,h:932,top:44,bottom:34},{w:412,h:915,top:24,bottom:24}];
  const mobileBase=base.replace('ui.html','mobile.html');
  const phoneResults=[];
  for(const size of phones){
   await page.setViewportSize({width:size.w,height:size.h});
   await page.goto(mobileBase);await page.evaluate(()=>window.mobileReady);
   await page.addStyleTag({content:`:root{--safe-top:${size.top}px;--safe-bottom:${size.bottom}px}`});
   for(const locale of ['zh-Hans','zh-Hant','en','ko','ja','ru']){
    await page.locator('#language').click();
    await page.locator(`[data-locale="${locale}"]`).click();
    await page.locator('#apply-language').click();
    const result=await page.evaluate(({size,locale})=>{
     const rect=el=>{const b=el.getBoundingClientRect();return {x:b.x,y:b.y,w:b.width,h:b.height,text:el.textContent};};
     const targets=['language','start','quit'].map(id=>rect(document.getElementById(id)));
     const font=[...document.fonts].filter(f=>['EGNoto','EGNotoKR'].includes(f.family)).map(f=>f.status);
     const title=document.querySelector('h1');const lines={};
     for(let i=0;i<title.firstChild.length;i++){if(!title.textContent[i].trim())continue;const range=document.createRange();range.setStart(title.firstChild,i);range.setEnd(title.firstChild,i+1);const r=range.getBoundingClientRect();const key=Math.round(r.y);lines[key]=(lines[key]||'')+title.textContent[i];}
     return {locale,lang:document.documentElement.lang,size,targets,font,noHorizontalScroll:document.documentElement.scrollWidth===size.w,title:rect(title),titleLines:Object.values(lines),actionTop:document.querySelector('.menu-actions').getBoundingClientRect().top,credit:rect(document.querySelector('#credit'))};
    },{size,locale});
    const ok=result.lang===locale&&result.noHorizontalScroll&&result.font.every(x=>x==='loaded')&&result.targets.every(b=>b.w>=48&&b.h>=48&&b.x>=0&&b.x+b.w<=size.w+1&&b.y>=size.top&&b.y+b.h<=size.h-size.bottom+1)&&result.credit.y+result.credit.h<=size.h-size.bottom;
    check(`phone-${size.w}-${locale}`,ok,result);phoneResults.push(result);
    check(`phone-${size.w}-${locale}-title`,result.title.y+result.title.h<result.actionTop&&result.titleLines.every(line=>[...line].length>=2),{lines:result.titleLines,title:result.title,actionTop:result.actionTop});
    if(size.w===390)await page.screenshot({path:path.join(output,`previews/mobile-menu-${locale}.png`)});
   }
   await page.locator('#language').click();
   const before=await page.locator('#current-language').textContent();
   await page.locator('[data-locale="en"]').click();
   await page.locator('#close-language').click();
   check(`phone-${size.w}-cancel`,await page.locator('#current-language').textContent()===before,'Close discards draft selection');
   await page.locator('#language').click();
   const sheetInfo=await page.locator('#language-sheet').evaluate(el=>{const r=el.getBoundingClientRect();return {y:r.y,h:r.height,rows:[...el.querySelectorAll('[role=radio]')].map(e=>{const b=e.getBoundingClientRect();return {h:b.height,w:b.width,text:e.textContent};})};});
   check(`phone-${size.w}-sheet`,sheetInfo.y>=size.top&&sheetInfo.y+sheetInfo.h<=size.h+1&&sheetInfo.rows.length===6&&sheetInfo.rows.every(r=>r.h>=48),sheetInfo);
   await page.screenshot({path:path.join(output,`previews/language-${size.w}x${size.h}.png`)});
   await page.locator('[data-locale="zh-Hans"]').click();await page.locator('#apply-language').click();
   await page.screenshot({path:path.join(output,`previews/mobile-menu-${size.w}x${size.h}.png`)});
   await page.goto(mobileBase+'?view=battle');await page.evaluate(()=>window.mobileReady);
   await page.addStyleTag({content:`:root{--safe-top:${size.top}px;--safe-bottom:${size.bottom}px}`});
   const frame=page.frames().find(f=>f.url().includes('ui.html'));await frame.evaluate(()=>window.ready);
   await page.waitForFunction(()=>document.querySelector('#map-clip').style.transform.includes('scale'));
   const battleInfo=await page.evaluate(()=>({buttons:[...document.querySelectorAll('.mobile-buttons button')].map(el=>({w:el.getBoundingClientRect().width,h:el.getBoundingClientRect().height,overflow:el.scrollHeight>el.clientHeight||el.scrollWidth>el.clientWidth})),scroll:document.documentElement.scrollWidth,view:innerWidth}));
   check(`phone-${size.w}-battle-controls`,battleInfo.scroll===battleInfo.view&&battleInfo.buttons.every(b=>b.w>=48&&b.h>=48&&!b.overflow),battleInfo);
   await page.screenshot({path:path.join(output,`previews/mobile-battle-${size.w}x${size.h}.png`)});
   for(const locale of ['zh-Hans','zh-Hant','en','ko','ja','ru']){
    await page.locator('#language').click();await page.locator(`[data-locale="${locale}"]`).click();await page.locator('#apply-language').click();
    const data=await page.locator('#mobile-actions').evaluate(el=>{const content=el.querySelector('#mobile-feedback').getBoundingClientRect();return {bottom:content.bottom,containerBottom:el.getBoundingClientRect().bottom,text:el.innerText,buttons:[...el.querySelectorAll('button')].map(b=>({w:b.clientWidth,h:b.clientHeight,sw:b.scrollWidth,sh:b.scrollHeight}))};});
    check(`phone-${size.w}-battle-${locale}`,data.bottom<=size.h-size.bottom+1&&data.buttons.every(b=>b.w>=48&&b.h>=48&&b.sw<=b.w&&b.sh<=b.h),data);
    if(size.w===390)await page.screenshot({path:path.join(output,`previews/mobile-battle-${locale}.png`)});
   }
   await page.locator('#language').click();await page.locator('[data-locale="zh-Hans"]').click();await page.locator('#apply-language').click();
  }
  fs.writeFileSync(path.join(evidence,'phone-matrix.json'),JSON.stringify(phoneResults,null,2));
  await page.goto(mobileBase);await page.evaluate(()=>window.mobileReady);check('language-persistence',await page.locator('#current-language').textContent()==='简体中文','Applied language survives reload');
 }finally{if(browser)await browser.close();server.close();}
 const counts=Object.fromEntries(['PASS','FAIL'].map(k=>[k,checks.filter(c=>c.status===k).length]));
 fs.writeFileSync(path.join(evidence,'layout-audit.json'),JSON.stringify({counts,checks},null,2));
 console.log(JSON.stringify(counts));
 if(counts.FAIL)process.exitCode=1;
})().catch(err=>{console.error(err);server.close();process.exitCode=1;});
