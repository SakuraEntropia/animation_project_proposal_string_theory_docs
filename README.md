# animation_project_proposal_string_theory_docs

**《STRING THEORY》动画企划 · 设定文档集 + 形式化世界模型**

一个把非形式化世界观文档重新编译成 **可推导、可验证的生成式世界模型** 的仓库。

| | |
|---|---|
| **作品** | 《STRING THEORY》 |
| **仓库用途** | 动画企划提案 · 设定文档 · 形式化验证 |
| **设定文档** | 🔒 **加密**（见下） |
| **Lean 形式化** | ✅ 公开 · 61 定理 · `lake build` 成功 |

---

## 目录结构

```
.
├── docs/
│   └── worldbuilding/          🔒 加密的设定文档集（GitHub Pages）
│       ├── index.html
│       ├── 01-宇宙观与公理.html
│       ├── 02-弦与扩散机.html
│       ├── 03-文明与时间墙.html
│       ├── 04-人物.html
│       ├── 05-剧情.html
│       ├── 06-配乐提案.html        （占位，待填）
│       ├── 07-附录-审计与开放问题.html
│       └── 08-附录-形式化与审计全文.html
├── lean/
│   ├── README.md
│   └── formalized_world/       ✅ Lean 4 + Mathlib 形式化（61 定理）
└── tools/
    ├── gen.py                  文档生成器（从源设定解析）
    └── encrypt.py              加密打包器
```

---

## 🔒 关于加密

设定文档**以 AES-256-GCM 客户端加密**，密码由企划方持有。

* 每个页面是**独立的单文件 HTML**，可离线打开，无需服务器。
* 加密在**浏览器内**完成（WebCrypto）：`PBKDF2-SHA256`（600,000 次迭代）派生密钥，
  `AES-256-GCM` 解密。
* **明文从未以未加密形式进入本仓库**——仓库中只存在密文与解密页面本身。
* 密码错误会失败于 GCM 认证标签，不提供任何预言机（oracle）。
* 密钥派生在**客户端**完成，密码不会离开浏览器。

> 页面已加 `noindex, nofollow`，但**公开仓库的内容不构成保密**：
> 密文是公开的，安全性完全依赖于密码强度。请勿在页面中放入高价值机密。

---

## ✅ Lean 形式化

`lean/formalized_world/` 是本设定世界的**机器验证数学内核**。

| 项 | 值 |
|---|---|
| 工具链 | `leanprover/lean4:v4.33.1` |
| 依赖 | Mathlib rev `v4.33.1` |
| 规模 | 8 模块 · 1767 行 |
| 定理 | **61 个，全部通过** |
| 构建 | `lake build` → **SUCCESS (8715 jobs)** |

```bash
cd lean/formalized_world && lake build
```

**核心定理**

| 定理 | 内容 |
|---|---|
| `flattening_max_entropy` | `S_W(p) ≤ log n`，等号**当且仅当** `p` 为均匀分布 |
| `attention_budget_bound` | 守恒预算 `A` 最多支撑 `A/c` 个结构 |
| `runaway_has_no_equilibrium` | 世界**不存在**非零平衡点 |
| `ritual_is_optimal_under_scarcity` | 越过有限阈值 `λ*` 后，释放严格优于保存 |
| `norm_is_emergent` | 文化规范由约束决定，而非由天性决定 |
| `geometric_budget_transfer` | 加速一个区域，必由另一个区域支付 |

> **Lean 证明了什么：** 在给定形式化假设下，这些命题成立。
> **Lean 没有证明：** 这些公理描述了我们的宇宙。
> `lake build` 成功是关于形式系统内部推导的陈述，不是关于现实的陈述。

---

## 🔧 重建

工具需要密码才能生成加密页面（密码**不入库**）：

```bash
# 方式一：环境变量
export ST_WORLDBUILDING_PASSWORD='...'
python3 tools/gen.py        # 从源设定解析并生成 8 份明文文档
python3 tools/encrypt.py    # 加密为 docs/worldbuilding/*.html

# 方式二：本地凭据文件（已在 .gitignore 中）
echo '{"password":"..."}' > .repo-credentials
```

---

## 方法说明

本仓库把原作设定文档视为**非形式化规格**，而非已成立的理论。每一条断言被归入且仅归入四类：

| 标记 | 含义 |
|---|---|
| **THEOREM** | 由公理与定义推出，且已在 Lean 中机器验证 |
| **MODEL RESULT** | 由数值或参数模型得到，不是严格定理 |
| **ASSUMPTION** | 主动指定的规则 |
| **NARRATIVE CONSEQUENCE** | 为故事表达而选择，目前无法严格推出 |

若推导结果与原有剧情冲突，**保留形式系统并报告冲突**，而非修改数学。
完整的一致性审计（24 处与现实物理或自身的冲突）见加密文档 `07` 与 `08`。

---

## 许可

设定与剧情内容版权归原作者所有。Lean 形式化代码以 Apache 2.0 提供。
