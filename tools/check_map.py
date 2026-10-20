#!/usr/bin/env python3
"""校验 D006 地图几何与射程覆盖，并生成 720x1280 预览图。

真值：godot/data/map_default.json（路径、入口、基地、9 格中心）
数值：configs/csv/towers.csv（射程、颜色）
用法：
  python tools/check_map.py
  python tools/check_map.py --preview docs/maps/D006-map-A.png --report logs/test_runs/map_coverage.log
"""
from __future__ import annotations

import argparse
import csv
import json
import math
import sys
from collections import OrderedDict
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAP_PATH = ROOT / "godot" / "data" / "map_default.json"
TOWERS_PATH = ROOT / "configs" / "csv" / "towers.csv"

FONT_CANDIDATES = [
    r"C:\Windows\Fonts\msyh.ttc",
    r"C:\Windows\Fonts\msyhbd.ttc",
    r"C:\Windows\Fonts\simhei.ttf",
]

BG = (11, 20, 30)
PANEL = (18, 31, 45)
GRID = (48, 70, 92)
PAPER = (232, 226, 210)
MUTED = (148, 163, 184)
GOLD = (245, 190, 90)


def load_map() -> dict:
    return json.loads(MAP_PATH.read_text(encoding="utf-8"))


def load_towers() -> "OrderedDict[str, dict]":
    with TOWERS_PATH.open(encoding="utf-8", newline="") as fh:
        rows = list(csv.DictReader(fh))
    return OrderedDict((row["tower_id"], row) for row in rows)


def seg_distance(px: float, py: float, ax: float, ay: float, bx: float, by: float) -> float:
    vx, vy = bx - ax, by - ay
    wx, wy = px - ax, py - ay
    length2 = vx * vx + vy * vy
    if length2 <= 0:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, (wx * vx + wy * vy) / length2))
    return math.hypot(px - (ax + t * vx), py - (ay + t * vy))


def path_samples(points, step=2.0):
    samples = []
    for (ax, ay), (bx, by) in zip(points, points[1:]):
        length = math.hypot(bx - ax, by - ay)
        n = max(1, int(length / step))
        for i in range(n):
            t = i / n
            samples.append((ax + (bx - ax) * t, ay + (by - ay) * t))
    samples.append(tuple(points[-1]))
    return samples


def build_report(map_data, towers):
    points = [tuple(p) for p in map_data["path"]]
    slots = map_data["slots"]
    samples = path_samples(points)
    total = 0.0
    for (ax, ay), (bx, by) in zip(points, points[1:]):
        total += math.hypot(bx - ax, by - ay)

    problems = []
    for a, b in combinations(slots, 2):
        half_sum = (a.get("size", map_data["slot_size"]) + b.get("size", map_data["slot_size"])) / 2.0
        if abs(a["center"][0] - b["center"][0]) < half_sum and abs(a["center"][1] - b["center"][1]) < half_sum:
            problems.append(f"slot {a['index']} 与 slot {b['index']} 重叠")
    slot_rows = []
    for slot in slots:
        half = slot.get("size", map_data["slot_size"]) / 2.0
        cx, cy = slot["center"]
        min_path_dist = min(seg_distance(cx, cy, *a, *b) for a, b in zip(points, points[1:]))
        if min_path_dist < half + 4:
            problems.append(f"slot {slot['index']} 与路径距离 {min_path_dist:.1f}px，小于半格 {half:.0f}+4")
        ranges = [float(t["range_px"]) for t in towers.values()]
        cover_range = min(ranges)
        covered = sum(1 for x, y in samples if math.hypot(x - cx, y - cy) <= cover_range)
        pct = 100.0 * covered / len(samples)
        slot_rows.append({
            "index": slot["index"], "center": (cx, cy),
            "nearest": min_path_dist, "coverage": pct, "range": cover_range,
        })
        if covered == 0:
            problems.append(f"slot {slot['index']} 采用最保守射程 {cover_range:.0f}px 仍完全无法攻击路径")

    fixed = map_data.get("fixed_towers", [])
    if len(fixed) != 3:
        problems.append(f"固定塔数量应为 3，实际 {len(fixed)}")
    if len({item["slot"] for item in fixed}) != len(fixed):
        problems.append("固定塔占用了重复格子")
    fixed_rows = []
    union_covered = [False] * len(samples)
    for item in fixed:
        tower = towers.get(item["type_id"])
        if tower is None:
            problems.append(f"固定塔类型不存在: {item['type_id']}")
            continue
        slot = slots[item["slot"]]
        cx, cy = slot["center"]
        rng = float(tower["range_px"])
        covered = 0
        for idx, (x, y) in enumerate(samples):
            if math.hypot(x - cx, y - cy) <= rng:
                covered += 1
                union_covered[idx] = True
        fixed_rows.append({
            "type_id": item["type_id"], "slot": item["slot"], "center": (cx, cy),
            "range": rng, "coverage": 100.0 * covered / len(samples),
        })
    union_pct = 100.0 * sum(union_covered) / len(samples)
    return {
        "path_length": total, "samples": len(samples), "slots": slot_rows,
        "fixed": fixed_rows, "union": union_pct, "problems": problems,
    }


def font(size: int):
    from PIL import ImageFont
    for candidate in FONT_CANDIDATES:
        if Path(candidate).is_file():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default()


def draw_preview(map_data, towers, report, out_path: Path):
    from PIL import Image, ImageDraw
    img = Image.new("RGB", tuple(map_data["design_size"]), BG)
    d = ImageDraw.Draw(img, "RGBA")
    f_title, f_mid, f_small = font(30), font(20), font(15)

    # HUD / 底部信息区
    d.rectangle([0, 0, 720, 118], fill=PANEL)
    d.text((24, 20), f"元素守卫 · {map_data['map_id']}｜单 S 形路径", font=f_title, fill=PAPER)
    d.text((24, 64), f"720×1280 · 格宽 {map_data['slot_size']}px · 9 格部署区 · 诊断用固定塔", font=f_small, fill=MUTED)
    d.line([(0, 118), (720, 118)], fill=GRID, width=2)
    d.rectangle([0, 118, 720, 1080], outline=(28, 43, 58), width=0)
    d.rectangle([0, 1080, 720, 1280], fill=PANEL)

    # 固定塔射程
    for row in report["fixed"]:
        cx, cy = row["center"]
        rng = row["range"]
        rgb = towers[row["type_id"]]["color_hex"].lstrip("#")
        color = tuple(int(rgb[i:i + 2], 16) for i in (0, 2, 4))
        d.ellipse([cx - rng, cy - rng, cx + rng, cy + rng], outline=color + (110,), width=3)
        d.ellipse([cx - rng - 1, cy - rng - 1, cx + rng + 1, cy + rng + 1], outline=color + (32,), width=1)

    # 路径：外发光 + 主路 + 中心线 + 方向箭头
    pts = [tuple(p) for p in map_data["path"]]
    d.line(pts, fill=(60, 48, 38), width=54, joint="curve")
    d.line(pts, fill=(196, 154, 92), width=40, joint="curve")
    d.line(pts, fill=(230, 201, 148), width=6, joint="curve")
    for a, b in zip(pts, pts[1:]):
        ax, ay = a
        bx, by = b
        dist = math.hypot(bx - ax, by - ay)
        for frac in (0.35, 0.7):
            x, y = ax + (bx - ax) * frac, ay + (by - ay) * frac
            ux, uy = (bx - ax) / dist, (by - ay) / dist
            nx, ny = -uy, ux
            tip = (x + ux * 14, y + uy * 14)
            left = (x - ux * 8 + nx * 8, y - uy * 8 + ny * 8)
            right = (x - ux * 8 - nx * 8, y - uy * 8 - ny * 8)
            d.polygon([tip, left, right], fill=(92, 62, 32))

    # 9 格部署区
    for slot in map_data["slots"]:
        cx, cy = slot["center"]
        half = slot.get("size", map_data["slot_size"]) / 2
        d.rounded_rectangle([cx - half, cy - half, cx + half, cy + half], radius=10,
                            fill=(30, 41, 54, 235), outline=(109, 133, 158), width=3)
        d.text((cx - 8, cy - 28), str(slot["index"]), font=f_small, fill=(150, 170, 190))
        row = next(r for r in report["slots"] if r["index"] == slot["index"])
        d.text((cx - half + 6, cy + half - 22), f"{row['coverage']:.0f}%", font=f_small, fill=(190, 200, 210))

    # 固定塔
    for item in map_data["fixed_towers"]:
        slot = map_data["slots"][item["slot"]]
        cx, cy = slot["center"]
        tower = towers[item["type_id"]]
        rgb = tower["color_hex"].lstrip("#")
        color = tuple(int(rgb[i:i + 2], 16) for i in (0, 2, 4))
        d.ellipse([cx - 26, cy - 26, cx + 26, cy + 26], fill=color + (235,), outline=(250, 245, 230), width=3)
        letter = {"fire": "F", "ice": "I", "lightning": "L"}[item["type_id"]]
        d.text((cx - 7, cy - 14), letter, font=f_mid, fill=(15, 20, 26))

    # 入口 / 基地
    ex, ey = map_data["entry"]["x"], map_data["entry"]["y"]
    bx, by = map_data["base"]["x"], map_data["base"]["y"]
    d.ellipse([ex - 22, ey - 22, ex + 22, ey + 22], fill=(120, 220, 170), outline=(240, 255, 245), width=3)
    d.text((ex - 26, ey - 52), "出怪口", font=f_small, fill=(150, 230, 190))
    d.ellipse([bx - 26, by - 26, bx + 26, by + 26], fill=(220, 80, 80), outline=(255, 230, 225), width=3)
    d.text((bx - 40, by - 62), "基地 / 终点", font=f_small, fill=(255, 170, 160))

    # 底部图例
    d.text((24, 1104), f"路径长度 {report['path_length']:.0f}px   ·   3 塔联合覆盖 {report['union']:.1f}% 路径", font=f_mid, fill=PAPER)
    names = {"fire": "火", "ice": "冰", "lightning": "雷"}
    line = "固定塔：" + " / ".join(
        f"{names[item['type_id']]}Lv{item.get('level', 1)}({item['slot']}号格)"
        for item in map_data["fixed_towers"]
    )
    d.text((24, 1140), line, font=f_small, fill=MUTED)
    warn = "格子之间无重叠、避开路径；9 格全部可攻击到路径" if not report["problems"] else "存在问题：" + "；".join(report["problems"])
    d.text((24, 1170), warn, font=f_small, fill=(255, 170, 120) if report["problems"] else (150, 230, 190))
    d.text((24, 1200), "Sprint 1 诊断夹具；正式玩家模式开局仍为 0 塔 / 60 金币。", font=f_small, fill=MUTED)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--preview", default="docs/maps/D006-map-A.png")
    parser.add_argument("--report", default="logs/test_runs/map_coverage.log")
    args = parser.parse_args()

    map_data = load_map()
    towers = load_towers()
    report = build_report(map_data, towers)

    lines = ["MAP CHECK: " + ("FAIL" if report["problems"] else "PASS"),
             f"map={map_data['map_id']} path_length={report['path_length']:.1f}px samples={report['samples']}",
             "slot,center,nearest_px,coverage_pct(range_px)"]
    for row in report["slots"]:
        lines.append(f"{row['index']},{row['center'][0]}x{row['center'][1]},{row['nearest']:.1f},{row['coverage']:.1f}%({row['range']:.0f})")
    lines.append("fixed towers:")
    for row in report["fixed"]:
        lines.append(f"  {row['type_id']} slot={row['slot']} range={row['range']:.0f} coverage={row['coverage']:.1f}%")
    lines.append(f"union coverage={report['union']:.1f}%")
    for problem in report["problems"]:
        lines.append("PROBLEM: " + problem)
    text = "\n".join(lines)
    print(text)
    report_path = ROOT / args.report
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(text + "\n", encoding="utf-8")
    if args.preview:
        try:
            draw_preview(map_data, towers, report, ROOT / args.preview)
            print("PREVIEW: " + args.preview)
        except Exception as exc:  # 预览失败不掩盖几何校验结论
            print(f"PREVIEW: SKIP {exc}", file=sys.stderr)
            return 1
    return 1 if report["problems"] else 0


if __name__ == "__main__":
    sys.exit(main())
