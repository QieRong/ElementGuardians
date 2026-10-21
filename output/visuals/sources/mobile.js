/* Interactive design sample; no gameplay or platform integration. */
const locales = [
 {id:'zh-Hans',native:'简体中文',title:'元素守卫',start:'开始游戏',quit:'退出游戏',credit:'单机原型 · AI 协作制作',apply:'应用',wave:'波次',base:'基地',gold:'金币',summon:'召唤 −20',cancel:'取消选择',begin:'开始第 1 波',preview:'这是界面预览',poor:'金币不足，召唤需要20金币'},
 {id:'zh-Hant',native:'繁體中文',title:'元素守衛',start:'開始遊戲',quit:'離開遊戲',credit:'單機原型 · AI 協作製作',apply:'套用',wave:'波次',base:'基地',gold:'金幣',summon:'召喚 −20',cancel:'取消選擇',begin:'開始第 1 波',preview:'這是介面預覽',poor:'金幣不足，召喚需要20金幣'},
 {id:'en',native:'English',title:'Element Guardians',start:'Start game',quit:'Exit game',credit:'Single-player prototype · Made with AI assistance',apply:'Apply',wave:'Wave',base:'Base',gold:'Gold',summon:'Summon −20',cancel:'Deselect',begin:'Start wave 1',preview:'Interface preview',poor:'Not enough gold. Summoning costs 20.'},
 {id:'ko',native:'한국어',title:'엘리먼트 가디언즈',start:'게임 시작',quit:'게임 종료',credit:'싱글 플레이 프로토타입 · AI 제작 지원',apply:'적용',wave:'웨이브',base:'기지',gold:'골드',summon:'소환 −20',cancel:'선택 취소',begin:'1 웨이브 시작',preview:'화면 미리보기',poor:'골드가 부족합니다. 소환 비용은 20입니다.'},
 {id:'ja',native:'日本語',title:'エレメント\nガーディアンズ',start:'ゲーム開始',quit:'ゲーム終了',credit:'シングルプレイ試作版 · AI制作支援',apply:'適用',wave:'ウェーブ',base:'拠点',gold:'ゴールド',summon:'召喚 −20',cancel:'選択解除',begin:'第1ウェーブ開始',preview:'画面プレビュー',poor:'ゴールド不足です。召喚には20必要です。'},
 {id:'ru',native:'Русский',title:'Стражи стихий',start:'Начать игру',quit:'Выйти из игры',credit:'Однопользовательский прототип · С помощью ИИ',apply:'Применить',wave:'Волна',base:'База',gold:'Золото',summon:'Призыв −20',cancel:'Снять выбор',begin:'Начать волну 1',preview:'Предпросмотр интерфейса',poor:'Недостаточно золота. Призыв стоит 20.'}
];
const byId=id=>document.getElementById(id);
const query=new URLSearchParams(location.search);
const isBattle=query.get('view')==='battle';
const poorSample=isBattle&&query.get('sample')==='poor';
const sheet=byId('language-sheet');
const toast=byId('feedback-toast');
let toastTimer;
let clearToastTimer;
let current='zh-Hans';
try{current=localStorage.getItem('eg-art-locale')||current;}catch{/* Preview works with storage blocked. */}
if(!locales.some(l=>l.id===current))current='zh-Hans';
let draft=current;
function dismissToast(){
 clearTimeout(toastTimer);clearTimeout(clearToastTimer);
 toast.classList.remove('visible');
 clearToastTimer=setTimeout(()=>{toast.firstElementChild.textContent='';},160);
}
function showToast(message){
 clearTimeout(toastTimer);clearTimeout(clearToastTimer);
 toast.firstElementChild.textContent=message;
 toast.classList.add('visible');
 const duration=Math.min(4500,Math.max(2000,[...message].length*70));
 toastTimer=setTimeout(dismissToast,duration);
}
function paint(){
 const l=locales.find(l=>l.id===current);document.documentElement.lang=l.id;
 if(!isBattle){
  byId('current-language').textContent=l.native;byId('game-title').textContent=l.title;
  byId('start').textContent=l.start;byId('quit').textContent=l.quit;byId('credit').textContent=l.credit;
  byId('apply-language').textContent=l.apply;
 }
 byId('mobile-hud').innerHTML=[[l.wave,'1 / 6'],[l.base,'10 / 10'],[l.gold,poorSample?'19':'60']].map(([name,val])=>`<div><span>${name}</span><strong>${val}</strong></div>`).join('');
 byId('mobile-actions').innerHTML=`<div class="mobile-buttons"><button disabled>${l.summon}</button><button disabled>${l.cancel}</button><button id="begin-preview" class="primary">${l.begin}</button></div>`;
 // The preview button must not pretend that a real wave started.
 byId('begin-preview').onclick=()=>showToast(l.preview);
}
function choices(){
 byId('language-options').innerHTML=locales.map(l=>`<button class="language-option" role="radio" aria-checked="${l.id===draft}" lang="${l.id}" data-locale="${l.id}"><span>${l.native}</span><span class="radio-mark" aria-hidden="true">${l.id===draft?'✓':''}</span></button>`).join('');
}
function openLanguage(){
 if(isBattle)return;
 dismissToast();draft=current;choices();sheet.showModal();byId('close-language').focus();
}
if(!isBattle){
 byId('language').onclick=openLanguage;
 byId('start').onclick=()=>{location.href='mobile.html?view=battle';};
 byId('language-options').onclick=e=>{const option=e.target.closest('[data-locale]');if(!option)return;draft=option.dataset.locale;choices();document.querySelector(`[data-locale="${draft}"]`).focus();};
 byId('language-options').onkeydown=e=>{if(!['ArrowDown','ArrowUp'].includes(e.key))return;e.preventDefault();const index=locales.findIndex(l=>l.id===draft);draft=locales[(index+(e.key==='ArrowDown'?1:5))%6].id;choices();document.querySelector(`[data-locale="${draft}"]`).focus();};
 byId('close-language').onclick=()=>sheet.close();
 sheet.onclick=e=>{if(e.target!==sheet)return;const b=sheet.getBoundingClientRect();if(e.clientY<b.top||e.clientX<b.left||e.clientX>b.right)sheet.close();};
 byId('apply-language').onclick=()=>{
  current=draft;try{localStorage.setItem('eg-art-locale',current);}catch{/* Keep the in-page choice. */}
  paint();sheet.close();
 };
 sheet.onclose=()=>byId('language').focus();
}else{
 byId('menu-header').remove();sheet.remove();
 byId('app').className='phone-battle';byId('battle-ui').hidden=false;
 if(poorSample)document.querySelector('iframe').src='ui.html?page=battle&state=poor';
 const container=byId('map-viewport');
 new ResizeObserver(()=>{const s=Math.min(container.clientWidth/720,container.clientHeight/960);byId('map-clip').style.transform=`scale(${s})`;}).observe(container);
}
paint();
window.mobileReady=document.fonts.ready;
if(!isBattle&&query.get('language')==='1')openLanguage();
// Independent visual scenario, not a transaction or a continuous game.
if(poorSample&&query.get('notice')==='1')window.mobileReady.then(()=>showToast(locales.find(l=>l.id===current).poor));
window.addEventListener('pagehide',dismissToast);
