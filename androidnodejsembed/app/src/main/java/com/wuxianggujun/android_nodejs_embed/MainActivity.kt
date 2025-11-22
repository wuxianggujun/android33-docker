package com.wuxianggujun.android_nodejs_embed

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.wuxianggujun.android_nodejs_embed.ui.theme.AndroidnodejsembedTheme

class MainActivity : ComponentActivity() {
    
    companion object {
        init {
            System.loadLibrary("androidnodejsembed")
        }
    }
    
    // 声明 native 方法
    external fun stringFromJNI(): String
    external fun getNodeVersion(): String
    external fun runJavaScript(code: String): String
    external fun runNodeJS(code: String): String
    
    // 简单的 TypeScript 到 JavaScript "编译器"（实际上是去除类型注解）
    private fun simpleTypeScriptCompile(tsCode: String): String {
        return tsCode
            // 移除类型注解 : type
            .replace(Regex(""":\s*\w+(\[\])?"""), "")
            // 移除接口定义
            .replace(Regex("""interface\s+\w+\s*\{[^}]*\}"""), "")
            // 移除类型别名
            .replace(Regex("""type\s+\w+\s*=\s*[^;]+;"""), "")
            // const 改为 var (V8 兼容性更好)
            .replace("const ", "var ")
            .trim()
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        
        // 测试 JNI 调用
        try {
            val cppMessage = stringFromJNI()
            val nodeVersion = getNodeVersion()
            Log.i("MainActivity", "C++ Message: $cppMessage")
            Log.i("MainActivity", "Node.js Version: $nodeVersion")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error calling native methods", e)
        }
        
        setContent {
            AndroidnodejsembedTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    NodeJSDemo(
                        modifier = Modifier.padding(innerPadding),
                        onGetVersion = { getNodeVersion() },
                        onRunJS = { code -> runJavaScript(code) },
                        onRunNodeJS = { code -> runNodeJS(code) },
                        simpleTypeScriptCompile = { ts -> simpleTypeScriptCompile(ts) }
                    )
                }
            }
        }
    }
}

@Composable
fun NodeJSDemo(
    modifier: Modifier = Modifier,
    onGetVersion: () -> String = { "N/A" },
    onRunJS: (String) -> String = { "N/A" },
    onRunNodeJS: (String) -> String = { "N/A" },
    simpleTypeScriptCompile: (String) -> String = { it }
) {
    var result by remember { mutableStateOf("点击按钮测试 Node.js") }
    
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterVertically)
    ) {
        Text(text = result)
        
        Button(onClick = {
            result = try {
                "Node.js 版本: ${onGetVersion()}"
            } catch (e: Exception) {
                "错误: ${e.message}"
            }
        }) {
            Text("获取 Node.js 版本")
        }
        
        Button(onClick = {
            result = try {
                val jsCode = "1 + 2 + 3"
                "执行 '$jsCode' = ${onRunJS(jsCode)}"
            } catch (e: Exception) {
                "错误: ${e.message}"
            }
        }) {
            Text("运行 JavaScript")
        }
        
        Button(onClick = {
            result = try {
                val jsCode = "'Hello from ' + 'Node.js!'"
                "结果: ${onRunJS(jsCode)}"
            } catch (e: Exception) {
                "错误: ${e.message}"
            }
        }) {
            Text("运行字符串拼接")
        }
        
        Button(onClick = {
            result = try {
                // TypeScript 代码示例（会失败）
                val tsCode = """
                    const greeting: string = "Hello TypeScript";
                    const add = (a: number, b: number): number => a + b;
                    greeting + " " + add(10, 20)
                """.trimIndent()
                "直接运行 TS（会失败）:\n${onRunJS(tsCode)}"
            } catch (e: Exception) {
                "预期的错误: ${e.message}"
            }
        }) {
            Text("❌ 直接运行 TypeScript")
        }
        
        Button(onClick = {
            result = try {
                // TypeScript 代码
                val tsCode = """
                    const greeting: string = "Hello TypeScript";
                    const add = (a: number, b: number): number => a + b;
                    greeting + " Result: " + add(10, 20)
                """.trimIndent()
                
                // "编译" TypeScript（去除类型注解）
                val compiledJS = simpleTypeScriptCompile(tsCode)
                
                "原始 TS:\n$tsCode\n\n编译后:\n$compiledJS\n\n执行结果:\n${onRunJS(compiledJS)}"
            } catch (e: Exception) {
                "错误: ${e.message}"
            }
        }) {
            Text("✅ 简单编译 + 运行 TS")
        }
        
        Button(onClick = {
            result = try {
                // 编译后的 JavaScript（从 TypeScript 编译而来）
                val compiledJS = """
                    var greeting = "Hello from compiled TS";
                    var add = function(a, b) { return a + b; };
                    greeting + " Result: " + add(15, 25)
                """.trimIndent()
                "编译后的 TS (JS):\n${onRunJS(compiledJS)}"
            } catch (e: Exception) {
                "错误: ${e.message}"
            }
        }) {
            Text("运行编译后的 TS")
        }
        
        Button(onClick = {
            result = try {
                val nodeCode = "typeof require !== 'undefined' ? 'require 可用!' : 'require 不可用'"
                "Node.js 环境检查:\n${onRunNodeJS(nodeCode)}"
            } catch (e: Exception) {
                "错误: ${e.message}"
            }
        }) {
            Text("🔍 检查 Node.js 环境")
        }
        
        Button(onClick = {
            result = try {
                val nodeCode = "process.version"
                "Node.js process.version:\n${onRunNodeJS(nodeCode)}"
            } catch (e: Exception) {
                "错误: ${e.message}"
            }
        }) {
            Text("📦 测试 process 对象")
        }
        
        Button(onClick = {
            result = try {
                val nodeCode = """
                    const os = require('os');
                    'Platform: ' + os.platform() + ', Arch: ' + os.arch()
                """.trimIndent()
                "Node.js require('os'):\n${onRunNodeJS(nodeCode)}"
            } catch (e: Exception) {
                "错误: ${e.message}"
            }
        }) {
            Text("🚀 测试 require('os')")
        }
        
        Button(onClick = {
            result = try {
                val nodeCode = """
                    const modules = ['fs', 'path', 'http', 'crypto', 'util', 'events'];
                    const available = modules.filter(m => {
                        try { require(m); return true; } catch(e) { return false; }
                    });
                    'Available: ' + available.join(', ')
                """.trimIndent()
                "内置模块检查:\n${onRunNodeJS(nodeCode)}"
            } catch (e: Exception) {
                "错误: ${e.message}"
            }
        }) {
            Text("📋 检查内置模块")
        }
        
        Button(onClick = {
            result = try {
                val nodeCode = """
                    const config = process.config;
                    'Node configured with:\n' +
                    'npm: ' + (config.variables.node_install_npm || 'unknown') + '\n' +
                    'intl: ' + (config.variables.icu_small || 'unknown')
                """.trimIndent()
                "编译配置:\n${onRunNodeJS(nodeCode)}"
            } catch (e: Exception) {
                "错误: ${e.message}"
            }
        }) {
            Text("⚙️ 查看编译配置")
        }
    }
}

@Preview(showBackground = true)
@Composable
fun NodeJSDemoPreview() {
    AndroidnodejsembedTheme {
        NodeJSDemo()
    }
}