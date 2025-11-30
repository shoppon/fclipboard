# fclipboard 设计文档

## 架构与技术选型
- 前端：Flutter 3.x（桌面 + Web），状态管理 Riverpod，路由 GoRouter。桌面使用 sqflite + FTS5；Web 使用 sqflite_common_ffi_web + LIKE/轻量评分。依赖注入与存储、API、同步层分离。
- 后端：FastAPI + SQLAlchemy + Alembic + Postgres；JWT/Refresh（python-jose + passlib）；OpenAPI 自动生成客户端；Gunicorn/Uvicorn behind Nginx；Kubernetes 部署，Helm 管理。
- 部署：K8s（Deployment/Service/Ingress），Postgres StatefulSet/外部托管，ConfigMap/Secret 注入，镜像 buildx；迁移由 InitContainer/Job 运行 Alembic。

## 模块划分（前端）
- App Shell：主题、路由、依赖注册。
- Auth：注册/登录/刷新/重置；token 与会话存储。
- Content：条目列表/详情/编辑器、置顶/最近使用、导入导出、参数化表单。
- Search：查询接口抽象；桌面实现 FTS5，Web 用 LIKE + 评分；过滤/排序统一接口。
- Sync：本地 SQLite 为主；写入入 sync 队列；定时/事件推送与拉取；冲突策略与状态提示。
- Settings：快捷键、同步间隔、默认过滤等。
- Platform：剪贴板、全局快捷键（桌面），Web 提供降级替代。

## 模块划分（后端）
- Auth Service：注册/登录/刷新/重置；密码哈希（bcrypt）；角色校验。
- Entry Service：CRUD、分页、增量（updatedAfter）、冲突检测（version/updatedAt）；导入/导出 JSON/CSV；parameters 存储。
- Category Service：CRUD、增量同步。
- Sync：entries/categories 批量同步接口；增量与冲突副本（conflictOf）。
- Admin：用户管理（列表/禁用/重置）。
- Infra：数据库会话、设置、日志、CORS、依赖注入。

## 数据模型（核心字段）
- User：id, email, password_hash, role, created_at, updated_at, is_active, reset_token(opt).
- Entry：id, user_id, title, body, tags (string[]/json), source, pinned, parameters(json), created_at, updated_at, version, deleted_at(opt), conflict_of(opt), category_id(opt).
- Category：id, user_id, name, color, version, created_at, updated_at.
- RefreshToken：jti, user_id, expires_at, revoked.
- 用户偏好（可选）：默认排序/过滤、快捷键、syncEnabled。

## 关键流程
- 搜索：本地索引查询 -> 过滤 -> 排序 -> 渲染；无网可用。
- 编辑：本地事务 -> 更新 version/updatedAt -> 入 pending 队列 -> UI 即时更新 -> 后台同步；冲突保留副本。
- 同步：定时/事件触发；上传 pending（create/update/delete）；拉取 updatedAfter；失败指数退避；本地 SQLite 永远可用。
- Auth：登录获取 access/refresh；刷新；登出撤销 refresh。

## API 设计（示例）
- Auth：POST /auth/register | /auth/login | /auth/refresh | /auth/reset/request | /auth/reset/confirm
- Entries：GET /entries?updatedAfter&limit&cursor；POST /entries；PUT /entries/{id}；PATCH /entries/{id}/pin；DELETE /entries/{id}；POST /entries/sync
- Categories：GET /categories?updatedAfter&limit；POST /categories；PUT /categories/{id}；DELETE /categories/{id}；POST /categories/sync
- Bulk：POST /entries/import (json/csv)；GET /entries/export?format=json|csv

## 部署/配置要点
- 环境变量：DATABASE_URL、JWT_SECRET、ACCESS_TOKEN_EXPIRE_MINUTES、REFRESH_TOKEN_EXPIRE_DAYS、CORS_ORIGINS、LOG_LEVEL。
- Helm values：镜像仓库/tag、副本数、资源、ingress host/TLS、Postgres 连接、迁移 Job/InitContainer，可选 storageClass。
- CI/CD：构建多平台镜像，推送；部署 helm upgrade --install；迁移自动执行。

## 测试策略
- 前端：单元（搜索/过滤、use cases）、集成（SQLite/FTS、同步队列）、widget/golden（搜索、编辑、冲突提示）。
- 后端：单元（service/repo）、集成（API + Postgres + 迁移）、契约（OpenAPI 生成客户端验证）。
- E2E：注册→登录→创建→搜索→同步。

## UI 方向
- 布局：左侧列表 + 顶部搜索栏 + 右侧详情/编辑；标签过滤条；桌面全局快捷键唤起，Web 提供显著复制/聚焦按钮。
- 视觉：简洁浅色为主，暗色可选；清晰层次与对比，留白充足；强调可达性与键盘操作。
