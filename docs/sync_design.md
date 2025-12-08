# 同步设计（Log + Cursor）

## 目标
- 保障多端在创建/更新/删除后可在下一次同步看到一致结果。
- 允许离线操作，恢复网络后自动补发。
- 采用日志式增量 + 游标，避免全量拉取/重复去重带来的回滚风险。

## 核心数据与队列
- 本地 SQLite
  - `sync_ops(entity_type, entity_id, op, payload, created_at)`：待推送日志，op ∈ {upsert, delete}。
  - `metadata(key, value)`：同步游标，例如 `snippets_cursor`、`tags_cursor`。
  - 业务表 `snippets` / `tags` 均持久化 `version`、`updated_at`、`deleted_at`。
- 墓碑删除
  - 删除写入 `deleted_at = now`，并作为 `delete` op 入队，远端和本地都不硬删。

## 同步协议（双端兼容）
- 端点
  - `POST /snippets/sync`
  - `POST /tags/sync`
- 全量下载
  - `GET /snippets/full?limit=200&page=1`
  - `GET /tags/full?limit=200&page=1`
  - 客户端循环分页直到返回列表长度 < limit。
- 请求体
  ```json
  {
    "cursor": "2024-05-01T12:00:00Z",     // 可选，增量起点
    "ops": [
      {"op": "upsert", "snippet": { ...完整字段含 deleted_at... }},
      {"op": "delete", "snippet": { "id": "...", "deleted_at": "..." }}
    ]
  }
  ```
  Tag 同理，字段名替换为 `tag`。
- 响应体
  ```json
  {
    "changes": [ { ...record..., "deleted_at": null | iso8601 } ],
    "nextCursor": "2024-05-01T12:05:00Z"
  }
  ```
  - `changes` 包含自 cursor 之后的新增/更新/删除；删除通过 `deleted_at` 表示。
  - 服务端会将 `nextCursor` 至少推进到返回列表中最大的 `(deleted_at | updated_at)`，如果无变更则返回当前时间。
  - 全量场景请调用单独的下载接口（见下文）。

## 使用建议
- 增量同步：正常用户操作后自动触发（显式“同步”按钮）。保持 `sync()` 走增量。
- 全量同步：首次登录或怀疑游标损坏时，分页调用 `GET /tags/full` + `GET /snippets/full`（客户端封装为 `downloadAll()`）拉取所有数据后重置本地，并写入最新 cursor 以便继续增量。

## 处理流程
1. 读取本地 `pending = sync_ops(entity_type)`。
2. 构造 payload（含 cursor + ops），POST `/…/sync`。
3. 200/OK 时：
   - 删除已推送的 pending 记录。
   - 将响应中的 `changes` 写入本地：
     - `deleted_at != null` → 作为墓碑写入或删除本地可见数据。
     - 其余记录执行 upsert。
   - 更新 `metadata` 中对应的 cursor。
4. 失败时：保留 pending，不更新 cursor，等待下次同步。

## 冲突与排序
- “最新写胜”（以 `(deleted_at | updated_at)` 为最终时间戳）。版本号在服务端入库时自增，以防并发写入落后。
- 不再按标题/名称去重；服务端根据主键或用户 + 唯一键自然合并。

## 典型场景
- 创建：
  1) 客户端 A 创建 tag/snippet → upsert op 入队 → 同步成功写服务端。
  2) 客户端 B 同步 → 拉取包含新增记录。
  3) 客户端 B 可继续创建，本地 upsert 入队，下一次同步推送。
- 删除：
  1) 客户端 A 删除 → 写 tombstone（deleted_at）并入队 delete op。
  2) 同步后服务端存墓碑。
  3) 客户端 B 同步 → 拉取墓碑，本地标记删除并从列表中消失。

## 客户端实现要点
- 删除/更新都走 upsert into 本地，然后入队 op；删除使用 `op=delete`。
- 同步时如果远端变更导致当前选中 tag/snippet 不存在，清空 UI 选中状态。
- `share` 接口拒绝分享已删除记录。

## 部署/迁移
- 数据库新增：`ALTER TABLE tags ADD COLUMN IF NOT EXISTS deleted_at timestamptz;`
- 确保后端镜像与客户端同时升级到新协议；老客户端需停止使用旧 sync 接口。

## 未决/可选优化
- 增加分页游标以支持超大变更批次（当前限制 200 条）。
- 增加“软冲突提示”（例如同一条记录短时间多端改名时提醒）。
