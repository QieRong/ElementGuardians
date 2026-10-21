/* Current mobile preview QA/export. Keeps the v01 screenshots and reports intact. */
const fs = require('fs');
const path = require('path');
const http = require('http');
const { chromium } = require('playwright');
const root = path.resolve(__dirname, '../../..');
// Every run gets new evidence; never replace an earlier red/green report.
const runId = new Date().toISOString().replace(/[:.]/g, '-');
function directoryArg(name, fallback) {
 const value=process.argv.slice(2).find(arg=>arg.startsWith(`--${name}=`));
 return path.resolve(root,value?value.slice(name.length+3):fallback);
}
const evidence = directoryArg('evidence-dir', `logs/test_runs/mobile-${runId}`);
const output = directoryArg('output-dir', `output/visuals/revisions/mobile-${runId}`);
const mime = {'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.js':'text/javascript; charset=utf-8','.json':'application/json; charset=utf-8','.png':'image/png','.ttf':'font/ttf'};
const server = http.createServer((req,res)=>{
 if(new URL(req.url,'http://localhost').pathname==='/favicon.ico'){res.writeHead(204).end();return;}
 const file=path.resolve(root,'.'+decodeURIComponent(new URL(req.url,'http://localhost').pathname));
 if(!file.startsWith(root+path.sep)){res.writeHead(403).end();return;}
 fs.readFile(file,(err,data)=>{if(err){res.writeHead(404).end();return;}res.setHeader('Content-Type',mime[path.extname(file)]||'application/octet-stream');res.end(data);});
});
const checks=[];
const measurements=[];
function check(id,ok,detail){checks.push({id,status:ok?'PASS':'FAIL',detail});}
const phones=[{w:320,h:568,top:0,bottom:0},{w:360,h:640,top:0,bottom:0},{w:390,h:844,top:47,bottom:34},{w:430,h:932,top:44,bottom:34},{w:412,h:915,top:24,bottom:24}];
const locales=['zh-Hans','zh-Hant','en','ko','ja','ru'];
async function ready(page){
 await page.evaluate(()=>window.mobileReady);
 await page.locator('#app').waitFor();
 if(await page.locator('#battle-ui').isVisible()){
  const frame=page.frames().find(f=>f.url().includes('ui.html'));
  await frame.evaluate(()=>window.ready);
  await page.waitForFunction(()=>document.querySelector('#map-clip').style.transform.includes('scale'));
 }
}
async function safe(page,size){
 await page.addStyleTag({content:`:root{--safe-top:${size.top}px;--safe-bottom:${size.bottom}px}`});
}
(async()=>{
 for(const directory of [evidence,output]){
  if(fs.existsSync(directory)&&fs.readdirSync(directory).length)throw new Error(`Refusing to overwrite evidence: ${directory}`);
 }
 fs.mkdirSync(evidence,{recursive:true});fs.mkdirSync(output,{recursive:true});
 await new Promise(r=>server.listen(0,'127.0.0.1',r));
 const base=`http://127.0.0.1:${server.address().port}/output/visuals/sources/mobile.html`;
 let browser;
 try{
  browser=await chromium.launch({headless:true,channel:'chrome'});
  const context=await browser.newContext({viewport:{width:320,height:568},deviceScaleFactor:1});
  const page=await context.newPage();
  const errors=[];
  page.on('pageerror',e=>errors.push(String(e)));
  page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
  page.on('response',r=>{if(r.status()>=400&&!r.url().endsWith('favicon.ico'))errors.push(`${r.status()} ${r.url()}`);});
  for(const size of phones){
   await page.setViewportSize({width:size.w,height:size.h});
   for(const locale of locales){
    const prefix=`${size.w}-${locale}`;
    await page.goto(base);await ready(page);await safe(page,size);
    await page.locator('#language').click();
    await page.locator(`[data-locale="${locale}"]`).click();
    await page.locator('#apply-language').click();
    const menu=await page.evaluate(()=>({lang:document.documentElement.lang,dialogOpen:!!document.querySelector('dialog[open]'),languageButtons:document.querySelectorAll('#language').length,title:document.querySelector('h1').textContent}));
    check(prefix+'-menu-language',menu.lang===locale&&!menu.dialogOpen&&menu.languageButtons===1,menu);
    if(locale==='zh-Hans'&&size.w===320)await page.screenshot({path:path.join(output,'menu-320x568.png')});
    await page.locator('#start').click();await ready(page);await safe(page,size);
    const info=await page.evaluate(()=>{
     const rect=e=>{const r=e.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height,bottom:r.bottom};};
     const app=document.querySelector('#app');const map=document.querySelector('#map-clip');
     return {lang:document.documentElement.lang,languageButtons:document.querySelectorAll('#language').length,languageDialogs:document.querySelectorAll('#language-sheet').length,headers:document.querySelectorAll('#menu-header').length,oldHint:!!document.querySelector('#mobile-feedback'),scrollWidth:document.documentElement.scrollWidth,width:innerWidth,height:innerHeight,hud:rect(document.querySelector('#mobile-hud')),hudContent:rect(document.querySelector('#mobile-hud > div')),hudCells:[...document.querySelectorAll('#mobile-hud > div')].map(e=>({cell:rect(e),label:rect(e.querySelector('span')),value:rect(e.querySelector('strong'))})),actions:rect(document.querySelector('#mobile-actions')),buttons:[...document.querySelectorAll('.mobile-buttons button')].map(b=>({...rect(b),overflow:b.scrollHeight>b.clientHeight||b.scrollWidth>b.clientWidth})),app:rect(app),map:rect(map),slotWidth:76*map.getBoundingClientRect().width/720,toastVisible:document.querySelector('#feedback-toast').classList.contains('visible'),gold:document.querySelector('#mobile-hud').innerText};
    });
    measurements.push({size,locale,info});
    check(prefix+'-battle-language',info.lang===locale&&info.languageButtons===0&&info.languageDialogs===0&&info.headers===0,info);
    check(prefix+'-no-idle-prompt',!info.oldHint&&!info.toastVisible,info);
    check(prefix+'-controls-and-safe-area',info.scrollWidth===size.w&&info.hudContent.y>=size.top&&info.buttons.every(b=>b.w>=48&&b.h>=48&&!b.overflow&&b.bottom<=size.h-size.bottom)&&Math.abs(info.actions.bottom-size.h)<1,info);
    const bottomGap=size.h-size.bottom-Math.max(...info.buttons.map(b=>b.bottom));
    check(prefix+'-compact-bottom',bottomGap>=0&&bottomGap<=12,{bottomGap});
    const centers=info.hudCells.map(c=>c.cell.x+c.cell.w/2);
    check(prefix+'-hud-alignment',info.hudCells.length===3&&Math.abs((centers[1]-centers[0])-(centers[2]-centers[1]))<1&&info.hudCells.every(c=>Math.abs(c.label.x+c.label.w/2-(c.cell.x+c.cell.w/2))<1&&Math.abs(c.value.x+c.value.w/2-(c.cell.x+c.cell.w/2))<1&&Math.abs(c.label.y-info.hudCells[0].label.y)<1&&Math.abs(c.value.y-info.hudCells[0].value.y)<1),info.hudCells);
    if(locale==='zh-Hans')await page.screenshot({path:path.join(output,`battle-${size.w}x${size.h}.png`)});
    if(size.w===390)await page.screenshot({path:path.join(output,`battle-${locale}.png`)});
    await page.locator('#begin-preview').click();await page.evaluate(()=>document.fonts.ready);
    await page.waitForFunction(()=>getComputedStyle(document.querySelector('#feedback-toast')).opacity==='1');
    const toast=await page.evaluate(()=>{
     const e=document.querySelector('#feedback-toast'),r=e.getBoundingClientRect(),a=document.querySelector('#app').getBoundingClientRect();
     return {text:e.innerText,role:e.getAttribute('role'),live:e.getAttribute('aria-live'),pointer:getComputedStyle(e).pointerEvents,focus:document.activeElement.id,centerX:Math.abs(r.x+r.width/2-(a.x+a.width/2)),centerY:Math.abs(r.y+r.height/2-(a.y+a.height/2)),x:r.x,right:r.right,y:r.y,bottom:r.bottom,actionsY:document.querySelector('#mobile-actions').getBoundingClientRect().y};
    });
    check(prefix+'-toast',toast.text.length>0&&toast.role==='status'&&toast.live==='polite'&&toast.pointer==='none'&&toast.focus==='begin-preview'&&toast.centerX<1&&toast.centerY<1&&toast.x>=0&&toast.right<=size.w&&toast.y>=size.top&&toast.bottom<=size.h-size.bottom&&toast.actionsY===info.actions.y,toast);
    if(size.w===390)await page.screenshot({path:path.join(output,`toast-${locale}.png`)});
    // Discard this notice through navigation; the separate timing checks below wait for expiry.
   }
   await page.goto(base);await ready(page);await safe(page,size);
   const before=await page.locator('#current-language').textContent();
   await page.locator('#language').click();await page.locator('[data-locale="en"]').click();await page.locator('#close-language').click();
   check(`${size.w}-cancel-language`,await page.locator('#current-language').textContent()===before,before);
   await page.locator('#language').click();await page.locator('[data-locale="zh-Hans"]').click();await page.locator('#apply-language').click();
   await page.goto(base+'?view=battle&sample=poor');await ready(page);await safe(page,size);
   await page.evaluate(()=>document.fonts.ready);
   // The screenshot scenario includes no actual purchase or RNG operation.
   await page.goto(base+'?view=battle&sample=poor&notice=1');await ready(page);await safe(page,size);
   await page.waitForFunction(()=>getComputedStyle(document.querySelector('#feedback-toast')).opacity==='1');
   if(size.w===320||size.w===390)await page.screenshot({path:path.join(output,`poor-toast-${size.w}x${size.h}.png`)});
  }
  await page.setViewportSize({width:320,height:568});
  await page.goto(base+'?view=battle&language=1');await ready(page);
  check('battle-query-cannot-open-language',await page.locator('#language-sheet').count()===0,'No battle language dialog, including direct URL');
  await page.locator('#begin-preview').click();
  await page.waitForTimeout(800);await page.locator('#begin-preview').click();await page.waitForTimeout(1400);
  check('repeated-notice-restarts-timer',await page.locator('#feedback-toast').evaluate(e=>e.classList.contains('visible')),'Visible 1.4s after second click; no stale timer');
  await page.waitForFunction(()=>!document.querySelector('#feedback-toast').classList.contains('visible'));
  await page.waitForFunction(()=>!document.querySelector('#feedback-toast').textContent);
  check('notice-clears-after-timeout',true,'Notice fades and live region text clears');
  check('single-notice-no-stack',await page.locator('#feedback-toast').count()===1,'One transient status, no modal/backdrop');
  await page.emulateMedia({reducedMotion:'reduce'});await page.locator('#begin-preview').click();
  const motion=await page.locator('#feedback-toast').evaluate(e=>({duration:getComputedStyle(e).transitionDuration,opacity:getComputedStyle(e).opacity}));
  check('reduced-motion',motion.duration==='0s'&&motion.opacity==='1',motion);
  await page.waitForFunction(()=>!document.querySelector('#feedback-toast').classList.contains('visible'));
  check('reduced-motion-still-dismisses',true,'No animation; same finite notice lifetime');
  await page.goto(base);await ready(page);await page.locator('#language').click();
  await page.locator('[data-locale="ja"]').click();await page.locator('#apply-language').click();
  check('japanese-two-line-title',(await page.locator('#game-title').textContent())==='エレメント\nガーディアンズ','Preserved explicit line break');
  await page.locator('#language').click();await page.locator('[data-locale="zh-Hans"]').click();await page.locator('#apply-language').click();
  await page.goto(base+'?view=battle');await ready(page);
  check('formal-initial-preview',await page.locator('#mobile-hud').innerText().then(t=>t.includes('60')&&t.includes('10 / 10')),'0-tower image, 60 gold, 10 HP; visual fixture only');
  check('browser-errors',errors.length===0,errors);
  await context.close();
 }finally{if(browser)await browser.close();server.close();}
 const counts=Object.fromEntries(['PASS','FAIL'].map(k=>[k,checks.filter(c=>c.status===k).length]));
 const result={counts,checks,measurements,scope:'Design/browser checks only. No Godot, real gameplay, native device, performance, or native-language acceptance.',automation:'Existing bundled Playwright and Chrome; no project dependency added.'};
 const name=counts.FAIL?'browser-first-red.json':'browser-audit.json';
 fs.writeFileSync(path.join(evidence,name),JSON.stringify(result,null,2));
 console.log(JSON.stringify({counts,evidence,output}));if(counts.FAIL)process.exitCode=1;
})().catch(err=>{console.error(err);server.close();process.exitCode=1;});
