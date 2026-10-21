/* Interactive design sample; no gameplay or platform integration. */
const locales = [
 {id:'zh-Hans',native:'简体中文',title:'元素守卫',start:'开始游戏',quit:'退出游戏',credit:'单机原型 · AI 协作制作',apply:'应用',wave:'波次',base:'基地',gold:'金币',summon:'召唤 −20',cancel:'取消选择',begin:'开始第 1 波',hint:'请先选择空格'},
 {id:'zh-Hant',native:'繁體中文',title:'元素守衛',start:'開始遊戲',quit:'離開遊戲',credit:'單機原型 · AI 協作製作',apply:'套用',wave:'波次',base:'基地',gold:'金幣',summon:'召喚 −20',cancel:'取消選擇',begin:'開始第 1 波',hint:'請先選擇空格'},
 {id:'en',native:'English',title:'Element Guardians',start:'Start game',quit:'Exit game',credit:'Single-player prototype · Made with AI assistance',apply:'Apply',wave:'Wave',base:'Base',gold:'Gold',summon:'Summon −20',cancel:'Deselect',begin:'Start wave 1',hint:'Select an empty slot first'},
 {id:'ko',native:'한국어',title:'엘리먼트 가디언즈',start:'게임 시작',quit:'게임 종료',credit:'싱글 플레이 프로토타입 · AI 제작 지원',apply:'적용',wave:'웨이브',base:'기지',gold:'골드',summon:'소환 −20',cancel:'선택 취소',begin:'1 웨이브 시작',hint:'먼저 빈 칸을 선택하세요'},
 {id:'ja',native:'日本語',title:'エレメント\nガーディアンズ',start:'ゲーム開始',quit:'ゲーム終了',credit:'シングルプレイ試作版 · AI制作支援',apply:'適用',wave:'ウェーブ',base:'拠点',gold:'ゴールド',summon:'召喚 −20',cancel:'選択解除',begin:'第1ウェーブ開始',hint:'先に空きマスを選択してください'},
 {id:'ru',native:'Русский',title:'Стражи стихий',start:'Начать игру',quit:'Выйти из игры',credit:'Однопользовательский прототип · С помощью ИИ',apply:'Применить',wave:'Волна',base:'База',gold:'Золото',summon:'Призыв −20',cancel:'Снять выбор',begin:'Начать волну 1',hint:'Сначала выберите пустую ячейку'}
];
const byId=id=>document.getElementById(id);
const sheet=byId('language-sheet');
let current=localStorage.getItem('eg-art-locale')||'zh-Hans';
if(!locales.some(l=>l.id===current))current='zh-Hans';
let draft=current;
function paint(){
 const l=locales.find(l=>l.id===current);document.documentElement.lang=l.id;
 byId('current-language').textContent=l.native;byId('game-title').textContent=l.title;byId('start').textContent=l.start;byId('quit').textContent=l.quit;byId('credit').textContent=l.credit;
 byId('apply-language').textContent=l.apply;
 byId('mobile-hud').innerHTML=[[l.wave,'1 / 6'],[l.base,'10 / 10'],[l.gold,'60']].map(([name,val])=>`<div><span>${name}</span><strong>${val}</strong></div>`).join('');
 byId('mobile-actions').innerHTML=`<div class="mobile-buttons"><button disabled>${l.summon}</button><button disabled>${l.cancel}</button><button class="primary">${l.begin}</button></div><p id="mobile-feedback">${l.hint}</p>`;
}
function choices(){
 byId('language-options').innerHTML=locales.map(l=>`<button class="language-option" role="radio" aria-checked="${l.id===draft}" lang="${l.id}" data-locale="${l.id}"><span>${l.native}</span><span class="radio-mark" aria-hidden="true">${l.id===draft?'✓':''}</span></button>`).join('');
}
function openLanguage(){draft=current;choices();sheet.showModal();byId('close-language').focus();}
byId('language').onclick=openLanguage;
byId('language-options').onclick=e=>{const option=e.target.closest('[data-locale]');if(!option)return;draft=option.dataset.locale;choices();document.querySelector(`[data-locale="${draft}"]`).focus();};
byId('language-options').onkeydown=e=>{if(!['ArrowDown','ArrowUp'].includes(e.key))return;e.preventDefault();const index=locales.findIndex(l=>l.id===draft);draft=locales[(index+(e.key==='ArrowDown'?1:5))%6].id;choices();document.querySelector(`[data-locale="${draft}"]`).focus();};
byId('close-language').onclick=()=>sheet.close();
sheet.onclick=e=>{if(e.target!==sheet)return;const b=sheet.getBoundingClientRect();if(e.clientY<b.top||e.clientX<b.left||e.clientX>b.right)sheet.close();};
byId('apply-language').onclick=()=>{current=draft;localStorage.setItem('eg-art-locale',current);paint();sheet.close();};
sheet.onclose=()=>byId('language').focus();
paint();
const query=new URLSearchParams(location.search);
if(query.get('view')==='battle'){
 byId('app').className='phone-battle';byId('battle-ui').hidden=false;
 const container=byId('map-viewport');new ResizeObserver(()=>{const s=Math.min(container.clientWidth/720,container.clientHeight/960);byId('map-clip').style.transform=`scale(${s})`;}).observe(container);
}
window.mobileReady=document.fonts.ready;
if(query.get('language')==='1')openLanguage();
