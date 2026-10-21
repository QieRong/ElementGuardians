/* Static art layouts only. GameSession, economy and combat are not implemented here. */
const ASSETS = '../../../game_asserts/';
const assetPaths = {menu:'09_背景场景/主菜单_竖屏裁剪.png',battle:'09_背景场景/战斗场景_竖屏裁剪.png',fire:'01_角色守卫/火焰守卫.png',ice:'01_角色守卫/冰霜守卫.png',lightning:'01_角色守卫/雷霆守卫.png',grunt:'02_敌人怪物/窥视蛛机.png'};
const params = new URLSearchParams(location.search);
const page = params.get('page') || 'menu';
const state = params.get('state') || 'combat';
const canvas = document.querySelector('#canvas');
const svg = (body, cls='', view='0 0 32 32') => `<svg class="${cls}" viewBox="${view}" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">${body}</svg>`;
const icons = {
 start:svg('<path d="M9 4 27 16 9 28Z" fill="currentColor"/><path d="M3 5v22" stroke="currentColor" stroke-width="2"/>','button-icon'),
 close:svg('<path d="m8 8 16 16M24 8 8 24" stroke="currentColor" stroke-width="2"/>','button-icon'),
 lock:svg('<path d="M10 13V9a6 6 0 0 1 12 0v4M7 13h18v16H7z" stroke="currentColor" stroke-width="2"/><circle cx="16" cy="20" r="2" fill="currentColor"/>'),
 coin:svg('<path d="m16 2 12 7v14l-12 7L4 23V9Z" stroke="currentColor" stroke-width="2"/><circle cx="16" cy="16" r="6" stroke="currentColor" stroke-width="2"/>'),
 heart:svg('<path d="M16 28 4 16C-3 7 9-1 16 8 23-1 35 7 28 16Z" fill="currentColor"/>'),
 wave:svg('<path d="m4 27 8-22 6 13 5-9 5 18Z" stroke="currentColor" stroke-width="2"/>'),
 summon:svg('<path d="m16 2 13 14-13 14L3 16Z" stroke="currentColor" stroke-width="2"/><path d="M9 16h14M16 9v14" stroke="currentColor" stroke-width="2"/>'),
 fire:svg('<path d="M16 1c5 12 15 15 10 25-6 9-23 3-20-8 1-4 5-6 5-12 2 5 4 7 5 8 3-3 2-7 0-13Z" fill="#e58a4d"/>'),
 ice:svg('<path d="m16 1 13 15-13 15L3 16Z" fill="#8bcad1"/><path d="M16 4v24M5 16h22" stroke="#1c2b38" stroke-width="2"/>'),
 lightning:svg('<path d="M18 1 3 19h11l-2 12L29 12H18l3-11Z" fill="#d8d45d"/>')
};
const img = (id, cls='') => `<img class="${cls}" src="${ASSETS+assetPaths[id]}" alt="">`;
const btn = (text,cls,icon='',disabled=false)=>`<button type="button" class="paper-btn ${cls}" ${disabled?'disabled':''} data-static="true">${icon}<span class="button-text" data-fit>${text}</span></button>`;
const proof = '<div class="proof">视觉稿 v01 · 非运行截图</div>';
function guard(type,level=1){return `<div class="guard-window ${type}">${img(type)}</div><span class="element-shape">${icons[type]}</span><span class="level" data-fit>Lv${level}</span>`;}
const samples = {
 combat:{gold:0,phase:'战斗中',occupants:{3:['lightning',1],4:['ice',1],5:['fire',1]},feedback:'战斗中不可召唤或合成',locked:true},
 initial:{gold:60,feedback:'请先选择空格',occupants:{}},
 selected:{gold:60,selected:4,feedback:'已选择4号格 · 召唤花费20金币',occupants:{},canSummon:true},
 poor:{gold:19,selected:4,feedback:'金币不足，召唤需要20金币',occupants:{}},
 merge:{gold:0,selected:1,target:2,feedback:'已选源格1，点击同类同级目标完成合成',occupants:{1:['fire',1],2:['fire',1]}},
 merged:{gold:0,feedback:'合成成功：目标守卫升至Lv2',occupants:{2:['fire',2]}},
 type:{gold:0,selected:1,feedback:'不同类型不可合成',occupants:{1:['fire',1],2:['ice',1]}},
 level:{gold:0,selected:1,feedback:'不同等级不可合成',occupants:{1:['fire',1],2:['fire',2]}},
 max:{gold:0,selected:1,feedback:'已到满级',occupants:{1:['fire',3],2:['fire',3]}},
 occupied:{gold:60,selected:4,feedback:'格子已有守卫，请选择空格',occupants:{4:['ice',1]}},
 full:{gold:60,feedback:'棋盘已满，合成可腾出空格',occupants:Object.fromEntries(Array.from({length:9},(_,i)=>[i,[['fire','ice','lightning'][i%3],1]]))}
};
function menu(){
 canvas.innerHTML=`<div class="layer">${img('menu','background')}<div class="layer menu-backdrop"></div></div>
 ${svg('<path d="M72 0v96M0 48h144" stroke="#e8d9bc" stroke-width="2"/><circle cx="72" cy="48" r="36" fill="#101c29" stroke="#e8d9bc" stroke-width="3"/><circle cx="72" cy="48" r="26" stroke="#a34431" stroke-width="9"/><path d="m72 18 10 30-10 30-10-30Z" fill="#e8d9bc"/><circle cx="72" cy="48" r="5" fill="#101c29"/>','pos crest','0 0 144 96')}
 <a class="lang-link" href="mobile.html?language=1">◎ 简体中文</a><div class="title-panel"></div><h1 class="pos text menu-title" data-fit>元素守卫</h1><p class="pos text subtitle" data-fit>ELEMENT GUARDIANS</p>
 ${btn('开始游戏','start primary',icons.start)}${btn('退出游戏','exit',icons.close)}<p class="pos text menu-caption" data-fit>单机原型 · AI 协作制作</p>${proof}`;
}
async function battle(){
 const map=await fetch('map.snapshot.json').then(r=>r.json());
 window.mapData=map;
 const s=samples[state]||samples.combat;
 window.sampleData=s;
 const points=map.path.map(p=>p.join(',')).join(' ');
 const arrows=[[350,190,0],[640,330,90],[350,440,180],[80,630,90],[350,810,0],[640,900,90]].map(([x,y,r])=>`<path d="m-7-7 8 7-8 7" transform="translate(${x} ${y}) rotate(${r})" stroke="#1c2b38" stroke-width="3"/>`).join('');
 const route=svg(`<polyline points="${points}" stroke="#101c29" stroke-width="48" stroke-linejoin="bevel"/><polyline data-route="true" points="${points}" stroke="#cbbca2" stroke-width="40" stroke-linejoin="bevel"/><polyline points="${points}" stroke="#e8d9bc" stroke-width="2" stroke-dasharray="2 12"/>${arrows}<circle cx="80" cy="190" r="21" fill="#a34431" stroke="#e8d9bc" stroke-width="3"/><path d="m73 180 14 10-14 10Z" fill="#e8d9bc"/><path d="m640 942 38 38-38 38-38-38Z" fill="#101c29" stroke="#e8d9bc" stroke-width="3"/><path d="m640 955 20 25-20 25-20-25Z" fill="#a34431"/><circle cx="640" cy="980" r="8" fill="#e8d9bc"/>`,'route','0 0 720 1280');
 const board=map.slots.map(slot=>{const unit=s.occupants[slot.index];return `<div class="slot ${s.selected===slot.index?'selected':''} ${s.target===slot.index?'target':''}" data-slot="${slot.index}" style="left:${slot.center[0]-slot.size/2}px;top:${slot.center[1]-slot.size/2}px">${unit?guard(...unit):`<span class="slot-number">${slot.index}</span>`}</div>`;}).join('');
 const hud=[['波次',icons.wave,'1 <em>/ 6</em>',24,200],['基地',icons.heart,'10 <em>/ 10</em>',236,224],['金币',icons.coin,String(s.gold),472,224]].map(([name,icon,val,left,width])=>`<div class="stat" style="left:${left}px;width:${width}px"><div class="stat-name">${icon}${name}</div><div class="stat-value" data-fit>${val}</div></div>`).join('');
 const enemies=s.locked?[[216,190],[382,190],[548,190]].map(([x,y])=>`<div class="enemy" style="left:${x-30}px;top:${y-30}px">${img('grunt')}<div class="enemy-health"></div></div>`).join(''):'';
 canvas.innerHTML=`<div class="layer">${img('battle','background battle-background')}</div><div class="field-paper"></div><div class="field-grain"></div>${route}${board}${enemies}
 <div class="hud">${hud}</div><div class="pos phase" data-fit>${s.phase||'准备中'}</div><div class="pos map-label entry-label" data-fit>敌人入口</div><div class="pos map-label base-label" data-fit>守卫基地</div>
 <div class="actions">${btn('召唤 -20','action summon '+(s.canSummon?'primary':''),s.canSummon?icons.summon:icons.lock,!s.canSummon)}${btn('取消选择','action cancel','',s.locked||s.selected===undefined)}${s.locked?'<div class="readonly" data-fit>本波进行中</div>':btn('开始第 1 波','action wave primary')}
 <div class="feedback" data-fit>${s.locked?icons.lock:icons.summon}<span>${s.feedback}</span></div></div>${proof}`;
}
function inspection(){
 canvas.className='inspection';
 const thumbs=['fire','ice','lightning'].flatMap(type=>['dark','light'].map(tone=>`<div class="thumb-sample ${tone}"><span class="label">${{fire:'火焰',ice:'冰霜',lightning:'雷霆'}[type]}守卫 · ${tone==='dark'?'深':'浅'}底</span><div class="slot">${guard(type)}</div><span class="sample-note">76 × 76<br>主体中心窗口</span></div>`)).join('');
 canvas.innerHTML=`<header>格内缩略与控件检查 · 静态视觉样例<br>元素形状 + 等级；完整名称在操作提示表达</header><div class="sheet">${thumbs}</div><header>主按钮状态 · 图形 + 文字提示</header>${[['正常','primary',false],['焦点','primary focused',false],['按下','primary pressed',false],['禁用 · 战斗中','',true]].map(([name,cls,disabled])=>`<div class="swatch-row">${btn(disabled?'召唤 -20':'开始游戏',cls,disabled?icons.lock:icons.start,disabled)}<span class="state-name">${name}</span></div>`).join('')}<header>金币字宽 · 完整显示，无截断</header><div class="money-samples">${[0,19,60,799].map(n=>`<span data-fit>金币 ${n}</span>`).join('')}</div>`;
}
window.ready=(async()=>{if(page==='menu')menu();else if(page==='inspect')inspection();else await battle();await document.fonts.ready;await Promise.all([...document.images].map(im=>im.decode()));})();
