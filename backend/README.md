# fclipboard backend

FastAPI + Postgres 服务，提供认证、内容 CRUD、同步与导入导出接口，支持 Kubernetes 部署。

## 快速开始（本地）
1. 创建虚拟环境并安装依赖：
   ```bash
   cd backend
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```
2. 设置环境变量（或 `.env`）：
   ```
   DATABASE_URL=postgresql+psycopg2://user:pass@localhost:5432/fclipboard
   JWT_SECRET=change-me
   ACCESS_TOKEN_EXPIRE_MINUTES=30
   REFRESH_TOKEN_EXPIRE_DAYS=7
   CORS_ORIGINS=http://localhost:3000,http://localhost:5173
   ```
3. 启动服务：
   ```bash
   uvicorn app.main:app --reload
   ```

## 数据库迁移
- 使用 Alembic（未附完整迁移文件，可通过 `Base.metadata.create_all` 快速验证；生产请编写迁移并在 Helm Job 中执行）。

## 部署（Kubernetes）
- `deploy/helm` 提供基础 Chart。关键 values：
  - `image.repository`、`image.tag`
  - `env.databaseUrl`、`env.jwtSecret`、`env.accessTokenExpireMinutes`、`env.refreshTokenExpireDays`
  - `ingress.hosts`、`ingress.tls`
- 迁移可通过 `job-migrate.yaml` 模板执行 Alembic。
