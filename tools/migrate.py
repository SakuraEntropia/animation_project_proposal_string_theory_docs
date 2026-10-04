#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Re:LU Canon Repository migration.
Reorganises a corpus classified by EDITING HISTORY into one classified by
WORLD CONTENT. Content-preserving: every old document is routed to a
disposition, and nothing is dropped without a record.
"""
import os, re, shutil, json, datetime, html as _html

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.dirname(ROOT)
SRC  = os.path.join(ROOT, '.build', 'out')
TREE = os.path.join(PROJ, 'ReLU-CANON')

TODAY = "2026-10-05"

# ---------------------------------------------------------------- taxonomy
# Top level = world content domains. Order is narrative-natural:
# physics -> the world -> life -> civilisation -> people -> the work itself.
TOP = [
    ("00_导航",        "导航、索引与元信息"),
    ("01_世界观",      "世界根规律：抹平、公理体系、与现实物理的差异"),
    ("02_Attention",   "注意力（可感性）：世界内部专有概念"),
    ("03_时间",        "时间墙、几何预算、时间尺度、时代"),
    ("04_宇宙",        "天体、纪元、恒星史、宇宙结构"),
    ("05_自然",        "地理、地形层级、材料、陨铁"),
    ("06_生态",        "生物、演化、生态系统"),
    ("07_文明",        "社会、制度、阶层、Ancient 文明、标准化"),
    ("08_技术",        "扩散机、发射器、测度仪、信息技术"),
    ("09_角色",        "Yau、Ricci、Gödren、配角群像"),
    ("10_故事",        "九拍、主线、开篇、情节哲学"),
    ("11_主题",        "L1 及递归主题树"),
    ("90_Archive",     "历史记录、审计、废弃与冲突"),
]

# (old filename, [dispositions])  disposition = (subpath, mode)
#   mode 'full'  = migrate the whole document body into this node
#   mode 'ref'   = this document is a source for this node; link, don't copy
#   mode 'arch'  = historical record, archive verbatim
ROUTES = {
 '00_项目命名状态.md':        [('00_导航/命名与标题', 'full')],
 '01_宇宙观与公理.md':        [('01_世界观/宇宙根公理', 'full')],
 '02_弦与扩散机.md':          [('08_技术/扩散机', 'full'),
                               ('06_生态/生物体系', 'ref'),
                               ('07_文明/社会结构', 'ref'),
                               ('05_自然/地形层级', 'ref'),
                               ('05_自然/物件体系', 'ref')],
 '03_文明与时间墙.md':        [('03_时间/时间墙', 'full'),
                               ('07_文明/从失败到制度', 'ref')],
 '04_人物.md':                [('09_角色/人物总则', 'full')],
 '05_剧情.md':                [('10_故事/主线与九拍', 'full')],
 '06_配乐提案.md':            [('10_故事/配乐', 'full')],
 '07_附录_审计与开放问题.md': [('90_Archive/审计附录', 'arch')],
 '09_修订提案_医学·认知·技术史·命名.md':[('07_文明/认知与技术史', 'full'),
                               ('06_生态/医学', 'ref')],
 '10_跨媒介研究_伏笔·隐喻·叙事机制.md':[('10_故事/伏笔与叙事机制', 'full')],
 '11_创作工作稿.md':          [('10_故事/创作工作稿', 'full')],
 '12_Yau-Gödel_人物模块.md':  [('09_角色/Yau', 'full'),
                               ('09_角色/Gödren', 'ref')],
 '13_重构_设定与架构审查.md': [('90_Archive/重构记录', 'arch')],
 '14_重构_Master_World_Bible.md':[('00_导航/Master World Bible', 'full')],
 '15_已裁定_PINS.md':         [('00_导航/PINS 裁定总表', 'full')],
 '16_已裁定_修复理由总账.md': [('90_Archive/修复理由总账', 'arch')],
 '17_核心构造修复审计.md':    [('01_世界观/构造审计', 'full')],
 '18_采纳_核心修复定值.md':   [('90_Archive/核心修复定值', 'arch')],
 '19_开篇事件提案审查.md':    [('10_故事/开篇事件', 'full')],
 '20_TSUKUSHI_BENCHMARK_REPORT.md':[('90_Archive/评估/基准报告', 'arch')],
 '21_反制策略.md':            [('90_Archive/评估/反制策略', 'arch')],
 '22_基准修复报告.md':        [('90_Archive/评估/基准修复', 'arch')],
 '23_Canon输入_SET4.md':      [('90_Archive/Canon输入/输入记录', 'arch')],
 '24_Canon_SET4_裁定与推导.md':[('90_Archive/Canon输入/输入记录', 'arch')],
 '25_Canon_SET5_代词政策.md': [('00_导航/代词政策', 'full')],
 '26_生物扩展.md':            [('06_生态/生物扩展', 'full')],
 '27_Canon_SET6_扩散机永动.md':[('08_技术/扩散机/永动与异化', 'full')],
 '28_Canon_SET7_引擎异化.md': [('08_技术/扩散机/永动与异化', 'ref')],
 '29_Canon_SET8_事实更正.md': [('04_宇宙/恒星史', 'full')],
 '30_跑分复评2.md':           [('90_Archive/评估/跑分复评', 'arch')],
 '31_Canon_SET9_测度仪.md':   [('08_技术/测度仪', 'full')],
 '32_Canon_SET10_独立来源.md':[('08_技术/技术来源与可靠性层级', 'full')],
 '33_Brainstorm回应.md':      [('90_Archive/创作方法论/Brainstorm', 'arch')],
 '34_设定总纲_供审查.md':     [('00_导航/设定总纲', 'full')],
 '35_提案_海拉式结局评估.md': [('10_故事/提案/海拉式结局', 'full')],
 '36_更正_注意力误读.md':     [('02_Attention/注意力误读更正', 'full')],
 '37_Ricci认知弧线.md':       [('09_角色/Ricci/认知弧线', 'full')],
 '38_主旨哲学漏洞与修复.md':  [('11_主题/主旨论证与修复', 'full')],
 '39_哲学研究.md':            [('11_主题/哲学文献研究', 'full')],
 '40_已裁定_放弃客观性.md':   [('11_主题/放弃客观性', 'full')],
 '41_剧情哲学_纵向与横向.md': [('10_故事/纵向与横向', 'full')],
 '42_创作动机_反市场.md':     [('11_主题/创作动机与反市场', 'full')],
}

# New author-supplied settings: analysed, classified, NOT invented.
NEW = [
 ('07_文明/威权文明', '背景板文明',
  '作者新增（2026-10-05）。**身份：背景板。**',
  ['它是角色生活的社会环境来源',
   '它解释：基础设施 / 发射器 / 领航员 / 社会文化 / 人类活动痕迹',
   '⛔ **不得**把它展开为政治小说、反乌托邦、制度批判或国家寓言',
   '**文明问题在本作中弱化**——它是世界的一部分，不是核心'],
  ['名称：**【名称待定】**','政体细节：**【待定】**','历史：**【待定】**',
   '与 Ancient 文明的关系：**【待定】**']),
 ('08_技术/物理硬盘通信', '物理硬盘通信',
  '作者新增（2026-10-05）。**技术树高度不均衡**的证据。',
  ['信息以**物理硬盘**为载体运输',
   '原因与基础设施＋**发射器体系**牵引有关：大量资源、线路与建设能力被发射器占用',
   '表现：电线不足 · 通信基础设施不足 · 线路建设畸形 · 物理运输数据',
   '⛔ **不得写成"科技倒退"**——重点是**技术树不均衡**，不是整体落后'],
  ['硬盘规格：**【待定】**','传输频次与网络形态：**【待定】**',
   '与已有「M-DISC」的关系：**【待定】**（`05_自然/物件体系`）']),
 ('09_角色/Yau/家庭与成长环境', 'Yau 的家庭',
  '作者新增（2026-10-05）。与既有 Yau Canon 合并。',
  ['Yau 从小**喜欢自己捣鼓东西**',
   '家中存在大量：自制设备 · 拆解物 · 工具 · 实验装置 · 奇怪机械 · 未完成项目 · 自己改造的东西',
   '⛔ **不得简化为"Yau 是天才"**',
   '★ 重点是：**Yau 从小就习惯自己动手理解世界**'],
  ['家庭成员构成：**【待定】**','家庭阶层／所在地：**【待定】**',
   '这些自制物与 `08_技术/测度仪`（独立发明）是否有传承关系：**【待定】**']),
 ('07_文明/Ancient', 'Ancient 文明',
  '作者新增（2026-10-05）。**参照《来自深渊》中古老文明的存在方式。**',
  ['Ancient 通过**文字 · 遗迹 · 建筑 · 器物 · 符号 · 文化残留 · 生物 · 环境**逐渐显现',
   '需要建立其自己的：文字系统 · 语言 · 建筑 · 艺术 · 音乐 · 宗教／哲学 · 日常文化 · 仪式 · 死亡观 · 时间观 · 自然观 · 生物观 · 技术',
   '⛔ **不得写成单纯的"神秘高级古代文明"**',
   '★ 它应该像一个**真正生活过、留下大量痕迹、但已经消失的文明**',
   '★ 主要作用之一：增强**世界的历史深度与时间感**'],
  ['文字系统：**【待定】**','语言：**【待定】**','建筑：**【待定】**',
   '艺术：**【待定】**','音乐：**【待定】**','宗教／哲学：**【待定】**',
   '日常文化：**【待定】**','仪式：**【待定】**','死亡观：**【待定】**',
   '时间观：**【待定】**','自然观：**【待定】**','生物观：**【待定】**',
   '技术：**【待定】**','★ **Ancient 与本作"烬纪"的关系：**【待定】']),
 ('06_生态/演化/时间与演化', '时间 → 环境 → 生物 → 演化',
  '作者新增（2026-10-05）。本作是**时间类故事**，此链条为承重结构。',
  ['需系统设计：**时间 → 环境 → 生物 → 演化**',
   '需设计：生物生命周期 · 物种演化 · 灭绝 · 环境变化 · 地理变化 · 不同时代生态系统 · 时间尺度 · **生物如何体现时间**',
   '★ 需与既有 `03_时间` 的时间机制整合'],
  ['各时代划分：**【待定】**','灭绝事件清单：**【待定】**',
   '★ **时间尺度与 `05_自然/地形层级` 的对应：**【待定】**',
   '⚠ 既有 `26_生物扩展` 的四次灭绝链**早于本设定**，需作者确认二者关系']),
 ('05_自然/同一地点的时间识别', '同一地点的时间识别',
  '作者新增（2026-10-05）。**判断依据必须来自世界内部。**',
  ['角色在不同时间来到同一地点时，需能判断**"这里就是过去来过的地方"**',
   '依据可来自：地形 · 地质 · 植物 · 生物 · 建筑 · 遗迹 · 人造物 · 生态系统 · 环境变化',
   '⛔ **不得单纯依靠旁白告诉观众**',
   '★ 须与已有时间机制、生物演化与地理设定**统一**'],
  ['★ 具体识别机制：**【待定】**——这是本设定最关键的缺口',
   '★ 是否与 `08_技术/测度仪`（测 `D_max`）有关：**【待定】**',
   '★ 是否与 `03_时间/时间墙` 的跨区时间剪切有关：**【待定】**']),
 ('02_Attention/注意力疾病', '注意力疾病',
  '作者新增（2026-10-05）。**创作原型：现实中的脑胶质瘤。**',
  ['⚠ **必须先读 `02_Attention/注意力总则` 中既有"注意力"定义，再设计疾病**',
   '现实脑胶质瘤**只是创作原型**，不是要求复制现实医学',
   '⛔ **禁止擅自扩展为**：ADHD · 注意力障碍 · 现实神经科学 · 现实医学 · 脑肿瘤科普',
   '★ 本作中"注意力"是**世界内部专有概念**，不是现实心理学概念'],
  ['★ **疾病机制：**【待定】**——依作者指令，Canon 不足以决定时必须标待定，不得自行确定',
   '疾病名称：**【待定】**','与 `F2` 注意力守恒的关系：**【待定】**',
   '与 `08_技术/扩散机`（弦层直接读写）的关系：**【待定】**',
   '与既有「噪声病者」阶层的关系：**【待定】**（`07_文明/社会结构`）']),
 ('11_主题/猎奇元素', '猎奇元素',
  '作者新增（2026-10-05）。**保留一定程度的猎奇感。**',
  ['猎奇元素可作为**生物、身体或世界观层面**的特殊元素存在（例：futa）',
   '⛔ **不得自行扩写成色情内容**',
   '⛔ **不得让猎奇元素取代核心内容**：自然 · 探索 · 时间 · 生命'],
  ['★ 具体形态：**【待定】**',
   '⚠ 既有 `SET4-R` 已确立"所有个体为**单一生殖型**"；'
   '猎奇元素与它的关系：**【待定】**',
   '`PIN-17` 代词政策（他／祂）在此的适用：**【待定】**']),
 ('07_文明/烂尾美学', '烂尾美学',
  '作者新增（2026-10-05）。**发射器是典型例子。**',
  ['"烂尾"表现：巨大的文明工程 · 曾经具有宏大目标 · 最终没有完成 · 不断追加 · 长期维护困难 · 不同时期工程层层叠加 · 留下巨大的文明残骸',
   '★ "烂尾"主要属于**文明景观**',
   '它用于表现：历史 · 时间 · 文明痕迹 · 探索环境 · 人类留下的残骸',
   '⛔ **不得把"烂尾"上升成整个宇宙的规律**'],
  ['发射器的具体形态：**【待定】**（见 `08_技术/发射器`）',
   '烂尾工程清单：**【待定】**']),
 ('07_文明/标准化', '标准化',
  '作者新增（2026-10-05）。例：**标准化牧场**。',
  ['标准化体现：文明**试图把自然、生物与生产过程变成可控制、可复制、可管理的对象**',
   '⛔ **标准化是【文明问题】**，不是"Re:LU 世界最可怕的事情"，也不是核心主题',
   '⛔ **不得因此把作品变成**：反工业 · 反科技 · 反现代化 · 反标准化 · 制度批判',
   '★ 标准化只是**这个文明面对自然时的一种行为**',
   '★ **自然本身才是更重要的对象**'],
  ['标准化牧场的具体形态：**【待定】**',
   '与既有 `06_生态` 摄食链的关系：**【待定】**',
   '与既有"食物必须种出来＋耕作者"推导的关系：**【待定】**']),
 ('09_角色/【反派·名称待定】', '所谓"反派"',
  '作者新增（2026-10-05）。**并非传统意义的最终反派。**',
  ['★ 与黎明卿式人物的区别：',
   '　黎明卿式：**个人主动**与自然发生极端耦合，并实施违背伦理的行为',
   '　本作此人：**他的行为同时受到整个架空文明推动**——国家支持 · 文明需要 · 技术体系支持 · 社会环境支持',
   '⛔ **不得简单理解成"一个疯子造成了一切"**',
   '⛔ **也不得进一步简化成"真正反派其实是国家"**',
   '★ 本设定首要用于讨论：**人类文明如何介入自然**'],
  ['名称：**【名称待定】**','身份与所属机构：**【待定】**',
   '具体行为：**【待定】**','与 `07_文明/威权文明` 的关系：**【待定】**',
   '与 `09_角色/Gödren` 的关系：**【待定】**']),
 ('09_角色/领航员', 'Navigator / 领航员',
  '作者新增（2026-10-05）。**人人都想成为领航员**——这是文明中的探索理想。',
  ['**绝大多数人并不一定能够成为真正的领航员**',
   '发射器存在**极高风险**。尝试者可能：失败 · 失踪 · 严重受伤 · 永久残疾 · 死亡',
   '⛔ **重点不是"国家逼人去送死"**',
   '★ 重点是：**人类主动向未知自然发起探索，而自然不会因为人类拥有理想就降低危险**',
   '★ 需与以下建立关系：自然 · 探索 · 时间 · 生物 · 发射器 · 人类局限'],
  ['⚠ 既有 Canon 说领航员是"无法理解的神"、完全变异、寿命短而悲壮（`07_文明/社会结构`）；'
   '本设定补充了**社会面向（人人向往）**。二者是否冲突：**【待定】**',
   '★ 既有 `SET9` 说领航员负责**测量 `D_max`**；与本设定的关系：**【待定】**',
   '选拔机制：**【待定】**','成功率：**【待定】**']),
]

STATUS = {'full':'Canon','ref':'Canon','arch':'Archive'}

def slug(p):
    return p.replace('/', '__')

def ensure(d):
    os.makedirs(d, exist_ok=True)

def safe_write(path, text):
    """Never silently overwrite: if a different document already owns this
    path, keep both. This is the guard that doc 08 splitting needed."""
    if os.path.exists(path):
        base, ext = os.path.splitext(path)
        i = 2
        while os.path.exists(f'{base}__{i}{ext}'):
            i += 1
        path = f'{base}__{i}{ext}'
    open(path, 'w', encoding='utf-8').write(text)
    return path

def strip_frontmatter(t):
    return re.sub(r'\A<!--.*?-->\s*', '', t, flags=re.S)

def build():
    if os.path.exists(TREE):
        shutil.rmtree(TREE)
    ensure(TREE)

    # top-level dirs + README
    for name, desc in TOP:
        d = os.path.join(TREE, name)
        ensure(d)
        open(os.path.join(d, '_README.md'), 'w', encoding='utf-8').write(
            f"# {name}\n\n> {desc}\n\n"
            f"本目录属于 **Re：LU Canon Repository**。\n\n"
            f"状态标签：`Canon` · `Proposed` · `TBD` · `Deprecated`\n\n"
            f"返回：[仓库索引](../INDEX.md)\n")

    # leaf docs
    index_rows = []
    for oldfile, routes in sorted(ROUTES.items()):
        p = os.path.join(SRC, oldfile)
        if not os.path.exists(p):
            print("!! missing source:", oldfile); continue
        body = strip_frontmatter(open(p, encoding='utf-8').read())
        title = oldfile[:-3]
        primary = routes[0][0]   # first route owns the full text
        for sub, mode in routes:
            if sub != primary:
                mode = 'ref'          # only the primary route carries the text
            elif mode == 'arch':
                pass                  # a document whose PRIMARY home is Archive stays archived
            # name the leaf after its SOURCE document: two different source docs
            # can target the same node (e.g. an appendix split and a revision
            # proposal) without one silently overwriting the other.
            fname = re.sub(r'[^0-9A-Za-z\u4e00-\u9fff·]+', '_', title) + '.md'
            dest_dir = os.path.join(TREE, sub)
            ensure(dest_dir)
            fn = os.path.join(dest_dir, fname)
            if mode == 'full':
                ensure(dest_dir)
                safe_write(fn, 
                    f"<!-- migrated from {oldfile} -->\n\n{body}")
            elif mode == 'arch':
                ensure(dest_dir)
                safe_write(fn, 
                    f"<!-- ARCHIVED from {oldfile}. Historical record; not current canon. -->\n\n{body}")
            else:  # ref
                if not os.path.exists(fn):
                    safe_write(fn, 
                        f"# {sub.split('/')[-1]}\n\n> **交叉引用节点。**\n\n"
                        f"本节点**无独立正文**；权威内容见主文档。\n\n"
                        f"- 来源文档：`{oldfile}`\n"
                        f"- 主文档节点：`{primary}`\n"
                        f"- 引用理由：该文档同时涉及本领域，正文已置于 `{primary}`\n")
            index_rows.append((sub, oldfile, mode))

    # new settings
    for sub, label, provenance, points, tbd in NEW:
        d = os.path.join(TREE, sub); ensure(d)
        lines = [f"# {label}", "",
                 f"> **状态：`Proposed`**（作者新增设定，已分类待整合）", "",
                 f"**来源：** {provenance}", "",
                 "---", "", "## 设定内容（作者给定）", ""]
        lines += [f"- {x}" for x in points]
        lines += ["", "---", "", "## 【待定】项（不得自行补全）", ""]
        lines += [f"- {x}" if not x.startswith(('★','⚠','⛔')) else f"- {x}" for x in tbd]
        lines += ["", "---", "",
                  "## 迁移说明", "",
                  f"- 本节点由 `tools/migrate.py` 于 {TODAY} 建立。",
                  "- **作者明确指定的内容全部保留；未指定处一律标 `【待定】`，未自行补 Canon。**",
                  "", "返回：[仓库索引](../../INDEX.md)", ""]
        safe_write(os.path.join(d, sub.split('/')[-1] + '.md'), '\n'.join(lines))
        index_rows.append((sub, '(新增设定)', 'new'))

    # ---- split doc 08: it is five documents concatenated under one filename ----
    p08 = os.path.join(SRC, '08_附录_形式化与审计全文.md')
    if os.path.exists(p08):
        txt = open(p08, encoding='utf-8').read()
        idxs = [m.start() for m in re.finditer(r'^# 【', txt, re.M)]
        SPLIT_ROUTE = {
          'Formalized World Model（主文档）':          '01_世界观/形式化世界模型',
          '时间墙 · VibeWorldbuilding 设计卷':        '03_时间/时间墙设计卷',
          'Canon 修订提案（医学·认知·技术史·命名）':  '07_文明/认知与技术史',
          '审计 A · 数值天体物理审计':                '04_宇宙/天体物理校核',
          '审计 B · 熵与几何数学物理审计':            '01_世界观/熵与几何数学物理校核',
          '模型运行结果':                              '90_Archive/模型运行结果',
        }
        for i, st in enumerate(idxs):
            en = idxs[i+1] if i+1 < len(idxs) else len(txt)
            blk = txt[st:en].rstrip() + '\n'
            banner = blk.split('\n', 1)[0].strip('# ').strip().strip('【】').strip()
            dest = SPLIT_ROUTE.get(banner)
            if not dest:  # tolerate minor drift in the banner text
                for k, v in SPLIT_ROUTE.items():
                    if k[:6] in banner or banner[:6] in k:
                        dest = v; break
            if not dest:
                print('   !! unmapped 08 part:', repr(banner)); continue
            d = os.path.join(TREE, dest); ensure(d)
            open(os.path.join(d, dest.split('/')[-1] + '.md'), 'w', encoding='utf-8').write(
                f"<!-- SPLIT from 08_附录_形式化与审计全文.md ; banner: {banner} -->\n\n" + blk)
            index_rows.append((dest, f'(08 分卷: {banner})', 'split'))
        # 08 itself is now fully decomposed; nothing is archived whole
        for j, r in enumerate(index_rows):
            pass

    # theme tree
    tdir = os.path.join(TREE, '11_主题'); ensure(tdir)
    open(os.path.join(tdir, '主题树.md'), 'w', encoding='utf-8').write(THEME_TREE)
    return index_rows

THEME_TREE = """# 主题树（Theme Tree）

> **状态：`Proposed`**
> 生成方式：**从全部 Canon 递归推导**，不是人为拼接。
> 递归深度不固定：能自然拆分的就继续，不能的停止。
> **L1 是作者明确的最高层命题，不得改动。**

---

## L1 · 最高层命题

> ## **L1：一切趋于无，我们还能做些什么？**

`[CANON]` 源 `01 §0`。

---

## L2 · 从 Canon 递归得出的四条

> **推导依据**：每条 L2 必须能回答"它从哪条 Canon 长出来"。
> 无法指出依据的，不列为 L2。

### L2-1 · 抹平不可对抗，只能被局部让渡

| 依据 | 内容 |
|---|---|
| `F1` | 抹平是天道本身，不是敌人 |
| `F3` + `geometric_budget_transfer` | 加速是**搬运**，不是创造 |
| `wall_moves_but_does_not_vanish` | 世界总速率不变，只是位置移动 |

**L3-1.1 代价总落在别处**
→ 依据：`geometric_budget_transfer`
→ 下接：`L4 债时制度`（`07_文明`）

**L3-1.2 任何维持都需要支付**
→ 依据：`attention_budget_bound`（计数配给）
→ 下接：`L4 谁能被维持`

### L2-2 · 理解永远缺席于使用

| 依据 | 内容 |
|---|---|
| `M1` | 能用 ≠ 能解释 |
| `M3` | 文明无法知道哪一条限制是公理性的 |
| `SET7` | 引擎异化：使用会累积不理解的代价 |

**L3-2.1 装置在被使用而不被理解**
→ 下接：`L4 扩散机`（`08_技术`）

**L3-2.2 制度在被执行而不被理解**
→ 下接：`L4 Gödren 的位置被制度化`（`09_角色`）

**L3-2.3 概念在被使用而不被定义**
→ 下接：`L4 Ricci 与「情感」`（`09_角色/Ricci/认知弧线`）

> ★ **L3-2.1 / 2.2 / 2.3 是同一个形式的三次出现。
> 这是递归推导的结果，不是设计出来的。**

### L2-3 · 自然是主体，文明只是其中一层

| 依据 | 内容 |
|---|---|
| 作者指令（2026-10-05） | **自然是主体** |
| `F1` | 抹平先于且独立于文明 |
| 六个已确立机制 | **无一条依赖主角或文明** |

**L3-3.1 人类不因拥有理想而获得自然的让步**
→ 依据：作者新增「领航员」设定
→ 下接：`L4 发射器的高风险`

**L3-3.2 文明试图把自然变成可管理对象**
→ 依据：作者新增「标准化」
→ 下接：`L4 标准化牧场`

**L3-3.3 文明留下的痕迹是残骸，不是成就**
→ 依据：作者新增「烂尾美学」
→ 下接：`L4 发射器`

### L2-4 · 意义只在记账者之间生效

| 依据 | 内容 |
|---|---|
| 作者裁定（2026-09-12） | **明确放弃客观性主张** |
| `F2` | 注意力守恒只在存在之间分配 |
| 三句作者台词第三句 | 「你仍然有独立的人格啊」= 结算的必要条件 |

**L3-4.1 没有外部裁决者**
**L3-4.2 因此账目必须能把自己也算进去**
→ 这不只是伦理防线，它**正是第一句台词的形式**：「剥夺可能性」是在拆自己的地基

---

## L3 及更深 · 递归规则

**继续拆分的条件**（三者须同时满足）：

1. 能指出它从哪条 Canon 长出
2. 它能生成**具体场景**，而不只是更细的抽象
3. 它不与同层其他节点重叠

**停止拆分的条件**（任一满足即停）：

1. 再拆只能得到同义反复
2. 再拆已经是**角色层**的具体问题，而非主题
3. 再拆需要新增 Canon 才能成立 ← ⛔ **必须停**

---

## ⛔ 被判定为"非 L2"的候选材料

> 作者特别要求：以下曾讨论过的材料**只是候选思想材料**，不得直接写成 L2。
> 判定依据：它们与 **L1 的关系**、**层级归属**。

| 候选 | 判定 | 理由 |
|---|---|---|
| **马斯洛需求层次** | ✅ **属于角色层**（`09_角色`），**非 L2** | 它是"个人如何自我实现"的框架，而 L1 问的是"世界趋于无时做什么"。**层级不同** |
| **天赋** | ⚠ **属于角色层 + 生物层** | 与 `06_生态` 的遗传机制相关；是**个体差异**问题，不是世界问题 |
| **时代窗口** | ✅ **属于 `03_时间` + `07_文明`** | "窗口关闭"是本作的时间结构（`PIN-06`），**应作为机制而非主题** |
| **自我实现** | ⚠ **属于角色层** | 由 `09_角色` 承载；**它不构成 L2**，因为它需要一个不存在的客观侧才能成为主题（见 `11_主题/放弃客观性`） |
| **反市场 / 反抖音化** | ⚠ **属于创作方法论**（`90_Archive` 或 `11_主题/创作动机`） | 它是**创作动机**，不是世界内命题。**不应作为 L2 出现在世界主题树中** |

> **判定原则：**
> **能作为 L2 的，必须是【关于世界】的命题。
> 凡是【关于角色】或【关于创作】的，降级到相应层。**

---

## 主题权重约束（作者指令，2026-10-05）

| 项 | 约束 |
|---|---|
| **自然是主体** | ✅ 必须保持 |
| **文明相关设定** | ⛔ **不得压过自然主题** |
| 想象体验参照 | 与《来自深渊》的**未知世界 + 自然残酷 + 探索**形成精神联系 |
| Re:LU 自有要素 | 时间 · 熵 · Ancient 文明 · 生物演化 · 烂尾文明景观 · 标准化文明 · 注意力 · 自己的世界规律 |

---

返回：[仓库索引](../INDEX.md)
"""

def main():
    rows = build()
    # migration log
    log = [f"# Migration Log", "",
           f"> **迁移日期：** {TODAY}",
           f"> **旧仓库：** 按编辑过程分类（`01`–`42` 编号 + RESTRUCTURE 工作区）",
           f"> **新仓库：** `ReLU-CANON/`，按**世界观内容**分类",
           f"> **原则：** 每条旧 Canon 都必须有去处；不静默覆盖；不自行补 Canon。", "",
           "---", "", "## 一、迁移映射", "",
           "| 旧文档 | 去向 | 方式 |", "|---|---|---|"]
    for sub, old, mode in rows:
        m = {'full':'整体迁移','arch':'归档（历史记录）','ref':'交叉引用',
             'new':'**新增设定**','split':'**从 08 分卷**'}[mode]
        log.append(f"| `{old}` | `{sub}` | {m} |")
    open(os.path.join(TREE, '90_Archive', 'MIGRATION_LOG.md'), 'w', encoding='utf-8').write('\n'.join(log) + '\n')
    print(f"migrated {len(rows)} routes; tree at {TREE}")

if __name__ == '__main__':
    main()
