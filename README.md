# connactions-app

App Flutter do ConnActions (Android primeiro). Design system, telas e decisões estão na spec de
arquitetura (pasta-mãe, `docs/superpowers/specs/`). O design original do Google Stitch está em
`docs/design/stitch/`.

## Rodar no dev

1. API de pé em `http://localhost:8090` (ver `connactions-api`)
2. Emulador: `flutter emulators --launch Pixel_9_Pro_XL`
3. `flutter run` (a URL da API em debug é `http://10.0.2.2:8090/v1`; outra: `--dart-define=API_URL=...`)

## Gate

`dart format --set-exit-if-changed .` · `dart analyze` · `flutter test`
