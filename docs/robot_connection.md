# Connessione app–robot

Il trasporto rimane TCP (`dart:io Socket`, porta 20002). Il formato JSON del
robot non cambia e non vengono aggiunti delimitatori, ID o comandi di ping.

## Ciclo della connessione

`RobotConnection` possiede socket, ricezione e timer. C'è un solo tentativo di
connessione pendente e un solo timer di riconnessione. Una chiusura invalida
immediatamente la sessione: un tentativo che termina in ritardo distrugge il
proprio socket, senza riaprire la pagina o sostituire la connessione attuale.
Una nuova sessione usa un nuovo buffer JSON e un nuovo decoder UTF-8 incrementale.

Il protocollo viene elaborato nell'ordine di ricezione, senza `await` nei
gestori dello stato. Il ritardo di 1,5 secondi tra `listening` e `SETMODE` è
conservato come timer annullabile. Le chiamate WebView hanno una coda separata;
quelle ancora in coda vengono ignorate se la sessione cambia. Una chiamata
WebView già iniziata non può essere annullata retroattivamente.

Le azioni che attendono dialoghi, audio o altre operazioni prima dell'invio
catturano la sessione iniziale. Un comando destinato a una sessione terminata
viene rifiutato, anche se nel frattempo è già connesso un nuovo socket.
Anche i timer GAS-OFF/WIRE-OFF vengono annullati al cambio di sessione:
la chiusura del socket non dimostra che gas, filo o movimenti siano cessati.

## Esiti dei comandi

`sendMessageToRobot` restituisce `RobotCommandReceipt`. `accepted` significa
che è stato tentato l'affidamento al socket locale, non che il robot abbia
ricevuto o eseguito il comando. `receipt.completed` termina senza lanciare
eccezioni con uno dei seguenti esiti:

| Esito | Significato |
| --- | --- |
| `notSent` | Nessuna scrittura tentata: socket assente, sessione scaduta o payload invalido. |
| `waiting` | Stato iniziale: scrittura tentata, in attesa di osservazioni. |
| `responseObserved` | Ricevuta una risposta compatibile con un unico comando pendente. |
| `stateObserved` | Osservato lo stato atteso, ad esempio `PAUSED` dopo `PAUSE`. |
| `unknown` | Timeout, errore, disconnessione o limite di monitoraggio: esecuzione sconosciuta. |

`waiting` non è terminale. Il protocollo disponibile **non contiene conferme
correlate tramite ID**, quindi nessuno degli esiti osservati viene presentato
come conferma certa dell'esecuzione. Due comandi compatibili con la stessa
risposta restano in attesa: l'app non sceglie arbitrariamente a chi attribuirla.
Una risposta tardiva aggiorna lo stato del robot, ma non cambia un esito già
terminato per timeout. Potrebbe comunque essere compatibile con un comando
successivo: questo è un ulteriore motivo per non chiamarla ACK.

Le associazioni conservative sono in `RobotCommandReceipt.observationFor`:
`SETPOINT/getPoint`, `SETSAFEPOSITION/SafePosition`, movimenti/`Movement`,
`SETUPAREA/FrameSet`, `RESETSAFEPOSITION/ResetSafePosition`,
`ARMPOSITION/ArmPositionStatus`, `SETMODE/HOMEREACH` e gli stati di saldatura
di `PAUSE`, `RESUME`, `WELD`, `STOPCORDONE`. Gli altri comandi, compresi quelli
senza risposta documentata, possono terminare con esito sconosciuto.

Non ci sono ritentativi automatici dei comandi né una coda di movimenti da
svuotare alla riconnessione. Non viene chiamato `flush()` dopo ogni comando:
`Socket.write()` alimenta già il trasporto, e lo svuotamento del buffer locale
non costituirebbe una conferma remota. Gli errori di scrittura sono osservati
sia durante `write()` sia tramite `socket.done`.

La pagina mostra l'ultimo esito, un avviso persistente per mancato invio/esito
sconosciuto e uno storico degli ultimi 100 comandi. Il log include data, ID
locale e sessione. L'ID locale non viene inviato al robot. La memoria di
monitoraggio è limitata a 256 comandi pendenti; superato il limite, il più
vecchio termina come sconosciuto, senza bloccare nuovi STOP/OFF.

## Rilevamento della connessione non operativa

I valori sono configurabili nel costruttore `RobotConnection`:

| Impostazione | Default |
| --- | --- |
| Timeout apertura TCP | 5 secondi |
| Intervallo riconnessione | 5 secondi |
| Attesa esito comando | 15 secondi |
| Assenza completa di messaggi validi | 30 secondi |
| Controllo watchdog | Ogni secondo |
| Timeout minimo telemetria | 15 secondi |

Dopo almeno tre intervalli misurati fra `RobotStatus` con posizione e velocità
valide, il timeout della telemetria è il maggiore fra 15 secondi e cinque volte
la mediana degli ultimi 20 intervalli. Pacchetti accorpati con intervallo zero
non modificano la stima. Se la telemetria è più lenta, anche la soglia di
silenzio generale viene allungata. Gli altri messaggi non possono mascherare
l'interruzione di una telemetria precedentemente periodica.

Questi valori richiedono verifica sul robot durante avvio, movimento,
saldatura e pausa. Il watchdog rileva assenza di ricezione, non dimostra
che la direzione tablet→robot funzioni: senza ACK correlati quel caso rimane
un timeout del comando. Dopo una perdita di connessione l'app torna ad
attendere la sessione e `HOMEREACH`; non ripete le lavorazioni precedenti.

## Verifica

```sh
flutter test --no-pub test/robot_connection_test.dart \
  test/laser_robot_connection_test.dart \
  test/laser_robot_parameter_sync_test.dart \
  test/laser_robot_parametri_order_test.dart
```

Le prove usano un socket simulato e un server TCP su localhost. Nessuna prova
invia comandi al robot fisico. Coprono framing, UTF-8, errori, ordine delle
risposte, interfaccia lenta, sessioni scadute, timeout, rilevamento del silenzio,
esiti dei comandi e regressioni dei parametri esistenti.
