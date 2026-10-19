#!/usr/bin/env python3
"""XLSX → CSV 单向同步器（stdlib, read-only XLSX)。

仅从源表工作表读取「无公式、静态值」；读图表/试算时不会导出。
Python 3.10+，无需 openpyxl、pandas、Godot 插件。
"""
from __future__ import annotations
import argparse
import csv
import io
import re
import sys
import tempfile
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
BOOK=ROOT/"configs"/"ElementGuardians_策划数值配置.xlsx"
OUT=ROOT/"configs"/"csv"
RUNTIME_OUT=ROOT/"godot"/"configs"/"csv"
SHEET_TO_CSV={"防御塔":"towers", "敌人":"enemies", "波次":"waves", "强化":"upgrades", "经济参数":"economy_params", "全局参数":"global_params"}
NS={"m":"http://schemas.openxmlformats.org/spreadsheetml/2006/main", "r":"http://schemas.openxmlformats.org/officeDocument/2006/relationships"}
PKG_REL="http://schemas.openxmlformats.org/package/2006/relationships"


def parse_sheet(zipf, path, shared):
    root=ET.fromstring(zipf.read(path))
    matrix=[]
    for row in root.findall(".//m:sheetData/m:row",NS):
        vals={}
        for cell in row.findall("m:c",NS):
            address=cell.get("r","")
            match=re.match(r"([A-Z]+)",address)
            if not match:
                continue
            col=0
            for ch in match.group(1): col=col*26+ord(ch)-64
            typ=cell.get("t")
            formula=cell.find("m:f",NS)
            if formula is not None:
                raise ValueError(f"data sheet contains formula: {path} {address}")
            v=cell.find("m:v",NS)
            if typ=="inlineStr":
                value="".join(n.text or "" for n in cell.findall(".//m:is//m:t",NS))
            elif typ=="s" and v is not None:
                value=shared[int(v.text)]
            elif v is not None and v.text is not None:
                value=v.text
                if typ not in ("str","e","b"):
                    try:
                        n=float(value)
                        value=str(int(n)) if n.is_integer() else format(n,".14g")
                    except ValueError:
                        pass
            else:
                value=""
            vals[col]=str(value)
        if vals:
            matrix.append([vals.get(i,"") for i in range(1,max(vals)+1)])
    return matrix


def read_book():
    if not BOOK.exists():
        raise FileNotFoundError(f"missing source workbook: {BOOK}")
    with zipfile.ZipFile(BOOK,"r") as z:
        ss=[]
        if "xl/sharedStrings.xml" in z.namelist():
            sr=ET.fromstring(z.read("xl/sharedStrings.xml"))
            for si in sr.findall("m:si",NS):
                ss.append("".join(t.text or "" for t in si.findall(".//m:t",NS)))
        wb=ET.fromstring(z.read("xl/workbook.xml"))
        rels=ET.fromstring(z.read("xl/_rels/workbook.xml.rels"))
        links={e.attrib["Id"]:e.attrib["Target"] for e in rels.findall(f"{{{PKG_REL}}}Relationship")}
        result={}
        for sheet in wb.findall("m:sheets/m:sheet",NS):
            name=sheet.get("name")
            if name not in SHEET_TO_CSV:
                continue
            target=links[sheet.attrib[f"{{{NS['r']}}}id"]]
            target=target.lstrip("/") if target.startswith("/") else "xl/"+target
            target=target.replace("xl/xl/","xl/")
            data=parse_sheet(z,target,ss)
            if not data:
                raise ValueError(f"empty worksheet {name}")
            result[SHEET_TO_CSV[name]]=data
        missing=set(SHEET_TO_CSV.values())-set(result)
        if missing:
            raise ValueError(f"missing worksheets for CSV: {sorted(missing)}")
    return result


def rows_to_csv(rows):
    out=io.StringIO(newline="")
    writer=csv.writer(out,lineterminator="\n")
    writer.writerows(rows)
    return out.getvalue()


def main():
    p=argparse.ArgumentParser(description="Synchronize Excel master data to Godot CSV")
    p.add_argument("--check",action="store_true",help="fail if CSV differs from XLSX; do not write")
    args=p.parse_args()
    data=read_book()
    csv_map={key:rows_to_csv(rows) for key,rows in data.items()}
    if args.check:
        drift=[]
        for key,txt in csv_map.items():
            for destination in (OUT, RUNTIME_OUT):
                path=destination/(key+".csv")
                if not path.exists() or path.read_text(encoding="utf-8-sig")!=txt:
                    drift.append(str(path.relative_to(ROOT)))
        if drift:
            print("CSV SYNC: FAIL | drift="+", ".join(drift),file=sys.stderr)
            return 1
        print("CSV SYNC: PASS | 6 tables match Excel master in both config directories")
        return 0
    # Validate planned exports BEFORE replacing existing CSVs.
    from validate_config import validate,ConfigError
    OUT.mkdir(parents=True,exist_ok=True)
    RUNTIME_OUT.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        staging=Path(tmp)
        for key,txt in csv_map.items():
            (staging/(key+".csv")).write_text(txt,encoding="utf-8")
        # Relocate validation config root only during precheck.
        import validate_config
        old=validate_config.CFG
        validate_config.CFG=staging
        try:
            validate()
        finally:
            validate_config.CFG=old
        for path in staging.iterdir():
            for destination in (OUT, RUNTIME_OUT):
                (destination/path.name).write_bytes(path.read_bytes())
    print("CSV SYNC: PASS | 6 sheets exported to both CSV destinations, cross-table validation PASS")
    return 0

if __name__=="__main__":
    try: sys.exit(main())
    except (OSError,ValueError,KeyError,zipfile.BadZipFile) as e:
        print(f"CSV SYNC: FAIL | {e}",file=sys.stderr)
        sys.exit(1)
