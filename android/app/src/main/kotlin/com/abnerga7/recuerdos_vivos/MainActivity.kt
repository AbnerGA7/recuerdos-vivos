package com.abnerga7.recuerdos_vivos

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "recuerdos/recursos")
            .setMethodCallHandler { llamada, respuesta ->
                if (llamada.method != "copiarAsset") {
                    respuesta.notImplemented()
                    return@setMethodCallHandler
                }
                val asset = llamada.argument<String>("asset")
                val destino = llamada.argument<String>("destino")
                if (asset == null || destino == null) {
                    respuesta.error("argumentos", "Faltan la ruta del recurso o el destino.", null)
                    return@setMethodCallHandler
                }
                // Copia por trozos, en otro hilo: no carga el archivo entero en memoria.
                Thread {
                    try {
                        assets.open("flutter_assets/$asset").use { entrada ->
                            File(destino).outputStream().use { salida ->
                                entrada.copyTo(salida, 1 shl 16)
                            }
                        }
                        runOnUiThread { respuesta.success(true) }
                    } catch (e: Exception) {
                        runOnUiThread { respuesta.error("copia", e.message, null) }
                    }
                }.start()
            }
    }
}
