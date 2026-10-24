from pathlib import Path
from copy import copy
import json, openpyxl
p=Path(__file__).resolve().parent
a=openpyxl.load_workbook(p/'source.xlsx');b=openpyxl.load_workbook(p.parents[2]/'configs/ElementGuardians_策划数值配置.xlsx')
values=[];styles=[]
for sheet in a.sheetnames:
 for row in a[sheet]:
  for cell in row:
   other=b[sheet][cell.coordinate]
   if cell.value != other.value: values.append([sheet,cell.coordinate,cell.value,other.value])
   if any(copy(getattr(cell,prop)) != copy(getattr(other,prop)) for prop in ['font','fill','border','alignment','number_format','protection']): styles.append([sheet,cell.coordinate])
report={'same_sheet_names':a.sheetnames==b.sheetnames,'original_value_formula_differences':values,'original_cell_style_differences':styles,'added_rows':list(b['经济参数'].values)[5:7], 'original_formula_count':sum(c.data_type=='f' for s in a for row in s for c in row),'final_formula_count':sum(c.data_type=='f' for s in b for row in s for c in row)}
(p/'workbook-audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
