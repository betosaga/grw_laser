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

Stato della connessione, esiti dei comandi ed errori passano esclusivamente
attraverso `LaserPageController.printLog` e sono visibili nella finestra log,
senza una barra di stato aggiuntiva nella pagina del robot. Il log include
data, ID locale e sessione. L'ID locale non viene inviato al robot. La memoria di
monitoraggio è limitata a 256 comandi pendenti; superato il limite, il più
vecchio termina come sconosciuto, senza bloccare nuovi STOP/OFF.

## Silenzio del robot e riconnessione

L'app non chiude una connessione TCP aperta per assenza, lentezza o interruzione
dei `RobotStatus`, né per il timeout di un comando. Il watchdog di ricezione è
stato rimosso: nessuna soglia di silenzio provoca una riconnessione automatica.
Se i messaggi riprendono, vengono elaborati sulla stessa sessione.

I valori sono configurabili nel costruttore `RobotConnection`:

| Impostazione | Default |
| --- | --- |
| Timeout apertura TCP | 5 secondi |
| Intervallo riconnessione | 5 secondi |
| Attesa esito comando | 15 secondi |

Il timeout di un comando ne registra soltanto l'esito sconosciuto tramite
`printLog`, senza chiudere il socket né reinviare il comando. Una connessione
silenziosa può restare aperta anche se la rete non è più operativa: il silenzio
da solo non è usato come prova di disconnessione.

Restano gestite le chiusure TCP del robot, gli errori effettivi del socket,
gli errori di framing/decodifica del flusso e le disconnessioni richieste
dall'utente o da un cambio di configurazione. Il timer di riconnessione
ritenta soltanto quando non esiste più un socket e non c'è un tentativo in corso.
Il timeout di apertura riguarda esclusivamente i nuovi tentativi TCP.

Dopo una reale riconnessione il flusso `listening` → `SETMODE` descritto sopra
resta attivo: la rimozione del watchdog non modifica l'inizializzazione della
modalità e non garantisce l'assenza di movimenti dopo una reale perdita TCP.

## Verifica

```sh
flutter test --no-pub test/robot_connection_test.dart \
  test/laser_robot_connection_test.dart \
  test/laser_robot_parameter_sync_test.dart \
  test/laser_robot_parametri_order_test.dart
```

Le prove usano un socket simulato e un server TCP su localhost. Nessuna prova
invia comandi al robot fisico. Coprono framing, UTF-8, errori, ordine delle
risposte, interfaccia lenta, sessioni scadute, timeout, mantenimento della
connessione durante silenzio prolungato o assenza dei `RobotStatus`,
esiti dei comandi e regressioni dei parametri esistenti.

## Eccezioni

`Connection refused`, timeout e altri errori di apertura TCP sono intercettati:
la connessione passa a disconnessa e il timer può ritentare. Lo stack trace
mostrato da `printLog` è diagnostico, non indica un'eccezione non gestita.
Anche gli errori di lettura, scrittura, cancellazione della sottoscrizione,
chiusura e azioni asincrone del protocollo vengono intercettati e registrati.
Un errore nei callback di notifica non deve interrompere la pulizia della
sessione o lasciare i comandi pendenti senza esito.
