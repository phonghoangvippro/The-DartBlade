package com.darkblade.the_darkblade

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // A stable 60 Hz avoids sustained 90/120 Hz rendering heating the
        // device until Android thermally throttles both CPU and GPU.
        window.attributes = window.attributes.apply {
            preferredRefreshRate = 60f
        }
    }
}
