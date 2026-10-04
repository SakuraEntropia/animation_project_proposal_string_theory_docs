#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate INDEX.md and the root README for the Re:LU Canon Repository."""
import os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.dirname(ROOT)
TREE = os.path.join(PROJ, 'ReLU-CANON')
TODAY = "2026-10-05"

DESC = {
 '00_导航':      '导航、索引与元信息',
 '01_世界观':    '世界根规律：抹平、公理体系、与现实物理的差异',
 '02_Attention': '注意力（可感性）：世界内部专有概念',
 '03_时间':      '时间墙、几何预算、时间尺度、时代',
 '04_宇宙':      '天体、纪元、恒星史、宇宙结构',
 '05_自然':      '地理、地形层级、材料、陨铁',
 '06_生态':      '生物、演化、生态系统',
 '07_文明':      '社会、制度、阶层、Ancient 文明、标准化',
 '08_技术':      '扩散机、发射器、测度仪、信息技术',
 '09_角色':      'Yau、Ricci、Godereos、配角群像',
 '10_故事':      '九拍、主线、开篇、情节哲学',
 '11_主题':      'L1 及递归主题树',
 '90_Archive':   '历史记录、审计、废弃与冲突',
}

def first_heading(p):
    try:
        for line in open(p, encoding='utf-8'):
            if line.startswith('# '):
                return line[2:].strip()
    except Exception:
        pass
    return None

def status_of(p):
    t = open(p, encoding='utf-8').read(4000)
    if '状态：`Proposed`' in t or '**状态：`Proposed`**' in t: return 'Proposed'
    if 'ARCHIVED from' in t: return 'Archive'
    if '【名称待定】' in t or '【待定】' in t: return 'TBD×'
    return 'Canon'

rows = []
for top in sorted(DESC):
    d = os.path.join(TREE, top)
    if not os.path.isdir(d): continue
    subs = []
    for dirpath, dirnames, filenames in os.walk(d):
        dirnames.sort()
        if 'README.md' in filenames:
            f = os.path.join(dirpath, 'README.md')
            rel = os.path.relpath(dirpath, TREE)
            title = first_heading(f) or rel
            subs.append((rel, title, status_of(f), os.path.relpath(f, TREE)))
        for extra in sorted(x for x in filenames if x.endswith('.md') and x != 'README.md'):
            f = os.path.join(dirpath, extra)
            rel = os.path.relpath(f, TREE)
            subs.append((rel, first_heading(f) or extra, status_of(f), rel))
    rows.append((top, subs))

L = ["# Re：LU · Canon Repository — INDEX", "",
     "> **官方标题：Re：LU**　|　完整展开：**Re: ILLUMINATE**　|　主题歌：Zona Pellucida　|　开发代号：String Theory",
     f"> **本索引重建于 {TODAY}。**",
     "",
     "**分类原则：** 第一级是**世界观内容大分类**，不是编辑过程。",
     "旧的 `01`–`42` 编号结构（按写作顺序）已废弃，见 `90_Archive/MIGRATION_LOG.md`。",
     "",
     "**状态标签：** `Canon` · `Proposed` · `TBD` · `Deprecated` · `Archive`",
     "",
     "---", "", "## 一级分类总览", "",
     "| 分类 | 内容 | 文档数 |", "|---|---|---:|"]
for top, subs in rows:
    L.append(f"| [`{top}`](#{top.replace('_','-')}) | {DESC[top]} | {len(subs)} |")
L += ["", "---", ""]

for top, subs in rows:
    L += [f"## {top}", "", f"> {DESC[top]}", "",
          "| 节点 | 标题 | 状态 |", "|---|---|---|"]
    for rel, title, st, link in subs:
        L.append(f"| `{rel}` | [{title}]({link}) | {st} |")
    L += [""]

L += ["---", "",
      "## 使用方式", "",
      "1. 从一级分类进入，逐级向下；每个目录的 `_README.md` 说明该分类的范围。",
      "2. **交叉引用**：同一设定属于多个领域时，只在主文档写全文，其余节点写引用。",
      "3. **`【待定】`** 表示该机制 Canon 不足以决定，**不得自行补全**。",
      "4. **`【名称待定】`** 表示作者尚未命名。",
      "5. 未来新增只需 append 到相应节点，再执行同一套 `全 Canon 分析 → 分类 → 迁移`。",
      "",
      "## 相关文档", "",
      "- [迁移日志](90_Archive/MIGRATION_LOG.md) — 每条旧 Canon 的去向",
      "- [主题树](11_主题/主题树.md) — 从 L1 递归推导",
      "- [Master World Bible](00_导航/Master%20World%20Bible/README.md)",
      "- [PINS 裁定总表](00_导航/PINS%20裁定总表/README.md)",
      "",
      "---", "",
      "> **创作方向（作者给定）：**",
      "> 人类生活在一个巨大、复杂、残酷、并不以人类为中心的自然世界中。",
      "> 文明只是这个世界中的一层。",
      "> 探索的意义不是因为自然会奖励人类，而恰恰是因为自然从来不会。", ""]

open(os.path.join(TREE, 'INDEX.md'), 'w', encoding='utf-8').write('\n'.join(L))

# root README
open(os.path.join(TREE, 'README.md'), 'w', encoding='utf-8').write(f"""# Re：LU · Canon Repository

> **正式标题：Re：LU**（完整展开 **Re: ILLUMINATE**）
> **主题歌：Zona Pellucida**　|　**早期开发代号：String Theory**

**本仓库是 Re:LU 设定与概念的权威结构化来源。**

收录：**既有全部 Canon** + **作者 2026-10-05 新增设定**。
全部内容经统一分类、去重、术语统一与交叉引用。

## 结构

第一级为**世界观内容大分类**（不是编辑过程、不是写作顺序）：

```
ReLU-CANON/
├── 00_导航/        导航、索引与元信息
├── 01_世界观/      世界根规律
├── 02_Attention/   注意力（世界内部专有概念）
├── 03_时间/        时间墙、几何预算
├── 04_宇宙/        天体、纪元、恒星史
├── 05_自然/        地理、地形、材料
├── 06_生态/        生物、演化、生态系统
├── 07_文明/        社会、制度、Ancient、标准化
├── 08_技术/        扩散机、发射器、测度仪
├── 09_角色/        Yau、Ricci、Godereos
├── 10_故事/        九拍、主线、情节哲学
├── 11_主题/        L1 及递归主题树
└── 90_Archive/     历史记录与审计
```

入口：[**INDEX.md**](INDEX.md)

## 迁移说明

本仓库由 `tools/migrate.py` 从旧仓库（按编辑过程编号的 `01`–`42` 结构）迁移而来。

- **内容保全**：每条旧 Canon 都有一条去向记录，见 [迁移日志](90_Archive/MIGRATION_LOG.md)。
- **不静默覆盖**：冲突一律标记，不擅自裁决。
- **不自行补 Canon**：作者未指定处一律标 `【待定】`。
- **交叉引用**：同一设定归属多个领域时，只在主文档写全文。

## 状态标签

| 标签 | 含义 |
|---|---|
| `Canon` | 已确立 |
| `Proposed` | 已提出，未最终确定 |
| `TBD` | 待定（`【待定】`／`【名称待定】`） |
| `Deprecated` | 废弃但保留 |
| `Archive` | 历史记录，非现行 Canon |

## 持续演化

未来新增设定只需 append 到相应节点，再执行同一套流程：

```
全 Canon 分析 → 概念抽取 → 关系分析 → 重复检测 → 冲突检测
→ 重新分类 → 递归建树 → 迁移 → 统一术语 → 重写文档
```

---

> 人类生活在一个巨大、复杂、残酷、并不以人类为中心的自然世界中。
> 文明只是这个世界中的一层。
> 探索的意义不是因为自然会奖励人类，而恰恰是因为自然从来不会。
""")
print("INDEX + README generated")
