#include <jni.h>
#include <string>
#include <android/log.h>
#include <node.h>
#include <node_version.h>
#include <v8.h>
#include <libplatform/libplatform.h>
#include <uv.h>
#include <mutex>

#define LOG_TAG "NodeJS"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// V8 平台单例管理
class V8Manager {
private:
    static V8Manager* instance;
    static std::mutex mutex;
    std::unique_ptr<v8::Platform> platform;
    bool initialized;

    V8Manager() : initialized(false) {}

public:
    static V8Manager* getInstance() {
        std::lock_guard<std::mutex> lock(mutex);
        if (instance == nullptr) {
            instance = new V8Manager();
        }
        return instance;
    }

    void initialize() {
        std::lock_guard<std::mutex> lock(mutex);
        if (!initialized) {
            LOGI("Initializing V8 platform...");
            platform = v8::platform::NewDefaultPlatform();
            v8::V8::InitializePlatform(platform.get());
            v8::V8::Initialize();
            initialized = true;
            LOGI("V8 platform initialized successfully");
        }
    }

    bool isInitialized() const {
        return initialized;
    }
};

V8Manager* V8Manager::instance = nullptr;
std::mutex V8Manager::mutex;

extern "C" JNIEXPORT jstring JNICALL
Java_com_wuxianggujun_android_1nodejs_1embed_MainActivity_stringFromJNI(
        JNIEnv* env,
        jobject /* this */) {
    std::string hello = "Hello from C++";
    LOGI("%s", hello.c_str());
    return env->NewStringUTF(hello.c_str());
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_wuxianggujun_android_1nodejs_1embed_MainActivity_getNodeVersion(
        JNIEnv* env,
        jobject /* this */) {
    // 直接使用宏定义的版本号
    std::string version = "Node.js v";
    version += std::to_string(NODE_MAJOR_VERSION);
    version += ".";
    version += std::to_string(NODE_MINOR_VERSION);
    version += ".";
    version += std::to_string(NODE_PATCH_VERSION);
    
    LOGI("Node.js version: %s", version.c_str());
    return env->NewStringUTF(version.c_str());
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_wuxianggujun_android_1nodejs_1embed_MainActivity_runJavaScript(
        JNIEnv* env,
        jobject /* this */,
        jstring jsCode) {
    
    const char* code = env->GetStringUTFChars(jsCode, nullptr);
    LOGI("Running JavaScript: %s", code);
    
    std::string result;
    
    try {
        // 确保 V8 平台已初始化（只初始化一次）
        V8Manager* v8Manager = V8Manager::getInstance();
        v8Manager->initialize();
        
        // 创建 Isolate（每次执行创建新的）
        v8::Isolate::CreateParams create_params;
        create_params.array_buffer_allocator =
            v8::ArrayBuffer::Allocator::NewDefaultAllocator();
        v8::Isolate* isolate = v8::Isolate::New(create_params);
        
        {
            v8::Isolate::Scope isolate_scope(isolate);
            v8::HandleScope handle_scope(isolate);
            
            // 创建上下文
            v8::Local<v8::Context> context = v8::Context::New(isolate);
            v8::Context::Scope context_scope(context);
            
            // 编译并运行 JavaScript
            v8::Local<v8::String> source =
                v8::String::NewFromUtf8(isolate, code, v8::NewStringType::kNormal)
                    .ToLocalChecked();
            
            v8::TryCatch try_catch(isolate);
            v8::Local<v8::Script> script;
            if (!v8::Script::Compile(context, source).ToLocal(&script)) {
                v8::String::Utf8Value error(isolate, try_catch.Exception());
                result = std::string("Compile error: ") + *error;
            } else {
                v8::Local<v8::Value> result_value;
                if (!script->Run(context).ToLocal(&result_value)) {
                    v8::String::Utf8Value error(isolate, try_catch.Exception());
                    result = std::string("Runtime error: ") + *error;
                } else {
                    v8::String::Utf8Value utf8(isolate, result_value);
                    result = std::string(*utf8);
                }
            }
        }
        
        // 清理 Isolate（但不清理平台）
        isolate->Dispose();
        delete create_params.array_buffer_allocator;
        
    } catch (const std::exception& e) {
        result = std::string("Exception: ") + e.what();
        LOGE("Exception: %s", e.what());
    }
    
    env->ReleaseStringUTFChars(jsCode, code);
    
    LOGI("JavaScript result: %s", result.c_str());
    return env->NewStringUTF(result.c_str());
}

// 新增：使用完整 Node.js 环境运行代码（简化版本）
extern "C" JNIEXPORT jstring JNICALL
Java_com_wuxianggujun_android_1nodejs_1embed_MainActivity_runNodeJS(
        JNIEnv* jenv,
        jobject /* this */,
        jstring jsCode) {
    
    const char* code = jenv->GetStringUTFChars(jsCode, nullptr);
    LOGI("Running Node.js code: %s", code);
    
    std::string result = "完整 Node.js 环境集成较复杂\n\n";
    result += "当前 libnode.so 包含:\n";
    result += "✅ V8 引擎 (已可用)\n";
    result += "✅ libuv 事件循环\n";
    result += "✅ Node.js 核心 API\n";
    result += "✅ 所有内置模块 (fs, http, crypto 等)\n\n";
    result += "要使用完整 Node.js 需要:\n";
    result += "1. 正确初始化 Node.js 环境\n";
    result += "2. 配置文件系统访问\n";
    result += "3. 处理事件循环\n\n";
    result += "当前可用: V8 JavaScript 执行 (runJavaScript 方法)";
    
    jenv->ReleaseStringUTFChars(jsCode, code);
    
    LOGI("Node.js info: %s", result.c_str());
    return jenv->NewStringUTF(result.c_str());
}
