# connactions-app

App Flutter do ConnActions (Android primeiro). Design system, telas e decisões estão na spec de
arquitetura (pasta-mãe, `docs/superpowers/specs/`). O design original do Google Stitch está em
`docs/design/stitch/`.

## Rodar no dev

1. API de pé em `http://localhost:8090` (ver `connactions-api`)
2. Emulador: `flutter emulators --launch Pixel_9_Pro_XL`
3. `flutter run` (a URL da API em debug é `http://10.0.2.2:8090/v1`, o host visto de dentro do emulador; outra: `--dart-define=API_URL=...`)

## Celular físico (depuração sem fio)

`10.0.2.2` só existe no emulador. No aparelho, a API do PC chega por `adb reverse`:

1. No celular: Opções do desenvolvedor → Depuração por Wi-Fi → "Parear dispositivo com código".
2. No PC: `adb pair <ip:porta> <código>`; depois `adb mdns services` mostra a porta de conexão e
   `adb connect <ip:porta>` conecta.
3. `adb reverse tcp:8090 tcp:8090` (funciona também pela depuração sem fio; sem firewall nem IP da LAN).
4. `flutter run -d <ip:porta> --dart-define=API_URL=http://127.0.0.1:8090/v1`. Para não pagar o
   Gradle a cada vez: `flutter build apk --debug --dart-define=API_URL=http://127.0.0.1:8090/v1`
   uma vez e depois `flutter run -d <ip:porta> --use-application-binary=build\app\outputs\flutter-apk\app-debug.apk`.

O SHA-1 registrado no Firebase é o do keystore de debug do PC, então o login com Google vale em
qualquer aparelho. "Fechar pelos recentes" no Samsung não mata o processo: para provar
persistência, `adb shell am force-stop app.connactions` e reabrir pelo launcher.

## Gate

`dart format --set-exit-if-changed .` · `dart analyze` · `flutter test`
