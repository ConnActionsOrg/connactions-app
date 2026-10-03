package app.connactions_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        criarCanais()
        // o canal e o método casam com o NotificadorFirebase, em lib/app/notificador.dart
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "connactions/notificacoes")
            .setMethodCallHandler { chamada, resultado ->
                if (chamada.method == "abrirConfiguracoes") {
                    startActivity(intentDasConfiguracoes())
                    resultado.success(null)
                } else {
                    resultado.notImplemented()
                }
            }
    }

    // Os ids são o canal que a API manda em cada mensagem. Recriar a cada abertura não desfaz o
    // ajuste da pessoa: num canal que já existe a importância só desce (e só se ela não mexeu).
    private fun criarCanais() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val canais = listOf(
            NotificationChannel("sua_vez", "Sua vez", NotificationManager.IMPORTANCE_HIGH)
                .apply { description = "Quando chega a sua vez de propor" },
            NotificationChannel("atividades", "Atividades novas", NotificationManager.IMPORTANCE_DEFAULT)
                .apply { description = "Quando alguém da turma lança uma atividade" },
            NotificationChannel("registros", "Registros", NotificationManager.IMPORTANCE_LOW)
                .apply { description = "Quando alguém posta um registro" },
            NotificationChannel("prazos", "Prazos", NotificationManager.IMPORTANCE_DEFAULT)
                .apply { description = "No último dia do prazo de uma atividade" },
        )
        getSystemService(NotificationManager::class.java).createNotificationChannels(canais)
    }

    private fun intentDasConfiguracoes(): Intent =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.fromParts("package", packageName, null),
            )
        }
}
