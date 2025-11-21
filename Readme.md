# Node.js Build Docker Image

一个专注于 Node.js 编译与运行的精简镜像，完全移除了 Android/Python/Java 依赖，满足“只编译 Node.js”的需求。

## ✅ What's Included

- Node.js 18（基于 `node:18-bullseye` 官方镜像）
- build-essential（gcc、g++、make），方便编译原生依赖
- git、ca-certificates 等常用 CLI 工具

## 🚀 使用方式

```bash
# 构建镜像
docker build -t node18-build:latest .

# 运行容器并挂载当前工程
docker run --rm -it -v ${PWD}:/workspace node18-build:latest bash
```

## 🧭 设计原则

- **KISS / YAGNI**：仅保留 Node.js + 必备依赖，镜像层级清晰。
- **SOLID / DRY**：镜像职责单一，便于扩展到其他项目；无多余脚本与重复安装命令。
