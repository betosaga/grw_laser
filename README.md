# grw_laser

GRW Laser Robot - Saga.

## Android

Richiede Flutter 3.47 o successivo. La build usa Gradle 9.1.0, Android Gradle
Plugin 9.0.1 e Kotlin integrato (`android.builtInKotlin=true`), anche per il
plugin locale `flutter_tts`.
La dichiarazione Kotlin 2.3.20 con `apply false` in `settings.gradle.kts`
seleziona la versione del compilatore usato da AGP senza applicare il vecchio
plugin Kotlin ai moduli. `android.newDsl=false` resta necessario per la DSL
usata dal plugin Gradle di Flutter; è indipendente da Kotlin integrato.
Le versioni risolte dei plugin compatibili sono registrate in `pubspec.lock`.
`android_id` usa una copia locale della 0.5.2+1 senza il ramo Gradle per il
vecchio KGP, che Flutter 3.47 segnala anche quando non viene eseguito. Il codice
che legge l'identificativo è invariato; dettagli e istruzioni per tornare al
pacchetto pubblicato sono in
[packages/android_id/LOCAL_CHANGES.md](packages/android_id/LOCAL_CHANGES.md).

```sh
flutter build apk --debug
```

## iOS: Swift Package Manager

Le dipendenze native iOS sono gestite con Swift Package Manager, abilitato nel
`pubspec.yaml`. CocoaPods non è necessario. Usare Flutter 3.47 o successivo;
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
- `volume_controller` usa la serie 3.7 con supporto SPM e Kotlin integrato.
- `flutter_tts` usa una copia locale della versione 4.2.5 con supporto SPM iOS.
  Origine, modifiche e istruzioni per tornare al pacchetto pubblicato sono in
  [packages/flutter_tts/LOCAL_CHANGES.md](packages/flutter_tts/LOCAL_CHANGES.md).

Quando si aggiungono plugin iOS, verificarne il supporto SPM per evitare che
Flutter debba ricorrere nuovamente a CocoaPods.
