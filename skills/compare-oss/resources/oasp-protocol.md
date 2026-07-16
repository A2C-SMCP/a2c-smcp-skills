# Compare-OSS — oasp-protocol 专属指南

> 通用流程参见 SKILL.md 主文件。

## 项目上下文

- 形态：MkDocs 协议规范文档仓（`docs/` + `mkdocs.yml`），无运行时代码
- 定位：Office AddIn Socket Protocol（OASP）规范——office4ai（Python 端）与 office-editor4ai（加载项端）之间的通信契约
- 架构约定：见项目根 `CLAUDE.md`

## Phase 0 差异：对比对象形态

对方通常是**通信方案/协议**而非单一代码库：Office.js 原生通道方案、其他 add-in ↔ host 桥接协议、通用 RPC-over-WebSocket 方案。规范文本 + 其参考实现一起拉。

## Phase 1 差异：维度盘点 = 契约条款对照

对照维度：消息/事件语义、请求-响应关联、错误传播、加载项生命周期（挂起/恢复/多文档）、批量操作、版本协商。每格标注规范章节号。

## Phase 4 差异：无运行时可 bench → 双端互操作实测

OASP 的天然实验基座是自家双端——**office4ai + office-editor4ai 搭最小链路**：

1. 构造对方方案声称更优的场景（如批量消息合并、断线恢复语义），在 OASP 链路上实测行为与延迟
2. 对方方案有参考实现时，同场景跑其实现对照；跑不起来（如需特定 Office 版本/商店部署）则显式记录，结论降级「存疑」
3. Office 运行时依赖强的场景允许「手动实测」，报告中标注

**协议特有过滤器**（Phase 5 追加）：对方方案是否绑定 Office.js 某宿主版本/Requirement Set？其假设（单文档、单加载项实例）在我方多端场景是否成立？

## 典型对比对象

- Office.js 原生 Dialog/ Custom Functions 通信通道（微软官方路线）
- 其他 Office add-in 与本地服务的桥接方案
- 通用 RPC-over-WebSocket / Socket.IO 协议设计（错误语义/重连模型参照）
