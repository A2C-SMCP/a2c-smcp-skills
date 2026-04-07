# Troubleshoot — A2C-SMCP Protocol 专属指南

> 通用流程参见 SKILL.md 主文件。

## 角色

协议规范仓库本身不运行，但排查中经常需要**参照协议确认行为是否正确**。

## 排查中的协议参考

### 事件定义验证

排查跨 SDK 通信问题时，对照 `docs/specification/events.md`：
- 事件名是否正确（client:*/server:*/notify:*）
- 请求/响应数据结构是否与 `data-structures.md` 一致
- req_id 是否正确传递和回显

### 错误码验证

排查错误返回时，对照 `docs/specification/error-handling.md`：
- 错误码是否在定义范围内
- 错误响应格式是否符合 `{ "error": { "code": int, "message": str } }`

### 版本兼容性

不同版本的 SDK 可能实现了不同版本的协议。检查 `pyproject.toml` 中的版本号，确认 SDK 版本与协议版本对应。
