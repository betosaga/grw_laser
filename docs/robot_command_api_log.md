# Log API dei comandi robot

Lo switch **Log comandi sulle API** nelle impostazioni del robot abilita queste
chiamate. Il valore predefinito è `false`. La scelta è salvata immediatamente
su disco con Hive (chiave `laser-command-api-log-enabled`), senza premere SALVA,
e vale per tutti i robot sul tablet, anche dopo il riavvio dell'app.
Quando è disattivato non partono nuove chiamate di logging; eventuali richieste
già avviate possono completarsi. I comandi e i log locali restano attivi.

L'app invia una POST alle API configurate in `URLs.apiurl` con
`f=logRobotLaserCommand` per ogni tentativo di `WELD` e per ogni richiesta di
interpolazione, comprese `/interpola_nuvola` e le URL configurate nei parametri.
Il log parte nel punto di invio, dopo la composizione del payload completo.

| Campo POST | Contenuto |
| --- | --- |
| `comando` | `WELD` oppure `/interpola` (anche per la variante nuvola) |
| `seriale_robot`, `ip_robot` | Robot a cui si riferisce la richiesta |
| `destinazione` | Indirizzo TCP oppure URL HTTP effettiva |
| `dataora_client` | Data e ora UTC del tentativo |
| `sessione_robot` | Sessione TCP dell'app |
| `parametri_json` | Intero JSON inviato, senza filtri, tagli o ricostruzioni dei parametri |
| `stato_invio` | `socket_write_attempted`, `not_sent` oppure `request_started` |
| `id_comando`, `esito_comando`, `dettaglio_esito` | Per WELD, identificativo locale ed esito disponibile al momento dell'invio |

`Api.request` aggiunge i normali metadati dell'app e le intestazioni di
autenticazione. Il body JSON resta un unico campo POST: i nomi dei parametri
con punti e le strutture annidate non vengono trasformati in campi PHP.

Il dispatcher esistente di `api.php` registra tutta la POST con
`Logger::logAPI("SAGAGRWLASER", ...)` e nella tabella `LOGS`. La nuova funzione
verifica client, autorizzazione, comando e formato JSON, poi restituisce HTTP
200. Non serve una nuova tabella e non viene duplicata la chiamata al logger.

La registrazione è asincrona, con timeout HTTP di 10 secondi e chiusura del
client HTTP alla fine. Errori e successo passano da `LaserPageController.printLog`.
Un errore del logging non blocca, non ritenta e non annulla il comando; non
chiude e non riconnette il socket del robot. Non viene creata una coda di
reinvi o una persistenza locale: se le API non sono raggiungibili, il log remoto
può mancare e l'errore compare nella finestra log dell'app.

Questi record descrivono richieste/tentativi, non conferme di esecuzione del
robot né il risultato dell'interpolazione. I WELD rifiutati localmente sono
distinti tramite `not_sent`; un tentativo di scrittura TCP non prova la ricezione.

## Installazione e verifica

Pubblicare la funzione aggiunta a `api.php` nell'endpoint usato dall'app
(attualmente `/api/grwlaser/apiv2.php`) prima di usare la nuova build.
Il file locale non viene distribuito sul server automaticamente.

```sh
php -d short_open_tag=1 -l api.php
php -d short_open_tag=1 test/api_robot_command_log_test.php WELD
php -d short_open_tag=1 test/api_robot_command_log_test.php /interpola
flutter test --no-pub test/robot_command_api_log_test.dart
```

I test usano socket e HTTP simulati, verificano la corrispondenza del payload
completo, entrambe le varianti di interpolazione, errori e timeout delle API.
Non inviano comandi a robot fisici o richieste alle API di produzione.
