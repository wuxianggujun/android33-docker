@echo off
setlocal enabledelayedexpansion

REM 检查命令参数
if "%1"=="export" goto :export
if "%1"=="help" goto :help
if "%1"=="-h" goto :help
if "%1"=="--help" goto :help
if not "%1"=="" (
    echo 未知参数: %1
    echo 使用 run-container.bat help 查看帮助
    exit /b 1
)

:check_image
echo 检查镜像是否存在...
docker images -q node18-build:latest > nul 2>&1
docker images node18-build:latest | findstr "node18-build" > nul

if %errorlevel% neq 0 (
    echo.
    echo ========================================
    echo 镜像不存在，开始首次构建...
    echo 这可能需要几分钟时间
    echo ========================================
    echo.
    docker build -t node18-build:latest .
    
    if !errorlevel! neq 0 (
        echo.
        echo 构建失败，请检查错误信息
        pause
        exit /b 1
    )
    
    echo.
    echo ========================================
    echo 镜像构建成功！
    echo ========================================
    echo.
) else (
    echo 镜像已存在...
)

echo.
echo 启动容器并挂载当前目录到 /workspace...
echo 提示: 在容器内可以访问 /workspace 目录
echo.
docker run --rm -it -v %cd%:/workspace node18-build:latest bash
exit /b 0

:export
echo 检查镜像是否存在...
docker images node18-build:latest | findstr "node18-build" > nul
if %errorlevel% neq 0 (
    echo 镜像不存在，请先运行 run-container.bat 构建镜像
    exit /b 1
)

echo.
echo 正在从容器中导出 libnode.so 和头文件...
docker run --rm -v %cd%:/workspace node18-build:latest bash -c "cp /output/lib/libnode.so /workspace/ && cp -r /output/include /workspace/"

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo libnode.so 和头文件已成功导出到当前目录
    echo ========================================
    dir libnode.so 2>nul
    echo.
    echo 头文件位置: include\node\
) else (
    echo 导出失败，请检查错误信息
    exit /b 1
)
exit /b 0

:help
echo.
echo ========================================
echo Node.js 共享库构建工具
echo ========================================
echo.
echo 用法:
echo   run-container.bat          启动容器（首次会自动构建镜像）
echo   run-container.bat export   导出 libnode.so 到当前目录
echo   run-container.bat help     显示此帮助信息
echo.
echo 示例:
echo   run-container.bat          # 进入容器进行开发
echo   run-container.bat export   # 导出编译好的 libnode.so
echo.
exit /b 0
