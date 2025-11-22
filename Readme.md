# Node.js Android Cross-Compilation Builder

> **献给我的好友影子** 🎉  
> 于 2025年11月23日，历经一天的编译调试，成功完成 Node.js 在 Android 平台的交叉编译。

This Docker image cross-compiles Node.js from source for Android (ARM64) with the `--shared` flag, generating `libnode.so` for embedding in Android applications.

## 项目简介 | Project Overview

本项目提供了一个完整的 Docker 构建环境，用于将 Node.js 交叉编译到 Android 平台。经过测试，**Node.js v20.11.0** 可以成功编译并在 Android 33 (API Level 33) 上正常运行。

**主要特性：**
- ✅ 已测试并验证：Node.js v20.11.0 在 Android ARM64 平台正常工作
- ✅ 生成优化的 libnode.so 共享库（约 54 MB）
- ✅ 包含完整的 Android 示例项目（`androidnodejsembed` 目录）
- ✅ 支持在 Android 应用中嵌入和运行 JavaScript 代码

**Key Features:**
- ✅ Tested and verified: Node.js v20.11.0 works on Android ARM64
- ✅ Generates optimized libnode.so shared library (~54 MB)
- ✅ Includes complete Android example project (`androidnodejsembed` directory)
- ✅ Supports embedding and running JavaScript in Android apps

## What's Included

- Debian bookworm base with minimal tooling
- Android NDK r26d for cross-compilation
- build-essential, git, python3, pkg-config, curl, ca-certificates, ccache
- Cross-compiled Node.js (v20.11.0 by default) for Android ARM64
- Optimized `libnode.so` (~54 MB) output to `/output/` directory

## Quick Start (Windows)

使用提供的批处理脚本：

```bash
# 首次运行会自动构建镜像并启动容器（需要 30-60 分钟）
.\run-container.bat

# 导出编译好的 libnode.so 到当前目录
.\run-container.bat export

# 查看帮助
.\run-container.bat help
```

## Manual Build and Run

```bash
# Build the image (optionally override parameters)
docker build -t node18-build:latest \
  --build-arg NODE_VERSION=20.11.0 \
  --build-arg NDK_VERSION=r26d \
  --build-arg ANDROID_API=33 \
  --build-arg TARGET_ARCH=arm64-v8a .

# Start a container with your project mounted to /workspace
docker run --rm -it -v ${PWD}:/workspace node18-build:latest bash
```

## Exporting `libnode.so`

```bash
# Copy libnode.so to the host workspace
docker run --rm -v ${PWD}:/workspace node18-build:latest \
  bash -c 'cp /output/libnode.so /workspace/'
```

## Build Arguments

- `NODE_VERSION`: Node.js version to compile (default: 20.11.0)
- `NDK_VERSION`: Android NDK version (default: r26d)
- `ANDROID_API`: Android API level (default: 33)
- `TARGET_ARCH`: Target architecture (default: arm64-v8a)
- `DEBIAN_MIRROR`: Debian package mirror (default: http://mirrors.aliyun.com/debian)
- `DEBIAN_SECURITY_MIRROR`: Debian security mirror

## Optimization Features

### Build Optimizations
- **ccache**: Caches compilation results for faster rebuilds
- **Parallel compilation**: Uses all available CPU cores
- **Size optimization**: `-Os` compiler flag for smaller binaries
- **Dead code elimination**: `-fdata-sections -ffunction-sections` + `--gc-sections`
- **Symbol stripping**: `llvm-strip` removes debug symbols

### Node.js Configuration
- `--shared`: Generate shared library (libnode.so)
- `--dest-cpu=arm64`: Target ARM64 architecture
- `--dest-os=android`: Target Android OS
- `--cross-compiling`: Enable cross-compilation mode
- `--without-intl`: Disable internationalization
- `--without-inspector`: Disable V8 inspector
- `--without-npm`: Remove npm
- `--without-corepack`: Remove corepack
- `--without-node-code-cache`: Skip code cache generation
- `--without-node-snapshot`: Skip snapshot generation (faster build)
- `--without-node-options`: Remove CLI options parsing
- `--without-report`: Remove diagnostic reports
- `--openssl-no-asm`: Disable OpenSSL assembly optimizations

## Output

- **File**: `libnode.so`
- **Size**: ~54 MB (after strip)
- **Platform**: Android ARM64 (arm64-v8a)
- **API Level**: 33
- **Node.js Version**: 20.11.0

## 在 Android 中使用 | Usage in Android

### 完整示例项目 | Complete Example

本仓库包含一个完整的 Android 示例项目，位于 `androidnodejsembed` 目录：

```bash
# 打开 Android Studio 并导入项目
cd androidnodejsembed
# 或直接用 Android Studio 打开 androidnodejsembed 目录
```

**示例项目包含：**
- ✅ 预编译的 libnode.so（已放置在 `app/src/main/jniLibs/arm64-v8a/`）
- ✅ JNI 接口实现
- ✅ Kotlin/Java 调用示例
- ✅ 完整的构建配置

### 手动集成步骤 | Manual Integration

### 1. 放置库文件到 Android 项目
```
app/src/main/jniLibs/arm64-v8a/libnode.so
```

### 2. 通过 JNI 在 C++ 中加载
```cpp
#include <node.h>

extern "C" JNIEXPORT void JNICALL
Java_com_example_MyApp_runJS(JNIEnv* env, jobject, jstring jsCode) {
    // 初始化并运行 JavaScript
    // Initialize and run JavaScript
}
```

### 3. 从 Kotlin/Java 调用
```kotlin
class MyApp {
    external fun runJS(code: String)
    
    companion object {
        init {
            System.loadLibrary("node")
        }
    }
}
```

### 运行示例 | Run Example
```kotlin
// 在 Android 应用中运行 JavaScript
val app = MyApp()
app.runJS("console.log('Hello from Node.js on Android!')")
```

## Size Reduction Tips

### Compression (Recommended)
Compress `libnode.so` and decompress at runtime:
- Original: ~54 MB
- Compressed (xz/7z): ~15-18 MB (65-70% reduction)

### Further Optimization
Add `--without-ssl` to remove OpenSSL (saves 10-15 MB):
- ⚠️ Disables HTTPS, TLS, and crypto module
- Only suitable if you don't need encryption

## Build Time

- **First build**: 30-60 minutes (depending on CPU)
- **Rebuild with cache**: 5-10 minutes (if only small changes)
- **Export only**: < 5 seconds

## Design Principles

- **KISS / YAGNI**: Only install packages required for cross-compilation
- **SOLID**: Single responsibility (cross-compile Node.js for Android)
- **DRY**: Build parameters captured as ARG/ENV pairs
