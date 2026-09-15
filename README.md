# grw_laser

GRW Laser Robot - Saga.

## iOS: Swift Package Manager

Le dipendenze native iOS sono gestite con Swift Package Manager, abilitato nel
`pubspec.yaml`. CocoaPods non è necessario. Usare Flutter 3.44 o successivo;
migrazione verificata con Flutter 3.47.4 e Xcode 27.

```sh
flutter pub get
flutter build ios --simulator --debug
```

Per lavorare in Xcode, aprire `ios/Runner.xcworkspace`. Dopo un `flutter clean`,
eseguire `flutter pub get` e `flutter build ios --config-only --no-codesign`
prima di aprire Xcode, così Flutter rigenera i pacchetti locali.

- `flutter_inappwebview` e `flutter_secure_storage` sono stati rimossi perché
  non usati dal codice dell'app.
- `volume_controller` usa la serie 3.5 con supporto SPM. Il vincolo `<3.6.0`
  evita di richiedere anche la migrazione Android ad AGP 9 / Kotlin integrato.
- `flutter_tts` usa una copia locale della versione 4.2.5 con supporto SPM iOS.
  Origine, modifiche e istruzioni per tornare al pacchetto pubblicato sono in
  [packages/flutter_tts/LOCAL_CHANGES.md](packages/flutter_tts/LOCAL_CHANGES.md).

Quando si aggiungono plugin iOS, verificarne il supporto SPM per evitare che
Flutter debba ricorrere nuovamente a CocoaPods.
