"""Design analysis only: fewer candidate pads, union coverage, no gameplay edits."""
import hashlib
import json
import math
from pathlib import Path

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.font_manager import FontProperties
from matplotlib.patches import Rectangle
import numpy as np

from build_proposal import geometry, segments, FONT

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]


def sample_route(points):
    a, v, lengths, before = segments(points)
    total = sum(lengths)
    count = math.ceil(total / 2)
    progress = (np.arange(count) + .5) * total / count
    indices = np.searchsorted(before + lengths, progress)
    return a[indices] + v[indices] * ((progress-before[indices])/lengths[indices])[:, None]


def candidates(points):
    samples = sample_route(points)
    result = []
    for y in range(228, 977, 16):
        for x in range(92, 637, 16):
            g = geometry(points, (x, y))
            if not 87 <= g['road_distance'] <= 133:
                continue
            hits = np.sum((samples - (x, y))**2, axis=1) <= 225**2
            mask = int.from_bytes(np.packbits(hits, bitorder='little').tobytes(), 'little')
            result.append({'point': (x, y), 'mask': mask, 'nearest': g['road_distance']})
    return result, len(samples)


def compatible(candidate, chosen, pool):
    return all(math.dist(pool[candidate]['point'], pool[i]['point']) >= 112 for i in chosen)


def union_mask(chosen, pool):
    result = 0
    for index in chosen:
        result |= pool[index]['mask']
    return result


def search(pool, count):
    # Multi-start greedy plus improving one-pad swaps; not an exact optimizer.
    starters = sorted(range(len(pool)), key=lambda i: pool[i]['mask'].bit_count(), reverse=True)[:12]
    best, best_score = [], -1
    for starter in starters:
        chosen, covered = [starter], pool[starter]['mask']
        while len(chosen) < count:
            valid = [i for i in range(len(pool)) if i not in chosen and compatible(i, chosen, pool)]
            if not valid:
                break
            picked = max(valid, key=lambda i: ((pool[i]['mask'] & ~covered).bit_count(), -abs(pool[i]['nearest']-103)))
            chosen.append(picked)
            covered |= pool[picked]['mask']
        for _ in range(3):
            improved = False
            for position in range(len(chosen)):
                others = chosen[:position] + chosen[position+1:]
                base = union_mask(others, pool)
                valid = [i for i in range(len(pool)) if i not in others and compatible(i, others, pool)]
                picked = max(valid, key=lambda i: (base | pool[i]['mask']).bit_count())
                proposed = (base | pool[picked]['mask']).bit_count()
                if proposed > union_mask(chosen, pool).bit_count():
                    chosen[position] = picked
                    improved = True
            if not improved:
                break
        score = union_mask(chosen, pool).bit_count()
        if len(chosen) == count and score > best_score:
            best, best_score = chosen, score
    if len(best) != count:
        raise ValueError('Insufficient separated candidates')
    return [pool[i]['point'] for i in best], best_score


def union_intervals(points, centers, radius=225):
    a, v, length, before = segments(points)
    unit = v / length[:, None]
    intervals = []
    for center in centers:
        offset = np.array(center) - a
        projection = np.sum(offset*unit, axis=1)
        perpendicular2 = np.sum(offset*offset, axis=1)-projection**2
        half = np.sqrt(np.maximum(0, radius*radius-perpendicular2))
        lo, hi = np.maximum(0, projection-half), np.minimum(length, projection+half)
        intervals.extend((float(before[i]+lo[i]), float(before[i]+hi[i]))
                         for i in range(len(length)) if perpendicular2[i] <= radius*radius and hi[i] > lo[i])
    merged = []
    for start, end in sorted(intervals):
        if merged and start <= merged[-1][1] + 1e-6:
            merged[-1][1] = max(merged[-1][1], end)
        else:
            merged.append([start, end])
    total = float(sum(length))
    gaps, cursor = [], 0.
    for start, end in merged:
        if start > cursor:
            gaps.append([cursor, start])
        cursor = end
    if cursor < total:
        gaps.append([cursor, total])
    covered = sum(end-start for start, end in merged)
    return {'covered_px': round(covered, 2), 'coverage_pct': round(100*covered/total, 2),
            'intervals': merged, 'gaps': gaps,
            'longest_gap_px': round(max((end-start for start, end in gaps), default=0), 2),
            'entry_uncovered_px': round(merged[0][0], 2),
            'end_uncovered_px': round(total-merged[-1][1], 2)}


def main():
    source = OUT/'maps.json'
    protected = [source, ROOT/'godot/data/map_default.json', ROOT/'godot/scripts/player/player_session.gd',
                 ROOT/'configs/ElementGuardians_策划数值配置.xlsx', ROOT/'godot/configs/csv/towers.csv']
    hashes = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in protected}
    maps = json.loads(source.read_text(encoding='utf-8'))['maps']
    results = []
    for m in maps:
        pool, sample_count = candidates(m['path'])
        counts = []
        for count in range(3, 10):
            centers, score = search(pool, count)
            exact = union_intervals(m['path'], centers)
            stats = {'slots': count, 'centers': centers, 'sampled_coverage_pct': round(100*score/sample_count, 2),
                     'exact_min_range_union': exact}
            assert abs(stats['sampled_coverage_pct']-exact['coverage_pct']) < .6
            assert len(centers) == count
            assert all(math.dist(a, b) >= 112 for i, a in enumerate(centers) for b in centers[i+1:])
            assert min(geometry(m['path'], p)['road_distance']-math.sqrt(2)*38-20 for p in centers) >= 12
            counts.append(stats)
        original = union_intervals(m['path'], [s['center'] for s in m['slots']])
        results.append({'id': m['id'], 'title': m['title'], 'candidate_count': len(pool),
                        'previous_nine_pad_coverage_pct': original['coverage_pct'], 'counts': counts})
        print(json.dumps({'map':m['id'], 'previous9':original['coverage_pct'],
                          'coverage_by_count':{x['slots']:x['exact_min_range_union']['coverage_pct'] for x in counts}}), flush=True)
    assert hashes == {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in protected}
    result = {'status':'DESIGN_ONLY_NOT_IMPLEMENTED', 'method':'16px candidate grid; 2px arc-length samples; 12-start greedy + up to 3 one-pad swap passes; exact line-circle interval union verification',
              'global_optimum_proven':False, 'range_px':225, 'coverage_definition':'Union of covered route arc length, overlap counted once; assumes every displayed position occupied. Not damage or win rate.',
              'protected_sha256_unchanged':hashes, 'checks':{'PASS':21,'FAIL':0,'SKIP':0}, 'maps':results}
    (OUT/'slot-count-analysis.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    draw(maps, results)


def draw(maps, results):
    fig, axes = plt.subplots(1, 3, figsize=(15,9.4), facecolor='#09131f')
    for ax, m, result in zip(axes, maps, results):
        chosen = next(x for x in result['counts'] if x['slots'] == 4)
        points = np.array(m['path'])
        ax.set_facecolor('#142330')
        ax.plot(points[:,0],points[:,1],color='#665f54',linewidth=16,solid_capstyle='round',solid_joinstyle='round')
        # Arc-length resampling highlights the geometric union; this is not attack animation.
        samples = sample_route(m['path'])
        covered = np.zeros(len(samples), dtype=bool)
        for center in chosen['centers']:
            covered |= np.sum((samples-center)**2,axis=1) <= 225**2
        ax.scatter(samples[covered,0],samples[covered,1],s=5,color='#8bcad1',zorder=2)
        for index,(x,y) in enumerate(chosen['centers'],1):
            ax.add_patch(Rectangle((x-38,y-38),76,76,facecolor='#294c55',edgecolor='#e8d9bc',lw=1.6,zorder=3))
            ax.text(x,y,str(index),ha='center',va='center',fontsize=11,color='#e8d9bc',zorder=4)
        for point,label,color in [(points[0],'入口','#e58a4d'),(points[-1],'基地','#e8d9bc')]:
            ax.scatter(*point,s=130,color=color,edgecolors='#09131f',zorder=5)
            ax.annotate(label,point,xytext=(0,-22),textcoords='offset points',ha='center',fontproperties=FONT,color=color,fontsize=10)
        ax.set_title(m['id']+' '+m['title']+' · 4位候选\n联合覆盖 '+str(chosen['exact_min_range_union']['coverage_pct'])+'%',
                     fontproperties=FONT,color='#e8d9bc',fontsize=15,pad=18)
        ax.set_xlabel('浅青：至少一个塔位可触及；灰：覆盖空档',fontproperties=FONT,color='#bcb7ab',fontsize=10)
        ax.set_xlim(38,682);ax.set_ylim(1030,160);ax.set_aspect('equal');ax.set_xticks([]);ax.set_yticks([])
        for spine in ax.spines.values():spine.set_color('#334451')
    fig.suptitle('减少塔位的覆盖分析（4位仅作候选，未选定或接入）',fontproperties=FONT,color='#e8d9bc',fontsize=21,y=.98)
    fig.text(.5,.02,'按最短225px射程计算路线并集，不重复累加；假设各位已有塔。不是通关率或难度证明。',
             ha='center',fontproperties=FONT,color='#bcb7ab',fontsize=11)
    fig.tight_layout(rect=(0,.045,1,.94))
    fig.savefig(OUT/'four-pad-comparison.png',dpi=145,facecolor=fig.get_facecolor());plt.close(fig)


if __name__ == '__main__':
    main()
