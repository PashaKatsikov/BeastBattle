package com.beastbattle.beast_battle

import android.app.Activity
import android.content.Intent
import android.content.res.Configuration
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val bridge = "beastpit/pick"
    private val rim = "beastpit/rim"
    private val requestCode = 0x2A6E
    private var pending: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        seatKeyboard()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        seatKeyboard()
    }

    // The window stays put. IME height still arrives as an inset, and the
    // page shifts its own field instead of the WebView being resized.
    private fun seatKeyboard() {
        window.setDecorFitsSystemWindows(false)
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, bridge)
            .setMethodCallHandler { call, result ->
                if (call.method == "grab") {
                    val multi = call.argument<Boolean>("multi") ?: false
                    val kinds = call.argument<List<String>>("kinds") ?: emptyList()
                    openPicker(multi, kinds, result)
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, rim)
            .setMethodCallHandler { call, result ->
                if (call.method == "read") {
                    val cut = window.decorView.rootWindowInsets?.displayCutout
                    result.success(
                        mapOf(
                            "left" to (cut?.safeInsetLeft ?: 0),
                            "top" to (cut?.safeInsetTop ?: 0),
                            "right" to (cut?.safeInsetRight ?: 0),
                            "bottom" to (cut?.safeInsetBottom ?: 0),
                        ),
                    )
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun openPicker(
        multi: Boolean,
        kinds: List<String>,
        result: MethodChannel.Result,
    ) {
        pending?.success(emptyList<String>())
        pending = result
        val usable = kinds.filter { it.contains("/") }
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, multi)
            when {
                usable.isEmpty() -> type = "*/*"
                usable.size == 1 -> type = usable[0]
                else -> {
                    type = "*/*"
                    putExtra(Intent.EXTRA_MIME_TYPES, usable.toTypedArray())
                }
            }
        }
        try {
            startActivityForResult(Intent.createChooser(intent, null), requestCode)
        } catch (_: Exception) {
            pending = null
            result.success(emptyList<String>())
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != this.requestCode) return
        val reply = pending
        pending = null
        if (reply == null) return
        if (resultCode != Activity.RESULT_OK || data == null) {
            reply.success(emptyList<String>())
            return
        }
        val uris = ArrayList<String>()
        val clip = data.clipData
        if (clip != null) {
            for (i in 0 until clip.itemCount) {
                uris.add(clip.getItemAt(i).uri.toString())
            }
        } else {
            data.data?.let { uris.add(it.toString()) }
        }
        reply.success(uris)
    }
}
