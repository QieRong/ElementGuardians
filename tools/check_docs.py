#!/usr/bin/env python3
"""文档一致性检查：路径引用、测试 ID、MANIFEST 哈希、文档编号。"""
from __future__ import annotations
import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
SEARCH_ROOTS = [ROOT, DOCS, ROOT / "configs", ROOT / "configs" / "csv", ROOT / "tracking",
                ROOT / "tools", ROOT / "game_asserts" / "10_说明文件"]

TICK = chr(96)
PATH_RE = re.compile("[" + TICK + "]([^" + TICK + r"\n]+)[" + TICK + "]")
PATH_PREFIX = ("docs/", "configs/", "tracking/", "tools/", "prompts/", "godot/", "game_asserts/")
PATH_EXT = (".md", ".csv", ".py", ".json", ".txt", ".tscn", ".gd", ".xlsx", ".png")
SKIP_MARKS = ("YYYY", "<", ">", "*", "…", "|", "http", " ", "{", "}", "sha256")
# 尚未生成、但被文档明确写为“导出物”的文件，不算断链
ALLOW_MISSING = {"README-PLAY.md", "ElementGuardians.exe"}

TEST_RE = re.compile(r"\b((?:CFG|SES|ECO|BRD|MRG|WAV|ENM|UP|RES|UI|PERF|RNG|ATK|AST|DOC)-\d{2})\b")
DOCNUM_RE = re.compile(r"^(\d{2})-[\w.-]+\.md$")


def doc_files():
    return sorted(DOCS.glob("*.md"))


def check_links(files):
    missing = []
    for path in files:
        text = path.read_text(encoding="utf-8")
        for token in PATH_RE.findall(text):
            token = token.strip()
            if any(mark in token for mark in SKIP_MARKS):
                continue
            if token.startswith("logs/"):
                continue
            if token.endswith("/"):
                continue  # 目录占位（如 godot/assets/），不要求已存在
            if token in ALLOW_MISSING:
                continue
            looks_path = token.startswith(PATH_PREFIX) or token.endswith(PATH_EXT)
            if not looks_path:
                continue
            if "/" not in token and not token.endswith(PATH_EXT):
                continue
            candidates = [ROOT / token] + [base / token for base in SEARCH_ROOTS[1:]]
            if not any(candidate.exists() for candidate in candidates):
                missing.append(f"{path.relative_to(ROOT)} -> {token}")
    return missing


def check_tests(files):
    defined = set()
    text08 = (DOCS / "08-TEST-PLAN.md").read_text(encoding="utf-8")
    for line in text08.splitlines():
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) >= 2 and TEST_RE.fullmatch(cells[0]):
            defined.add(cells[0])
    referenced = {}
    for path in files:
        for test_id in TEST_RE.findall(path.read_text(encoding="utf-8")):
            referenced.setdefault(test_id, set()).add(path.name)
    undefined = sorted({tid for tid in referenced if tid not in defined})
    return defined, undefined, referenced


def check_manifest():
    manifest = ROOT / "MANIFEST.sha256"
    if not manifest.is_file():
        return ["MANIFEST.sha256 不存在"]
    problems = []
    listed = 0
    for line in manifest.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        parts = line.split(None, 1)
        if len(parts) != 2:
            problems.append(f"MANIFEST 行格式错误: {line}")
            continue
        digest, rel = parts[0], parts[1].strip()
        target = ROOT / rel
        if not target.is_file():
            problems.append(f"MANIFEST 文件缺失: {rel}")
            continue
        actual = hashlib.sha256(target.read_bytes()).hexdigest()
        if actual != digest:
            problems.append(f"MANIFEST 哈希不符: {rel}")
        listed += 1
    return problems + ([f"MANIFEST 仅列出 {listed} 个文件"] if listed == 0 else [])


def check_doc_numbers(files):
    numbers = {}
    problems = []
    for path in files:
        match = DOCNUM_RE.match(path.name)
        if not match:
            problems.append(f"文档命名不符合 NN-NAME.md: {path.name}")
            continue
        number = match.group(1)
        if number in numbers:
            problems.append(f"文档编号重复 {number}: {numbers[number]} 与 {path.name}")
        numbers[number] = path.name
    return problems, numbers


def main():
    files = doc_files()
    missing_links = check_links(files)
    defined, undefined, referenced = check_tests(files)
    manifest_problems = check_manifest()
    number_problems, numbers = check_doc_numbers(files)

    print(f"DOCS: {len(files)} files | tests defined={len(defined)} referenced={len(referenced)}")
    for problem in missing_links:
        print(f"DOC-LINK FAIL: {problem}", file=sys.stderr)
    for test_id in undefined:
        print(f"DOC-TEST FAIL: {test_id} referenced by {', '.join(sorted(referenced[test_id]))} but not defined in 08", file=sys.stderr)
    for problem in manifest_problems:
        print(f"DOC-MANIFEST FAIL: {problem}", file=sys.stderr)
    for problem in number_problems:
        print(f"DOC-NAME FAIL: {problem}", file=sys.stderr)

    failed = bool(missing_links or undefined or manifest_problems or number_problems)
    print("DOC CHECK: " + ("FAIL" if failed else f"PASS | {len(files)} docs, {len(defined)} test ids, manifest verified"))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
