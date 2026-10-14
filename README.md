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

## Fotos

Registros e foto do perfil saem do `image_picker` (câmera ou galeria, sem permissão de manifesto no
Android) já em 1600px, e a API normaliza e serve em `/midia`. No celular físico as URLs vêm em
`127.0.0.1:8090`, que o `adb reverse` resolve; no emulador a API precisa de
`MIDIA_BASE_URL=http://10.0.2.2:8090/midia` no `.env`.

## Backlog e Comunidade

O Feed tem o cartão "Backlog de ideias" (as minhas ideias livres, "N/5"). A tela do backlog guarda as
ideias da turma, até 5 livres por pessoa, e quem está na vez as propõe. O Propor tem três abinhas:
"Do zero", "Backlog" e "Comunidade"; escolher uma origem preenche o formulário, a origem vai na
proposta (`origem_ideia_id` ou `origem_atividade_id`) e aparece como chip acima do título ("Sua
ideia", "Ideia de Carol" ou "Da Comunidade · 🍕 Turma Prova"), que o ✕ desfaz sem perder o texto.

A aba Comunidade lista as atividades públicas e encerradas de outras turmas, sem nenhuma pessoa:
só o nome e o emoji da turma, as fotos com legenda e "N turmas se inspiraram". A pílula do topo
escolhe a turma que recebe o que se salva e de onde se propõe; sem turma, dá para ler e não agir.

## Diário: reações, comentários e capa

O Diário da turma abre com a capa: o título, a frase, o sticker e a paleta (qualquer membro troca pelo lápis) e os contadores de atividades e de fotos. Cada atividade encerrada tem, embaixo, as reações (seis tipos, vários por pessoa; tocar de novo desmarca) e o balão dos comentários, que abre uma folha com o campo para escrever. Reação e comentário só valem em atividade encerrada e só para membros; o app mostra quantos reagiram, não quem. A reação muda na hora e volta sozinha se a API recusar.

## Gate

`dart format --set-exit-if-changed .` · `dart analyze` · `flutter test`
