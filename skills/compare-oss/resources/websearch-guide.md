# 选型类线索的 Web 现状核验（Phase 3 方法资源）

**跨项目通用**。选型/产品类结论——「该用哪个库/引擎/协议」「X 比 Y 更适合我们」——必须落到**当前**数据，不能用训练期印象。本文给可直接跑的 recipe 与纪律。

---

## 为何强制实时核验：AGE 翻车案例

一次真实翻车（TuringFocus 线实践，教训跨项目通用）：凭训练期印象断言「Apache AGE 版本滞后 PostgreSQL 1~2 个大版本、PG18 兼容性存疑」，据此建议「自建两表 edge-list 替代 AGE」。用户质疑后拉实时数据：

- AGE 自 **v1.7.0（2026-01）就支持 PG18**，v1.8.0（2026-07）追平 PG18+PG19；4.7k★、97 contributors、最近提交在数天内。
- 「版本滞后」的核心论据**已过时**，据此推出的替换建议随之作废。

**教训**：任何「落后/过时/不行」的断言，出口前必须用当前数据复核一遍。训练期印象是假设，不是证据。

---

## GitHub 健康度 recipe（`gh api`）

对每个候选库/引擎，拉这几组信号（`repo` 换成 `owner/name`）：

```bash
# 1) 基础活跃度与治理
gh api repos/<owner>/<name> --jq '{stars:.stargazers_count, forks:.forks_count,
  open_issues:.open_issues_count, subscribers:.subscribers_count,
  pushed_at:.pushed_at[0:10], archived:.archived, license:.license.spdx_id, desc:.description}'

# 2) 发布节奏 + 目标版本支持（release 名里常带版本标记）
gh api "repos/<owner>/<name>/releases?per_page=20" --jq '.[] | "\(.published_at[0:10])  \(.tag_name)  \(.name)"'

# 3) 提交脉搏：是真活，还是只打 release tag？
gh api "repos/<owner>/<name>/commits?per_page=20" --jq '.[].commit.committer.date[0:10]'

# 4) 52 周提交分布（判断「近期提速/停摆」，oldest->newest）
gh api "repos/<owner>/<name>/stats/participation" --jq '.all'

# 5) bus factor：贡献者数（=100 说明被截断，实际更多）
gh api "repos/<owner>/<name>/contributors?per_page=100&anon=false" --jq 'length'
```

> 分支常按版本命名，`gh api repos/<repo>/branches?per_page=100 --jq '.[].name'` 可判断多版本支持面。

## 信号解读

| 信号 | 健康 | 警示 |
|---|---|---|
| 最近 commit / pushed_at | 数天~数周内 | 数月无提交 |
| 52 周分布 | 均匀，近期不弱 | 前重后轻、长段 0（曾停摆） |
| release 节奏 | 稳定周期 | 长期断档后突发（曾停摆再复活） |
| contributors | 数十~上百、多雇主 | 个位数 / 单人主导（bus factor 高） |
| 版本成熟度 | 1.x+ 稳定 | 0.x pre-1.0（次版本可能破 API，须锁版本） |
| 目标版本支持 | 已支持我方基线 | 滞后 / 仅 rc / EOL 临近 |
| 许可证 / 归属 | 宽松 + 社区治理 | 厂商锁定 / 单一赞助方 / copyleft 冲突 |

## WebSearch 补位

`gh api` 拿不到的用 WebSearch / WebFetch：项目是否被弃、是否已 fork 换名、社区迁移动向、生产事故复盘、与竞品的最新对比、商业授权变更。

**多源交叉验证纪律**（别单点采信）：

- 任一关键断言至少 **2 个独立来源**印证；只有单一来源时，结论降级为「待证」。
- **一手优于二手**：官方 release notes / issue / commit / 官方文档 > 二手博客 / 聚合评测。
- 来源互相矛盾时，以**更新、更权威**者为准，并在结论里显式标注分歧与取舍理由。
- 警惕采样偏差：搜到的「X 不行」可能来自旧版本或特定场景，回到一手来源确认适用范围。

---

## 纪律清单

- [ ] 每条选型断言都有**当前**数据支撑，结论标注**数据日期**（数字会过时）。
- [ ] 「落后/过时/不行」类断言，落笔前用当前数据复核过一遍。
- [ ] **诚实优于唱赞歌**：同时列对方真实风险（停摆史、bus factor、pre-1.0）与我方真实短板。
- [ ] 区分「活跃度」与「适配度」：项目很活 ≠ 适合我方场景（许可证/部署形态/协议模型仍可能不合）。
- [ ] 对方绕开某技术的动机，先查是否是我方**不共享**的约束（如对方托管环境限制 → 我方自托管则该动机不成立）。
