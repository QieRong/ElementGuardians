"""Design-only geometry/interaction proposal. Does not write production data."""
import csv
import hashlib
import html
import json
import math
from pathlib import Path

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.font_manager import FontProperties
from matplotlib.patches import Circle, Rectangle
import numpy as np

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
FONT = FontProperties(fname='C:/Windows/Fonts/msyh.ttc')


def bezier(start, control1, control2, end, count=42):
    return [[(1-t)**3*start[k] + 3*(1-t)**2*t*control1[k] +
             3*(1-t)*t*t*control2[k] + t**3*end[k] for k in (0, 1)]
            for t in np.linspace(0, 1, count)]


def smooth_polyline(points, radius=44):
    result = [points[0]]
    for index in range(1, len(points)-1):
        previous, corner, following = map(np.array, points[index-1:index+2])
        a = corner + (previous-corner) / np.linalg.norm(previous-corner) * radius
        b = corner + (following-corner) / np.linalg.norm(following-corner) * radius
        result.append(a.tolist())
        result.extend([((1-t)**2*a + 2*(1-t)*t*corner + t*t*b).tolist()
                       for t in np.linspace(0, 1, 16)[1:]])
    result.append(points[-1])
    return result


def segments(points):
    a = np.array(points[:-1], dtype=float)
    v = np.diff(np.array(points, dtype=float), axis=0)
    length = np.linalg.norm(v, axis=1)
    valid = length > .0001
    a, v, length = a[valid], v[valid], length[valid]
    return a, v, length, np.r_[0, np.cumsum(length)[:-1]]


def geometry(points, center, radius=225):
    a, v, length, before = segments(points)
    unit = v / length[:, None]
    offset = np.array(center) - a
    projection = np.sum(offset*unit, axis=1)
    nearest = np.clip(projection, 0, length)
    distance = np.linalg.norm(offset - nearest[:, None]*unit, axis=1)
    closest = int(np.argmin(distance))
    perpendicular2 = np.sum(offset*offset, axis=1) - projection**2
    half = np.sqrt(np.maximum(0, radius*radius-perpendicular2))
    lo, hi = np.maximum(0, projection-half), np.minimum(length, projection+half)
    covered = np.where(perpendicular2 <= radius*radius, np.maximum(0, hi-lo), 0)
    used = np.flatnonzero(covered > .00001)
    return {'road_distance': float(min(distance)),
            'nearest_progress': float(before[closest]+nearest[closest]),
            'covered_path': float(sum(covered)),
            'first_contact': float(before[used[0]]+lo[used[0]]) if len(used) else None,
            'path_length': float(sum(length))}


def choose_slots(points):
    candidates = []
    for y in range(228, 977, 16):
        for x in range(92, 637, 16):
            g = geometry(points, (x, y))
            # Conservative square-to-road clearance: use the square's circumradius.
            if 87 <= g['road_distance'] <= 133:
                candidates.append(((x, y), g))
    chosen = []
    total = geometry(points, (360, 600))['path_length']
    for fraction in (.035, .135, .245, .355, .465, .575, .685, .795, .91):
        valid = [(p, g) for p, g in candidates
                 if all(math.dist(p, old) >= 112 for old in chosen)]
        if not valid:
            raise ValueError('Not enough separated construction sites')
        point, _ = min(valid, key=lambda item:
                       abs(item[1]['nearest_progress']-fraction*total)
                       + .8*abs(item[1]['road_distance']-103))
        chosen.append(point)
    return sorted(chosen, key=lambda p: geometry(points, p)['nearest_progress'])


def main():
    original = ROOT / 'godot/data/map_default.json'
    towers_path = ROOT / 'godot/configs/csv/towers.csv'
    protected = [original, towers_path, ROOT/'godot/scripts/player/player_session.gd',
                 ROOT/'configs/ElementGuardians_策划数值配置.xlsx']
    before = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
              for p in protected}
    old = json.loads(original.read_text(encoding='utf-8'))
    towers = list(csv.DictReader(towers_path.open(encoding='utf-8')))
    old_length = geometry(old['path'], (360, 620))['path_length']
    path_a = (bezier((80, 220), (180, 170), (540, 175), (600, 300)) +
              bezier((600, 300), (660, 440), (450, 515), (250, 470))[1:] +
              bezier((250, 470), (90, 440), (85, 650), (245, 700))[1:] +
              bezier((245, 700), (420, 760), (600, 690), (600, 900))[1:] +
              bezier((600, 900), (600, 1020), (160, 1020), (120, 900))[1:] + [[120, 850]])
    path_b = smooth_polyline([(90, 215), (610, 390), (140, 570),
                             (590, 750), (160, 950), (620, 950)], 42)
    path_c = smooth_polyline([(100, 260), (600, 260), (600, 820), (100, 820),
                             (100, 460), (430, 460), (430, 650), (270, 650)], 50)
    definitions = [('A', '双湾弧道', '连续弧湾，多次经过防区', path_a),
                   ('B', '斜岭折返', '斜向折返，分段接力防守', path_b),
                   ('C', '环庭内旋', '外圈推进后进入内侧，内外分工', path_c)]
    maps, checks = [], []
    for map_id, title, purpose, points in definitions:
        slots = choose_slots(points)
        length = geometry(points, slots[0])['path_length']
        stats = []
        for index, p in enumerate(slots):
            coverage = {tower['tower_id']: round(geometry(points, p, float(tower['range_px']))['covered_path'], 1)
                        for tower in towers}
            stats.append({'index': index+1, 'center': list(p), 'coverage_px': coverage,
                          'min_road_distance_px': round(geometry(points, p)['road_distance'], 1)})
        min_gap = min(math.dist(a, b) for i, a in enumerate(slots) for b in slots[i+1:])
        # Validate the complete 76px square, not just its center.
        min_square_clearance = min(geometry(points, p)['road_distance']-math.sqrt(2)*38-20 for p in slots)
        valid = (len(slots) == 9 and min_gap >= 112 and min_square_clearance >= 12 and
                 all(all(value > 0 for value in s['coverage_px'].values()) for s in stats) and
                 all(76 <= x <= 644 and 204 <= y <= 986 for x, y in slots))
        checks.append({'map_id': map_id, 'status': 'PASS' if valid else 'FAIL',
                       'scope': 'Geometry only; no combat or difficulty acceptance',
                       'slots': len(slots), 'min_center_gap_px': round(min_gap, 1),
                       'conservative_square_to_road_clearance_px': round(min_square_clearance, 1)})
        maps.append({'id': map_id, 'title': title, 'purpose': purpose, 'path': points,
                     'path_length_px': round(length, 1),
                     'change_vs_original_pct': round(100*(length/old_length-1), 1),
                     'slot_size': 76, 'slots': stats})
    after = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in protected}
    assert before == after
    data = {'status': 'PROPOSAL_ONLY_NOT_IMPLEMENTED', 'original_length_px': old_length,
            'ranges_px': {t['tower_id']: float(t['range_px']) for t in towers},
            'maps': maps, 'protected_source_hashes_unchanged': before,
            'checks': checks, 'full_game_difficulty': 'NOT_TESTED'}
    (OUT/'maps.json').write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    draw(maps)
    write_html(maps)
    print(json.dumps({'maps': [{k:m[k] for k in ('id','path_length_px','change_vs_original_pct')} for m in maps],
                      'geometry': checks, 'protected_sources_unchanged': True}, ensure_ascii=False))


def draw(maps):
    fig, axes = plt.subplots(1, 3, figsize=(15, 9.4), facecolor='#09131f')
    for ax, m in zip(axes, maps):
        ax.set_facecolor('#142330')
        points = np.array(m['path'])
        ax.plot(points[:, 0], points[:, 1], color='#c4b69b', linewidth=16,
                solid_capstyle='round', solid_joinstyle='round', zorder=1)
        for start, end in zip(points[::max(1, len(points)//9)], points[max(1, len(points)//9)::max(1, len(points)//9)]):
            vector = end-start
            if np.linalg.norm(vector) > 0:
                unit = vector/np.linalg.norm(vector)
                mid = (start+end)/2
                ax.annotate('', xy=mid+unit*15, xytext=mid-unit*15,
                            arrowprops={'arrowstyle':'->','color':'#142330','lw':1.8})
        for s in m['slots']:
            x, y = s['center']
            ax.add_patch(Rectangle((x-38,y-38),76,76,facecolor='#294c55',edgecolor='#8bcad1',lw=1.6,zorder=3))
            ax.text(x,y,str(s['index']),ha='center',va='center',color='#e8d9bc',fontsize=11,zorder=4)
        for point, label, color in [(points[0], '入口', '#e58a4d'), (points[-1], '基地', '#e8d9bc')]:
            ax.scatter(*point,s=150,color=color,edgecolors='#09131f',zorder=5)
            ax.annotate(label,point,xytext=(0,-22),textcoords='offset points',ha='center',
                        fontproperties=FONT,color=color,fontsize=10,zorder=6)
        ax.set_title(m['id']+'  '+m['title']+'\n'+m['purpose'],fontproperties=FONT,color='#e8d9bc',fontsize=15,pad=18)
        ax.set_xlabel(f"路线 {m['path_length_px']:.0f}px / 较原图 {m['change_vs_original_pct']:+.1f}%",
                      fontproperties=FONT,color='#b7b1a6',fontsize=11)
        ax.set_xlim(38,682); ax.set_ylim(1030,160); ax.set_aspect('equal')
        ax.set_xticks([]); ax.set_yticks([])
        for spine in ax.spines.values(): spine.set_color('#334451')
    fig.suptitle('沿路九塔位 · 三地图几何提案（未接入游戏）',fontproperties=FONT,color='#e8d9bc',fontsize=22,y=.98)
    fig.text(.5,.02,'数字仅供审阅定位；几何检查不等于难度或真人验收。原地图继续保留。',
             ha='center',fontproperties=FONT,color='#b7b1a6',fontsize=12)
    fig.tight_layout(rect=(0,.045,1,.94))
    fig.savefig(OUT/'three-map-proposal.png',dpi=145,facecolor=fig.get_facecolor())
    plt.close(fig)


def write_html(maps):
    cards = []
    for m in maps:
        pts = ' '.join(f'{x:.1f},{y:.1f}' for x,y in m['path'])
        slots = ''.join(f'<g class="slot" tabindex="0" role="button" aria-label="查看塔位{s["index"]}射程" data-x="{s["center"][0]}" data-y="{s["center"][1]}"><rect x="{s["center"][0]-38}" y="{s["center"][1]-38}" width="76" height="76"/><text x="{s["center"][0]}" y="{s["center"][1]+9}">{s["index"]}</text></g>' for s in m['slots'])
        entry, base = m['path'][0], m['path'][-1]
        cards.append(f'<section class="map"><h2>{m["id"]} · {m["title"]}</h2><p>{m["purpose"]}</p><svg viewBox="0 120 720 960" aria-label="{m["title"]}地图提案"><polyline class="road" points="{pts}"/><circle class="range" r="225" visibility="hidden"/><circle class="outer" r="235" visibility="hidden"/>{slots}<circle cx="{entry[0]}" cy="{entry[1]}" r="18" fill="#e58a4d"/><circle cx="{base[0]}" cy="{base[1]}" r="23" fill="#e8d9bc"/></svg><p>路线 {m["path_length_px"]:.0f}px · 较原图 {m["change_vs_original_pct"]:+.1f}%</p><div class="info">点一个塔位，查看随机召唤前的射程预览。</div><div class="nearby" hidden><b>随机召唤 · 20 金币</b><p>火：单体伤害 · 230px<br>冰：减速 · 235px<br>雷：连锁 · 225px</p><small>设计示意，不能自选类型；不会扣款或生成守卫。</small></div></section>')
    document = '''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>元素守卫｜布阵体验提案</title><style>
    *{box-sizing:border-box}body{margin:0;background:#09131f;color:#e8d9bc;font-family:"Microsoft YaHei",sans-serif;line-height:1.7}main{max-width:1400px;margin:auto;padding:28px}h1{font-size:30px;margin-bottom:4px}.badge{color:#e58a4d}.flow{padding:20px;background:#142330;border:1px solid #53616b;margin:24px 0}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:20px}.map{position:relative;background:#142330;border:1px solid #53616b;padding:16px;overflow:hidden}.map h2{margin:0;font-size:23px}.map p{margin:5px 0 12px;color:#bcb7ab}svg{width:100%;display:block;background:#10202b}.road{fill:none;stroke:#c4b69b;stroke-width:40;stroke-linecap:round;stroke-linejoin:round}.slot{cursor:pointer}.slot rect{fill:#294c55;stroke:#8bcad1;stroke-width:3}.slot text{font-size:26px;fill:#e8d9bc;text-anchor:middle;pointer-events:none}.slot:hover rect,.slot:focus rect,.slot.selected rect{fill:#a34431;stroke:#e8d9bc;stroke-width:5}.range{fill:#8bcad116;stroke:#8bcad1;stroke-width:3;pointer-events:none}.outer{fill:none;stroke:#e8d9bc;stroke-width:2;stroke-dasharray:8;pointer-events:none}.nearby{position:absolute;width:min(310px,88%);background:#101c29;border:1px solid #d3c3a2;box-shadow:0 6px 20px #0008;padding:14px;z-index:5;pointer-events:none}.nearby b{display:block;background:#a34431;padding:8px}.nearby p{font-size:14px;color:#e8d9bc}.nearby small{font-size:12px;color:#bcb7ab}.info{min-height:58px;font-size:14px}.notes{margin-top:28px;padding:20px;border:1px solid #53616b}.notes li{margin-bottom:8px}@media(max-width:900px){.grid{grid-template-columns:1fr}.map{max-width:560px;width:100%;margin:auto}main{padding:16px}}
    </style><main><div class="badge">方案预览 · 未接入 Godot · 点击地图只查看射程</div><h1>点位附近完成召唤，让道路决定布防</h1><p>保留随机4/3/3、召唤20、初始60金币/10HP、同类同级合成最高Lv3。每局一图，同局六波不换路。</p><div class="flow"><b>空位 → 射程预览＋就近操作面板 → 随机召唤20 → 实际守卫与精确射程</b><br>类型说明不承担购买操作；点空白处关闭，无消耗。下面数字仅供审阅，正式游戏不显示调试格号。</div><div class="grid">CARDS</div><div class="notes"><h2>其他交互约定</h2><ul><li>面板锚定所选空位上方，临近屏幕边缘时换到下方或侧面；不得遮住目标或越出可视区。</li><li>空位的实线圈为最小225px，虚线圈为最大235px；随机结果出来后仅显示该守卫真实射程。</li><li>底部移除召唤按钮，保留低频的开波与阶段信息；金币不足在面板内解释。</li><li>点已有守卫查看类型、等级、射程和可合成目标；源消失、目标保留升级要有预览。无出售、退款或直接搬塔。</li><li>教程只放在设置→玩法教程，主动进入、可返回；不在首波自动弹出，不自动开波。</li><li>教程先做目标/召唤/合成/战斗图文与标明“演示”的短动画，不改真实对局金币或随机流。</li><li>每局按独立地图seed选图并记录map_id，同局六波固定。随机选图允许不同局重复；不暗加防重复规则。</li><li>地图仍是提案。路线长度、各塔位覆盖、入口和基地均改变，须审阅后再接入；六波、Boss和难度未实测。</li></ul></div></main><script>
    for(const card of document.querySelectorAll('.map')){const svg=card.querySelector('svg'),popup=card.querySelector('.nearby');function close(){popup.hidden=true;for(const c of svg.querySelectorAll('circle.range,circle.outer'))c.setAttribute('visibility','hidden');for(const s of svg.querySelectorAll('.slot'))s.classList.remove('selected')}function show(slot){close();slot.classList.add('selected');const x=Number(slot.dataset.x),y=Number(slot.dataset.y);for(const c of svg.querySelectorAll('circle.range,circle.outer')){c.setAttribute('cx',x);c.setAttribute('cy',y);c.setAttribute('visibility','visible')}popup.hidden=false;const box=slot.getBoundingClientRect(),bounds=card.getBoundingClientRect(),height=popup.offsetHeight,width=popup.offsetWidth;let left=box.left-bounds.left+box.width/2-width/2;left=Math.max(8,Math.min(left,bounds.width-width-8));let top=box.top-bounds.top-height-12;if(top<70)top=box.bottom-bounds.top+12;top=Math.min(top,bounds.height-height-12);popup.style.left=left+'px';popup.style.top=top+'px';card.querySelector('.info').textContent='当前塔位：'+slot.getAttribute('aria-label').replace('查看塔位','').replace('射程','')+'；实线225px，虚线235px。'}for(const slot of svg.querySelectorAll('.slot')){slot.addEventListener('click',e=>{e.stopPropagation();show(slot)});slot.addEventListener('keydown',e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();show(slot)}})}card.addEventListener('click',e=>{if(!e.target.closest('.slot'))close()});card.addEventListener('keydown',e=>{if(e.key==='Escape')close()})}
    </script></html>'''
    (OUT/'preview.html').write_text(document.replace('CARDS',''.join(cards)),encoding='utf-8')


if __name__ == '__main__':
    main()
