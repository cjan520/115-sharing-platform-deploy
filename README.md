# 115 影视资源共享平台安装说明

本仓库只用于安装部署，不包含项目源码。请先向管理员获取授权安装码。

## 安装

```bash
cp .env.example .env
```

编辑 `.env`，至少填写：

```env
POSTGRES_PASSWORD=数据库密码
JWT_SECRET=随机长字符串
LICENSE_CODE=授权安装码
```

默认后台账号：

```text
账号：admin
密码：admin123456
```

首次登录后建议立即在后台修改默认密码。

启动：

```bash
docker compose up -d
```

访问：

- 管理后台：`http://群晖IP:5115`
- 会员中心：`http://群晖IP:5116`
- 后端接口：`http://群晖IP:8115`

## 更新

```bash
docker compose pull
docker compose up -d
```

## 说明

- 本安装包只拉取 Docker 镜像运行，不需要源码。
- 授权码由管理员发放，未填写或校验失败时业务容器不会启动。
- 数据、日志、授权设备信息会保存在当前目录的 `data/` 和 `backups/` 中。
