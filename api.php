<?

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

define("CLIENT_TOKEN", "SAGA-GRWLASER-01770fd0-5913-4ad2-9f94-c4f3f1c65a3b");
define("ANDROID_PACKAGE_NAME", "com.saga.grwlaser");
define("IOS_PACKAGE_NAME", "com.saga.grwlaser");

require_once("../../settings.php");

$ID_LOG = null;

if (isset($_POST['f']))
{
	Logger::logAPI("SAGAGRWLASER", 'CALL: ' . $_POST['f'] . " . POST: " . print_r($_POST, true), "GRW LASER", __LINE__, basename(__FILE__, '.php'), "");

	if (isset($_POST["f"]))
	{
		$function_called = $_POST["f"];
		$headers = apache_request_headers();
		$user_token = tokenFromHeaders($headers) ?? "";
		$utente = null;
		if ($user_token != "")
		{
			$utente = getUserByToken($conn, $user_token);
		}
		$id_utente = is_null($utente) ? null : $utente["id"];
		$username = is_null($utente) ? null : $utente["username"];
		$ip_address = getRealUserIp();
		$app_data = $_POST["app_data"] ?? "";

		try
		{
			$ID_LOG = MSSQL::queryP_IDV($conn, "INSERT INTO LOGS (ip, idutente, username, dataora, packagename, user_token, function_called, post_data, app_data) VALUES (?, ?, ?, GETDATE(), ?, ?, ?, ?, ?)", [$ip_address, $id_utente, $username, "grwlaser", $user_token, $function_called, json_encode($_POST), $app_data]);
		}
		catch (Exception $e)
		{
		}
	}

    ob_start();

    call_user_func_array($function_called, [$conn, $_POST, $_FILES]);

    $output_generato = ob_get_contents();
    ob_end_flush();

    if (!is_null($ID_LOG) && !empty($output_generato))
    {
        try
        {
            MSSQL::queryP($conn, "UPDATE LOGS SET output = ? WHERE id = ?", [$output_generato, $ID_LOG]);
        }
        catch (Exception $e)
        {
        }
    }
}

// ---------------------------------------------------------------
// AUTH / TOKEN
// ---------------------------------------------------------------

function saveToken($conn, $post, $files)
{
	$headers = apache_request_headers();
	checkClient($headers);
	checkAuthorization($conn, $headers);

	$userid = $post['userid'];
	$token = $post['token'] ?? "";
	$platform = $post['platform'] ?? "";
	$deviceid = $post['deviceid'] ?? "";
	$appversion = $post['appversion'] ?? "";

	if (trim($deviceid) == "")
	{
		responseError(400, 0, "Device ID Non Valido");
	}

	$PACKAGE_NAME = trim($platform) == "android" ? ANDROID_PACKAGE_NAME : IOS_PACKAGE_NAME;
	$TOKEN_TYPE = "NOTIFICATION";

	MSSQL::begin($conn, "SAGAID");
	MSSQL::queryP($conn, "DELETE FROM USER_TOKENS WHERE deviceid = ? AND platform = ? AND ( packagename = ? OR packagename = ? ) AND type = ?", [$deviceid, $platform, ANDROID_PACKAGE_NAME, IOS_PACKAGE_NAME, $TOKEN_TYPE]);
	$res = MSSQL::queryP($conn, "INSERT INTO USER_TOKENS (userid, token, createdAt, platform, deviceid, appversion, packagename, type) VALUES (?,?,GETDATE(),?,?,?,?,?)", [$userid, $token, $platform, $deviceid, $appversion, $PACKAGE_NAME, $TOKEN_TYPE]);

	if ($res === false)
	{
		MSSQL::rollback($conn, "SAGAID");
	}
	else
	{
		MSSQL::commit($conn, "SAGAID");
	}
}

function getPermessi($conn, $username, $tipoutente)
{
	$packagename = "REPORTS";
	$results = [];
	$permesso = 0;

	$qsezioni = MSSQL::queryP($conn, "SELECT sezione, posizione FROM PERMESSI_APP WHERE packagename = ? GROUP BY sezione, posizione", [$packagename, $tipoutente]);
	while ($rsezioni = sqlsrv_fetch_array($qsezioni))
	{
		$qpermission = MSSQL::queryP($conn, "SELECT * FROM PERMESSI_APP WHERE packagename = ? AND sezione = ? AND username = ?", [$packagename, $rsezioni['sezione'], $username]);
		$permesso = -1;
		if (sqlsrv_num_rows($qpermission) > 0)
		{
			$rpermission = sqlsrv_fetch_array($qpermission);
			$permesso = $rpermission['abilitato'];
		}

		if ($permesso == -1)
		{
			$qpermission = MSSQL::queryP($conn, "SELECT * FROM PERMESSI_APP WHERE packagename = ? AND sezione = ? AND tipoutente = ?", [$packagename, $rsezioni['sezione'], $tipoutente]);
			if (sqlsrv_num_rows($qpermission) > 0)
			{
				$rpermission = sqlsrv_fetch_array($qpermission);
				$permesso = $rpermission['abilitato'];
			}
		}

		if ($permesso == 1)
		{
			array_push($results, $rsezioni['sezione']);
		}
	}

	return $results;
}

// ---------------------------------------------------------------
// LOGIN
// ---------------------------------------------------------------

function doLogin($conn, $post)
{
	$headers = apache_request_headers();
	checkClient($headers);

	$u = $post['u'];
	$u = strtolower($u);
	$p = Utils::d($post['p']);
	$deviceID = $post['d'];
	$packageName = $post['pkg'];
	$platform = $post['plf'];

	Logger::logAPI("SAGAGRWLASER", 'Richiesta login: ' . $u, "GRW LASER", __LINE__, basename(__FILE__, '.php'), "");

	$q = MSSQL::queryP($conn, "SELECT TOP
									1 UTENTI.*,
									SQUADRE.nome AS nomesquadra,
									SQUADRE_UT.nome AS nomesquadraUT,
									SQUADRE_FX.nome AS nomesquadraFX,
									IMMAGINI_UTENTI.id AS avatarid
								FROM
									UTENTI
								LEFT JOIN
									IMMAGINI_UTENTI
								ON UTENTI.id = IMMAGINI_UTENTI.rif_Tabella_id
								LEFT JOIN
									SQUADRE
								ON
									UTENTI.idsquadra = SQUADRE.id
								LEFT JOIN
									SQUADRE_FX
								ON
									UTENTI.idsquadra_fx = SQUADRE_FX.id
								LEFT JOIN
									SQUADRE_UT
								ON
									UTENTI.idsquadra_ut = SQUADRE_UT.id
								WHERE
									UTENTI.username = ? AND UTENTI.licenziato = 0 AND UTENTI.attivo = 1", [$u]);

	$r = sqlsrv_fetch_array($q);

	$curl = curl_init();
	curl_setopt_array($curl, [
	 CURLOPT_SSL_VERIFYPEER => false,
	 CURLOPT_SSL_VERIFYHOST => false,
	 CURLOPT_URL => "https://ip-geolocation-ipwhois-io.p.rapidapi.com/json/?ip=" . $_SERVER['REMOTE_ADDR'],
	 CURLOPT_RETURNTRANSFER => true,
	 CURLOPT_FOLLOWLOCATION => true,
	 CURLOPT_ENCODING => "",
	 CURLOPT_MAXREDIRS => 10,
	 CURLOPT_TIMEOUT => 30,
	 CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
	 CURLOPT_CUSTOMREQUEST => "GET",
	 CURLOPT_HTTPHEADER => [
	  "X-RapidAPI-Host: ip-geolocation-ipwhois-io.p.rapidapi.com",
	  "X-RapidAPI-Key: c6a07bda47mshf59069a6a063868p1f95a6jsn3a403ddee8b0"
	 ],
	]);
	$response = curl_exec($curl);
	curl_close($curl);

	$passwordVerify = password_verify($p, trim($r['password']));
	if ($passwordVerify)
	{
		$userToken = getTokenForUser($conn, $r['id'], $platform, $deviceID, $packageName);
		$permessi = getPermessi($conn, $r['username'], $r['tipoutente']);

		$results = [
		 'id' => $r['id'],
		 'user_token' => $userToken,
		 'username' => $r['username'],
		 'squadraFX' => $r['nomesquadraFX'],
		 'squadra' => $r['nomesquadra'],
		 'squadraUT' => $r['nomesquadraUT'],
		 'email' => $r['email'],
		 'nome' => DBU::ss($r['nome']),
		 'cognome' => DBU::ss($r['cognome']),
		 'idsquadra' => $r['idsquadra'] ?? 0,
		 'idsquadraFX' => $r['idsquadra_fx'] ?? 0,
		 'idsquadraUT' => $r['idsquadra_ut'] ?? 0,
		 'apme' => $r['apme'] ?? "",
		 'abilitazione' => $r['abilitazione'],
		 'abilitazioneut' => $r['abilitazioneut'],
		 'avatar' => $r['avatarid'] != null ? 'https://rswonline.saga-srl.it/_openfilecrypt_.php?x=' . Utils::c("id=" . $r['avatarid']) : null,
		 'tipoutente' => $r['tipoutente'],
		 'modifica_parametri_robot' => $r['modifica_parametri_robot'],
		 'abilitato_visitalinea' => $r['abilitato_visitalinea'],
		 'permessi' => $permessi
		];

		Logger::logAPI("SAGAGRWLASER", 'Login effettuato: ' . $u, "GRW LASER", __LINE__);
		MSSQL::queryP(
		 $conn,
		 "INSERT INTO LOGIN_ATTEMPTS (ip,username,dataora,num_tentativo,browser,session_id,ok,additionaldata) VALUES (?,?,GETDATE(),?,?,?,?,?)",
		 [$_SERVER['REMOTE_ADDR'], $r['username'], 1, $_SERVER['HTTP_USER_AGENT'], "APP GRW LASER API " . basename($_SERVER['SCRIPT_FILENAME']), 1, $response]
		);

		echo json_encode($results);
	}
	else
	{
		Logger::logAPI("SAGAGRWLASER", 'Login fallito: ' . $u, "GRW LASER", __LINE__);
		MSSQL::queryP(
		 $conn,
		 "INSERT INTO LOGIN_ATTEMPTS (ip,username,dataora,num_tentativo,browser,session_id,ok,additionaldata) VALUES (?,?,GETDATE(),?,?,?,?,?)",
		 [
		  $_SERVER['REMOTE_ADDR'],
		  $r['username'],
		  1,
		  $_SERVER['HTTP_USER_AGENT'],
		  "APP GRW LASER API " . basename($_SERVER['SCRIPT_FILENAME']),
		  0,
		  $response
		 ]
		);

		responseError(400, 0, "Impossibile effettuare il login. Credenziali errate");
	}
}

function doLoginFakeForTheAdmins($conn, $post)
{
	$headers = apache_request_headers();
	checkClient($headers);

	$u = $post['u'];
	$u = strtolower($u);
	$deviceID = $post['d'];
	$packageName = $post['pkg'];
	$platform = $post['plf'];

	$q = MSSQL::queryP($conn, "SELECT TOP
									1 UTENTI.*,
									SQUADRE.nome AS nomesquadra,
									SQUADRE_UT.nome AS nomesquadraUT,
									SQUADRE_FX.nome AS nomesquadraFX,
									IMMAGINI_UTENTI.id AS avatarid
								FROM
									UTENTI
								LEFT JOIN
									IMMAGINI_UTENTI
								ON UTENTI.id = IMMAGINI_UTENTI.rif_Tabella_id
								LEFT JOIN
									SQUADRE
								ON
									UTENTI.idsquadra = SQUADRE.id
								LEFT JOIN
									SQUADRE_FX
								ON
									UTENTI.idsquadra_fx = SQUADRE_FX.id
								LEFT JOIN
									SQUADRE_UT
								ON
									UTENTI.idsquadra_ut = SQUADRE_UT.id
								WHERE
									UTENTI.username = ? AND UTENTI.licenziato = 0 AND UTENTI.attivo = 1", [$u]);

	$r = sqlsrv_fetch_array($q);

	$curl = curl_init();
	curl_setopt_array($curl, [
	 CURLOPT_SSL_VERIFYPEER => false,
	 CURLOPT_SSL_VERIFYHOST => false,
	 CURLOPT_URL => "https://ip-geolocation-ipwhois-io.p.rapidapi.com/json/?ip=" . $_SERVER['REMOTE_ADDR'],
	 CURLOPT_RETURNTRANSFER => true,
	 CURLOPT_FOLLOWLOCATION => true,
	 CURLOPT_ENCODING => "",
	 CURLOPT_MAXREDIRS => 10,
	 CURLOPT_TIMEOUT => 30,
	 CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
	 CURLOPT_CUSTOMREQUEST => "GET",
	 CURLOPT_HTTPHEADER => [
	  "X-RapidAPI-Host: ip-geolocation-ipwhois-io.p.rapidapi.com",
	  "X-RapidAPI-Key: c6a07bda47mshf59069a6a063868p1f95a6jsn3a403ddee8b0"
	 ],
	]);
	$response = curl_exec($curl);
	curl_close($curl);

	$userToken = getTokenForUser($conn, $r['id'], $platform, $deviceID, $packageName);
	$permessi = getPermessi($conn, $r['username'], $r['tipoutente']);

	$results = [
	 'id' => $r['id'],
	 'user_token' => $userToken,
	 'username' => $r['username'],
	 'squadraFX' => $r['nomesquadraFX'],
	 'squadra' => $r['nomesquadra'],
	 'squadraUT' => $r['nomesquadraUT'],
	 'email' => $r['email'],
	 'nome' => DBU::ss($r['nome']),
	 'cognome' => DBU::ss($r['cognome']),
	 'idsquadra' => $r['idsquadra'] ?? 0,
	 'idsquadraFX' => $r['idsquadra_fx'] ?? 0,
	 'idsquadraUT' => $r['idsquadra_ut'] ?? 0,
	 'apme' => $r['apme'] ?? "",
	 'abilitazione' => $r['abilitazione'],
	 'abilitazioneut' => $r['abilitazioneut'],
	 'avatar' => $r['avatarid'] != null ? 'https://rswonline.saga-srl.it/_openfilecrypt_.php?x=' . Utils::c("id=" . $r['avatarid']) : null,
	 'tipoutente' => $r['tipoutente'],
	 'modifica_parametri_robot' => $r['modifica_parametri_robot'],
	 'abilitato_visitalinea' => $r['abilitato_visitalinea'],
	 'permessi' => $permessi
	];

	echo json_encode($results);
}

// ---------------------------------------------------------------
// AGGIORNAMENTI APP
// ---------------------------------------------------------------

function getUpdates($conn, $post)
{
	$headers = apache_request_headers();
	checkClient($headers);

	$packagename = $post['packagename'];
	$version = $post['version'];

	if (strpos($version, "+"))
	{
		$version_element = explode("+", $version);
		$version = $version_element[0];
	}

	$build = intval($post['build']);
	$platform = $post['platform'];

	$res = false;
	Logger::logAPI("SAGAGRWLASER", "Controllo aggiornamenti (" . $platform . ") ID " . $packagename . " " . $version . " " . $build, __LINE__);
	$q = MSSQL::queryP($conn, "SELECT * FROM rsw.dbo.APPVERSION WHERE platform = ? AND packagename = ?", [$platform, $packagename]);
	$v = sqlsrv_fetch_array($q);
	$newversion = $v['version'];
	$newbuild = intval($v['build']);
	$v['linkandroid'] = $v['linkandroid'] ?? '';
	$v['linkiOS'] = $v['linkiOS'] ?? '';
	$v['update'] = 0;

	if ($version == $newversion)
	{
		if ($build < $newbuild)
		{
			$res = true;
		}
	}

	if ($version < $newversion)
	{
		$res = true;
	}

	if ($res)
	{
		$v['update'] = 1;
	}

	echo json_encode($v, true);
}

// ---------------------------------------------------------------
// SQUADRE
// ---------------------------------------------------------------

function getSquadre($conn, $post)
{
	$headers = apache_request_headers();
	checkClient($headers);
	checkAuthorization($conn, $headers);

	$q = MSSQL::queryP($conn, "SELECT id, nome, ordine FROM SQUADRE WHERE attiva = 1 AND officina = 0 ORDER BY ordine", []);
	$results = [];
	while ($r = sqlsrv_fetch_array($q))
	{
		$results[] = [
		 'id' => $r['id'],
		 'nome' => $r['nome'],
		 'ordine' => $r['ordine']
		];
	}

	echo json_encode($results);
}

// ---------------------------------------------------------------
// ROBOT LASER — LISTA E DETTAGLIO
// ---------------------------------------------------------------

function getRobotLaserList($conn, $post)
{
	$robots = [];
	$result = MSSQL::queryP($conn, "SELECT seriale_robot, color FROM rsw.dbo.ROBOT_LASER WHERE abilitato = 1 ORDER BY seriale_robot ASC", []);
	if ($result === false)
	{
		responseError(500, 1, "Lettura lista robot non avvenuta");
	}

	while ($data = sqlsrv_fetch_array($result, SQLSRV_FETCH_ASSOC))
	{
		$robots[] = $data;
	}

	$flags = defined('JSON_INVALID_UTF8_SUBSTITUTE') ? JSON_INVALID_UTF8_SUBSTITUTE : 0;
	echo json_encode($robots, $flags);
}

function getImpostazioniRobotLaser($conn, $post)
{
	getRobotLaserDetail($conn, $post);
}

function getRobotLaserDetail($conn, $post)
{
    $headers = apache_request_headers();
    checkClient($headers);
    checkAuthorization($conn, $headers);

    checkParametri(["seriale_robot"], $post);

    $SERIALE_ROBOT = strtoupper(trim($post["seriale_robot"]));

    $result = MSSQL::queryP($conn, "SELECT seriale_robot, ip_robot, ip_server, pin_gas, pin_laser, pin_massa, allontanamento_x, allontanamento_y, allontanamento_z, color, saldatura_verticale, saldatura_orizzontale, abilitato FROM ROBOT_LASER WHERE seriale_robot = ?", [$SERIALE_ROBOT]);
    if ($result === false) { responseError(500, 1, "Lettura dettaglio robot non avvenuta"); }
    if (sqlsrv_num_rows($result) > 0)
    {
        $data = sqlsrv_fetch_array($result, SQLSRV_FETCH_ASSOC);
        $limiti = getRobotLaserLimitiByRobotId($conn, $SERIALE_ROBOT);
        if ($limiti === false)
        {
            responseError(400, 1, "Lettura limiti non avvenuta");
        }

        $data['limiti'] = $limiti;
        $data['parametri'] = getRobotLaserParametriBySeriale($conn, $SERIALE_ROBOT);
        if ($data['parametri'] === false)
        {
            responseError(400, 1, "Lettura parametri robot non avvenuta");
        }

        $flags = defined('JSON_INVALID_UTF8_SUBSTITUTE') ? JSON_INVALID_UTF8_SUBSTITUTE : 0;
        echo json_encode($data, $flags);
    }
    else
    {
        responseError(404, 1, "Robot Laser non trovato con il seriale indicato");
    }
}

function setImpostazioniRobotLaser($conn, $post)
{
    $headers = apache_request_headers();
    checkClient($headers);
    checkAuthorization($conn, $headers);

    checkParametri(["seriale_start", "seriale_robot", "ip_robot", "ip_server", "pin_gas", "pin_laser", "pin_massa", "allontanamento_x", "allontanamento_y", "allontanamento_z"], $post);

    $seriale_robot_current = strtoupper(trim($post["seriale_start"]));
    $seriale_robot_new = strtoupper(trim($post["seriale_robot"]));
    $ip_robot = $post["ip_robot"];
    $ip_server = $post["ip_server"];
    $pin_gas = $post["pin_gas"];
    $pin_laser = $post["pin_laser"];
    $pin_massa = $post["pin_massa"];

    $allontanamento_x = normalizeNullableInt($post["allontanamento_x"]);
    if ($allontanamento_x === false) { responseError(400, 1, "allontanamento_x non valido"); }
    if ($allontanamento_x === null) { $allontanamento_x = 0; }

    $allontanamento_y = normalizeNullableInt($post["allontanamento_y"]);
    if ($allontanamento_y === false) { responseError(400, 1, "allontanamento_y non valido"); }
    if ($allontanamento_y === null) { $allontanamento_y = 0; }

    $allontanamento_z = normalizeNullableInt($post["allontanamento_z"]);
    if ($allontanamento_z === false) { responseError(400, 1, "allontanamento_z non valido"); }
    if ($allontanamento_z === null) { $allontanamento_z = 0; }

    list($limitiPayload, $limitiPayloadError) = normalizeRobotLaserLimitiPayload($post);
    if ($limitiPayload === false) { responseError(400, 1, $limitiPayloadError); }

    list($parametriPayload, $parametriPayloadError) = normalizeRobotLaserParametriPayload($conn, $seriale_robot_current, $post);
    if ($parametriPayload === false) { responseError(400, 1, $parametriPayloadError); }

    MSSQL::begin($conn, "RSW");

    $currentRobot = MSSQL::queryP($conn, "SELECT id FROM ROBOT_LASER WITH (UPDLOCK, HOLDLOCK) WHERE seriale_robot = ?", [$seriale_robot_current]);
    if ($currentRobot === false) { MSSQL::rollback($conn, "RSW"); responseError(400, 1, "Verifica robot laser non avvenuta"); }
    if (sqlsrv_num_rows($currentRobot) <= 0) { MSSQL::rollback($conn, "RSW"); responseError(404, 1, "Robot Laser non trovato con il seriale indicato"); }

    if ($seriale_robot_current !== $seriale_robot_new)
    {
        $targetRobot = MSSQL::queryP($conn, "SELECT id FROM ROBOT_LASER WITH (UPDLOCK, HOLDLOCK) WHERE seriale_robot = ?", [$seriale_robot_new]);
        if ($targetRobot === false) { MSSQL::rollback($conn, "RSW"); responseError(400, 1, "Verifica nuovo seriale robot non avvenuta"); }
        if (sqlsrv_num_rows($targetRobot) > 0) { MSSQL::rollback($conn, "RSW"); responseError(409, 1, "Esiste gia un Robot Laser con il nuovo seriale indicato"); }
    }

    $r = MSSQL::queryP($conn, "UPDATE ROBOT_LASER SET seriale_robot = ?, ip_robot = ?, ip_server = ?, pin_gas = ?, pin_laser = ?, pin_massa = ?, allontanamento_x = ?, allontanamento_y = ?, allontanamento_z = ? WHERE seriale_robot = ?", [$seriale_robot_new, $ip_robot, $ip_server, $pin_gas, $pin_laser, $pin_massa, $allontanamento_x, $allontanamento_y, $allontanamento_z, $seriale_robot_current]);
    if ($r === false) { MSSQL::rollback($conn, "RSW"); responseError(400, 1, "Salvataggio non avvenuto"); }

    $result = MSSQL::queryP($conn, "SELECT seriale_robot, ip_robot, ip_server, pin_gas, pin_laser, pin_massa, allontanamento_x, allontanamento_y, allontanamento_z, color, saldatura_verticale, saldatura_orizzontale, abilitato FROM ROBOT_LASER WHERE seriale_robot = ?", [$seriale_robot_new]);
    if ($result === false) { MSSQL::rollback($conn, "RSW"); responseError(400, 1, "Lettura dettaglio robot non avvenuta"); }
    if (sqlsrv_num_rows($result) <= 0) { MSSQL::rollback($conn, "RSW"); responseError(404, 1, "Robot Laser non trovato con il seriale indicato"); }

    if ($seriale_robot_current !== $seriale_robot_new)
    {
        $rRenameLimiti = MSSQL::queryP($conn, "UPDATE rsw.dbo.ROBOT_LASER_LIMITI SET robot_id = ? WHERE robot_id = ?", [$seriale_robot_new, $seriale_robot_current]);
        if ($rRenameLimiti === false) { MSSQL::rollback($conn, "RSW"); responseError(400, 1, "Aggiornamento limiti non avvenuto"); }

        $rRenameParametri = MSSQL::queryP($conn, "UPDATE rsw.dbo.ROBOT_LASER_PARAMETRI SET seriale_robot = ?, data_modifica = SYSUTCDATETIME() WHERE seriale_robot = ?", [$seriale_robot_new, $seriale_robot_current]);
        if ($rRenameParametri === false) { MSSQL::rollback($conn, "RSW"); responseError(400, 1, "Aggiornamento parametri robot non avvenuto"); }
    }

    $data = sqlsrv_fetch_array($result, SQLSRV_FETCH_ASSOC);
    if ($limitiPayload !== null)
    {
        list($limitiFinal, $limitiSaveError) = syncRobotLaserLimiti($conn, $seriale_robot_new, $limitiPayload);
        if ($limitiFinal === false) { MSSQL::rollback($conn, "RSW"); responseError(400, 1, $limitiSaveError); }
    }
    else
    {
        $limitiFinal = getRobotLaserLimitiByRobotId($conn, $seriale_robot_new);
        if ($limitiFinal === false) { MSSQL::rollback($conn, "RSW"); responseError(400, 1, "Lettura limiti non avvenuta"); }
    }

    if ($parametriPayload !== null)
    {
        list($parametriFinal, $parametriSaveError) = syncRobotLaserParametri($conn, $seriale_robot_new, $parametriPayload);
        if ($parametriFinal === false) { MSSQL::rollback($conn, "RSW"); responseError(400, 1, $parametriSaveError); }
    }
    else
    {
        $parametriFinal = getRobotLaserParametriBySeriale($conn, $seriale_robot_new);
        if ($parametriFinal === false) { MSSQL::rollback($conn, "RSW"); responseError(400, 1, "Lettura parametri robot non avvenuta"); }
    }

    MSSQL::commit($conn, "RSW");

    $data['limiti'] = $limitiFinal;
    $data['parametri'] = $parametriFinal;

    $flags = defined('JSON_INVALID_UTF8_SUBSTITUTE') ? JSON_INVALID_UTF8_SUBSTITUTE : 0;
    echo json_encode($data, $flags);
}

// ---------------------------------------------------------------
// ROBOT LASER - PARAMETRI (helpers)
// ---------------------------------------------------------------

function robotLaserParametroValueFromStorage($value, $tipo)
{
    if ($value === null) { return null; }

    $tipo = strtolower(trim((string)$tipo));
    if (in_array($tipo, ['int', 'integer', 'intero', 'tinyint', 'smallint', 'bigint'], true))
    {
        return (int)$value;
    }
    if (in_array($tipo, ['float', 'double', 'decimal', 'number', 'numeric', 'numero'], true))
    {
        return (float)$value;
    }
    if (in_array($tipo, ['bool', 'boolean', 'bit'], true))
    {
        return in_array(strtolower(trim((string)$value)), ['1', 'true', 'yes', 'si', 'on'], true);
    }
    if (in_array($tipo, ['json', 'array', 'object', 'lista'], true))
    {
        $decoded = json_decode((string)$value, true);
        return json_last_error() === JSON_ERROR_NONE ? $decoded : $value;
    }

    return (string)$value;
}

function decodeRobotLaserValoriAmmessi($value)
{
    if ($value === null || trim((string)$value) === '') { return null; }

    $decoded = json_decode((string)$value, true);
    return json_last_error() === JSON_ERROR_NONE ? $decoded : null;
}

function mapRobotLaserParametroRow($row)
{
    return [
        'parametro' => trim((string)$row['parametro']),
        'tipo' => trim((string)$row['tipo']),
        'nullable' => (bool)$row['nullable'],
        'valore' => robotLaserParametroValueFromStorage($row['valore'], $row['tipo']),
        'valore_default' => robotLaserParametroValueFromStorage($row['valore_default'], $row['tipo']),
        'valori_ammessi' => decodeRobotLaserValoriAmmessi($row['valori_ammessi_json']),
        'categoria' => $row['categoria'] === null ? null : (string)$row['categoria'],
        'descrizione' => $row['descrizione'] === null ? null : (string)$row['descrizione'],
        'ordine' => (int)$row['ordine'],
        'modificabile' => (bool)$row['modificabile'],
        'personalizzato' => (bool)$row['personalizzato'],
    ];
}

function getRobotLaserParametriBySeriale($conn, $serialeRobot)
{
    $qParametri = MSSQL::queryP(
        $conn,
        "SELECT p.parametro, p.tipo, p.[nullable], p.valore_default, p.valori_ammessi_json,
                p.categoria, p.descrizione, p.ordine, p.modificabile,
                CASE WHEN rp.parametro IS NULL THEN p.valore_default ELSE rp.valore END AS valore,
                CASE WHEN rp.parametro IS NULL THEN CAST(0 AS bit) ELSE CAST(1 AS bit) END AS personalizzato
         FROM rsw.dbo.ROBOT_LASER_PARAMETRO p
         LEFT JOIN rsw.dbo.ROBOT_LASER_PARAMETRI rp
           ON rp.parametro = p.parametro AND rp.seriale_robot = ?
         ORDER BY p.ordine ASC, p.parametro ASC",
        [$serialeRobot]
    );
    if ($qParametri === false) { return false; }

    $parametri = [];
    while ($rParametro = sqlsrv_fetch_array($qParametri, SQLSRV_FETCH_ASSOC))
    {
        $parametri[] = mapRobotLaserParametroRow($rParametro);
    }

    return $parametri;
}

function isRobotLaserParametriList($value)
{
    if (!is_array($value)) { return false; }
    if (count($value) === 0) { return true; }
    return array_keys($value) === range(0, count($value) - 1);
}

function normalizeRobotLaserParametroValueForStorage($value, $definition)
{
    $nome = $definition['parametro'];
    if ($value === null)
    {
        return $definition['nullable'] ? [null, null] : [false, "Il parametro " . $nome . " non puo essere nullo"];
    }

    $tipo = strtolower(trim((string)$definition['tipo']));
    if (in_array($tipo, ['int', 'integer', 'intero', 'tinyint', 'smallint', 'bigint'], true))
    {
        if (is_int($value)) { return [(string)$value, null]; }
        if (is_float($value) && floor($value) === $value) { return [(string)(int)$value, null]; }
        if (!is_string($value) || !preg_match('/^[+-]?\d+$/', trim($value))) { return [false, "Il parametro " . $nome . " deve essere un intero"]; }
        return [(string)(int)trim($value), null];
    }
    if (in_array($tipo, ['float', 'double', 'decimal', 'number', 'numeric', 'numero'], true))
    {
        if (!is_numeric($value)) { return [false, "Il parametro " . $nome . " deve essere numerico"]; }
        return [(string)$value, null];
    }
    if (in_array($tipo, ['bool', 'boolean', 'bit'], true))
    {
        if (is_bool($value)) { return [$value ? '1' : '0', null]; }
        $normalized = strtolower(trim((string)$value));
        if (in_array($normalized, ['1', 'true', 'yes', 'si', 'on'], true)) { return ['1', null]; }
        if (in_array($normalized, ['0', 'false', 'no', 'off'], true)) { return ['0', null]; }
        return [false, "Il parametro " . $nome . " deve essere booleano"];
    }
    if (in_array($tipo, ['json', 'array', 'object', 'lista'], true))
    {
        if (is_string($value))
        {
            json_decode($value, true);
            if (json_last_error() !== JSON_ERROR_NONE) { return [false, "Il parametro " . $nome . " non contiene JSON valido"]; }
            return [$value, null];
        }

        $encoded = json_encode($value);
        return $encoded === false ? [false, "Il parametro " . $nome . " non contiene JSON valido"] : [$encoded, null];
    }
    if (is_array($value) || is_object($value))
    {
        return [false, "Il parametro " . $nome . " deve essere testuale"];
    }

    return [(string)$value, null];
}

function robotLaserParametroComparableValue($value)
{
    if ($value === null) { return '__NULL__'; }
    if (is_bool($value)) { return $value ? '1' : '0'; }
    if (is_array($value) || is_object($value)) { return json_encode($value); }
    return (string)$value;
}

function isRobotLaserParametroValueAllowed($value, $allowed)
{
    if ($allowed === null || $value === null) { return true; }

    if (is_array($allowed) && isRobotLaserParametriList($allowed))
    {
        $comparableValue = robotLaserParametroComparableValue($value);
        foreach ($allowed as $option)
        {
            if (is_array($option) && array_key_exists('valore', $option)) { $option = $option['valore']; }
            elseif (is_array($option) && array_key_exists('value', $option)) { $option = $option['value']; }

            if (robotLaserParametroComparableValue($option) === $comparableValue) { return true; }
        }
        return false;
    }

    if (is_array($allowed))
    {
        foreach (['valori', 'values', 'opzioni', 'options'] as $key)
        {
            if (isset($allowed[$key]) && is_array($allowed[$key]))
            {
                return isRobotLaserParametroValueAllowed($value, $allowed[$key]);
            }
        }

        if (is_numeric($value))
        {
            if (array_key_exists('min', $allowed) && (float)$value < (float)$allowed['min']) { return false; }
            if (array_key_exists('max', $allowed) && (float)$value > (float)$allowed['max']) { return false; }
        }
    }

    return true;
}

function normalizeRobotLaserParametriPayload($conn, $serialeRobot, $post)
{
    if (!array_key_exists('parametri', $post)) { return [null, null]; }

    $payload = $post['parametri'];
    if (is_string($payload))
    {
        $payload = json_decode($payload, true);
        if (json_last_error() !== JSON_ERROR_NONE) { return [false, "Il campo parametri non contiene JSON valido"]; }
    }
    if (!is_array($payload)) { return [false, "Il campo parametri deve essere una lista o un oggetto"]; }

    $definitionsList = getRobotLaserParametriBySeriale($conn, $serialeRobot);
    if ($definitionsList === false) { return [false, "Lettura parametri robot non avvenuta"]; }

    $definitions = [];
    foreach ($definitionsList as $definition)
    {
        $definitions[strtolower($definition['parametro'])] = $definition;
    }

    $rows = [];
    if (isRobotLaserParametriList($payload))
    {
        foreach ($payload as $index => $row)
        {
            if (!is_array($row) || !array_key_exists('parametro', $row) || !array_key_exists('valore', $row))
            {
                return [false, "Formato parametro non valido alla riga " . ($index + 1)];
            }
            $rows[] = ['parametro' => $row['parametro'], 'valore' => $row['valore']];
        }
    }
    else
    {
        foreach ($payload as $parametro => $valore)
        {
            $rows[] = ['parametro' => $parametro, 'valore' => $valore];
        }
    }

    $normalizedRows = [];
    $seen = [];
    foreach ($rows as $row)
    {
        $parametro = trim((string)$row['parametro']);
        $definitionKey = strtolower($parametro);
        if ($parametro === '' || !isset($definitions[$definitionKey])) { return [false, "Parametro robot non riconosciuto: " . $parametro]; }
        if (isset($seen[$definitionKey])) { return [false, "Parametro robot duplicato: " . $parametro]; }
        $seen[$definitionKey] = true;

        $definition = $definitions[$definitionKey];
        list($storageValue, $valueError) = normalizeRobotLaserParametroValueForStorage($row['valore'], $definition);
        if ($storageValue === false) { return [false, $valueError]; }

        $typedValue = robotLaserParametroValueFromStorage($storageValue, $definition['tipo']);
        if (!isRobotLaserParametroValueAllowed($typedValue, $definition['valori_ammessi']))
        {
            return [false, "Valore non ammesso per il parametro " . $definition['parametro']];
        }

        if (!$definition['modificabile'])
        {
            if (robotLaserParametroComparableValue($typedValue) !== robotLaserParametroComparableValue($definition['valore']))
            {
                return [false, "Il parametro " . $definition['parametro'] . " non e modificabile"];
            }
            continue;
        }

        $normalizedRows[] = ['parametro' => $definition['parametro'], 'valore' => $storageValue];
    }

    return [$normalizedRows, null];
}

function syncRobotLaserParametri($conn, $serialeRobot, $parametri)
{
    foreach ($parametri as $parametro)
    {
        $rParametro = MSSQL::queryP(
            $conn,
            "UPDATE rsw.dbo.ROBOT_LASER_PARAMETRI
             SET valore = ?, data_modifica = SYSUTCDATETIME()
             WHERE seriale_robot = ? AND parametro = ?;
             IF @@ROWCOUNT = 0
             BEGIN
                 INSERT INTO rsw.dbo.ROBOT_LASER_PARAMETRI (seriale_robot, parametro, valore)
                 VALUES (?, ?, ?);
             END",
            [$parametro['valore'], $serialeRobot, $parametro['parametro'], $serialeRobot, $parametro['parametro'], $parametro['valore']]
        );
        if ($rParametro === false) { return [false, "Salvataggio parametri robot non avvenuto"]; }
    }

    $finalParametri = getRobotLaserParametriBySeriale($conn, $serialeRobot);
    if ($finalParametri === false) { return [false, "Lettura parametri robot non avvenuta"]; }

    return [$finalParametri, null];
}

// ---------------------------------------------------------------
// ROBOT LASER — LIMITI (helpers)
// ---------------------------------------------------------------

function normalizeNullableInt($value)
{
    if (!isset($value)) { return null; }
    if (is_string($value) && trim($value) === "") { return null; }
    if (!is_numeric($value)) { return false; }
    return (int)$value;
}

function normalizeNullableDecimal($value)
{
    if (!isset($value)) { return null; }
    if (is_string($value) && trim($value) === "") { return null; }
    if (!is_numeric($value)) { return false; }
    return (float)$value;
}

function normalizeNullableString($value)
{
    if (!isset($value)) { return null; }
    if (is_string($value) && trim($value) === "") { return null; }
    return trim((string)$value);
}

function mapRobotLaserLimiteRow($row)
{
    return [
        'id' => isset($row['id']) ? (int)$row['id'] : null,
        'robot_id' => isset($row['robot_id']) ? trim((string)$row['robot_id']) : null,
        'limite_z_down' => isset($row['limite_z_down']) ? (int)$row['limite_z_down'] : 0,
        'step_up' => isset($row['step_up']) ? (float)$row['step_up'] : 0,
        'step_down' => isset($row['step_down']) ? (float)$row['step_down'] : 0,
        'step_up_sx' => isset($row['step_up_sx']) ? (float)$row['step_up_sx'] : 0,
        'step_up_dx' => isset($row['step_up_dx']) ? (float)$row['step_up_dx'] : 0,
        'step_down_sx' => isset($row['step_down_sx']) ? (float)$row['step_down_sx'] : 0,
        'step_down_dx' => isset($row['step_down_dx']) ? (float)$row['step_down_dx'] : 0,
        'step_left' => isset($row['step_left']) ? (float)$row['step_left'] : 0,
        'step_right' => isset($row['step_right']) ? (float)$row['step_right'] : 0,
        'step_y' => isset($row['step_y']) ? (float)$row['step_y'] : 0,
        'tipo_controrotaia' => !isset($row['tipo_controrotaia']) || trim((string)$row['tipo_controrotaia']) === "" ? "0" : trim((string)$row['tipo_controrotaia']),
    ];
}

function getRobotLaserLimitiByRobotId($conn, $robotId)
{
    $qLimiti = MSSQL::queryP($conn, "SELECT id, robot_id, ISNULL(limite_z_down, 0) AS limite_z_down, ISNULL(step_up, 0) AS step_up, ISNULL(step_down, 0) AS step_down, ISNULL(step_up_sx, 0) AS step_up_sx, ISNULL(step_up_dx, 0) AS step_up_dx, ISNULL(step_down_sx, 0) AS step_down_sx, ISNULL(step_down_dx, 0) AS step_down_dx, ISNULL(step_left, 0) AS step_left, ISNULL(step_right, 0) AS step_right, ISNULL(step_y, 0) AS step_y, ISNULL(tipo_controrotaia, '0') AS tipo_controrotaia FROM rsw.dbo.ROBOT_LASER_LIMITI WHERE robot_id = ? ORDER BY tipo_controrotaia ASC, limite_z_down ASC, id ASC", [$robotId]);
    if ($qLimiti === false) { return false; }

    $limiti = [];
    while ($rLimiti = sqlsrv_fetch_array($qLimiti, SQLSRV_FETCH_ASSOC))
    {
        $limiti[] = mapRobotLaserLimiteRow($rLimiti);
    }

    return $limiti;
}

function normalizeRobotLaserLimiteInputRow($row, $index)
{
    if (!is_array($row)) { return [false, "Formato limite non valido alla riga " . ($index + 1)]; }

    $id = null;
    if (array_key_exists('id', $row))
    {
        $id = normalizeNullableInt($row['id']);
        if ($id === false || ($id !== null && $id <= 0)) { return [false, "Id limite non valido alla riga " . ($index + 1)]; }
    }

    $limiteZDown = normalizeNullableInt($row['limite_z_down'] ?? null);
    $stepUp = normalizeNullableDecimal($row['step_up'] ?? null);
    $stepDown = normalizeNullableDecimal($row['step_down'] ?? null);
    $stepUpSx = normalizeNullableDecimal($row['step_up_sx'] ?? null);
    $stepUpDx = normalizeNullableDecimal($row['step_up_dx'] ?? null);
    $stepDownSx = normalizeNullableDecimal($row['step_down_sx'] ?? null);
    $stepDownDx = normalizeNullableDecimal($row['step_down_dx'] ?? null);
    $stepLeft = normalizeNullableDecimal($row['step_left'] ?? null);
    $stepRight = normalizeNullableDecimal($row['step_right'] ?? null);
    $stepY = normalizeNullableDecimal($row['step_y'] ?? null);
    $tipoControrotaia = normalizeNullableString($row['tipo_controrotaia'] ?? null);

    if ($limiteZDown === false || $stepUp === false || $stepDown === false || $stepUpSx === false || $stepUpDx === false || $stepDownSx === false || $stepDownDx === false || $stepLeft === false || $stepRight === false || $stepY === false)
    {
        return [false, "Valori limiti non validi alla riga " . ($index + 1)];
    }

    return [[
        'id' => $id,
        'limite_z_down' => $limiteZDown === null ? 0 : $limiteZDown,
        'step_up' => $stepUp === null ? 0 : $stepUp,
        'step_down' => $stepDown === null ? 0 : $stepDown,
        'step_up_sx' => $stepUpSx === null ? 0 : $stepUpSx,
        'step_up_dx' => $stepUpDx === null ? 0 : $stepUpDx,
        'step_down_sx' => $stepDownSx === null ? 0 : $stepDownSx,
        'step_down_dx' => $stepDownDx === null ? 0 : $stepDownDx,
        'step_left' => $stepLeft === null ? 0 : $stepLeft,
        'step_right' => $stepRight === null ? 0 : $stepRight,
        'step_y' => $stepY === null ? 0 : $stepY,
        'tipo_controrotaia' => $tipoControrotaia === null ? "0" : $tipoControrotaia,
    ], null];
}

function normalizeRobotLaserLimitiPayload($post)
{
    if (array_key_exists('limiti', $post))
    {
        $limitiValue = $post['limiti'];
        if (is_string($limitiValue)) { $limitiValue = json_decode($limitiValue, true); }
        if (!is_array($limitiValue)) { return [false, "Il campo limiti deve essere una lista"]; }
        $rows = $limitiValue;
    }
    else
    {
        return [null, null];
    }

    $normalizedRows = [];
    $keys = [];

    foreach ($rows as $index => $row)
    {
        list($normalizedRow, $error) = normalizeRobotLaserLimiteInputRow($row, $index);
        if ($normalizedRow === false) { return [false, $error]; }

        $uniqueKey = strtolower($normalizedRow['tipo_controrotaia']) . "|" . $normalizedRow['limite_z_down'];
        if (isset($keys[$uniqueKey])) { return [false, "Combinazione tipo controrotaia e lim z down duplicata alla riga " . ($index + 1)]; }

        $keys[$uniqueKey] = true;
        $normalizedRows[] = $normalizedRow;
    }

    return [$normalizedRows, null];
}

function syncRobotLaserLimiti($conn, $robotId, $limiti)
{
    $currentLimiti = getRobotLaserLimitiByRobotId($conn, $robotId);
    if ($currentLimiti === false) { return [false, "Lettura limiti non avvenuta"]; }

    $currentById = [];
    foreach ($currentLimiti as $limite) { $currentById[(int)$limite['id']] = $limite; }

    $keepIds = [];
    foreach ($limiti as $limite)
    {
        $params = [
            $robotId, $limite['limite_z_down'], $limite['step_up'], $limite['step_down'],
            $limite['step_up_sx'], $limite['step_up_dx'], $limite['step_down_sx'], $limite['step_down_dx'],
            $limite['step_left'], $limite['step_right'], $limite['step_y'], $limite['tipo_controrotaia'],
        ];

        if ($limite['id'] === null)
        {
            $rLimite = MSSQL::queryP($conn, "INSERT INTO rsw.dbo.ROBOT_LASER_LIMITI (robot_id, limite_z_down, step_up, step_down, step_up_sx, step_up_dx, step_down_sx, step_down_dx, step_left, step_right, step_y, tipo_controrotaia) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", $params);
        }
        else
        {
            if (!isset($currentById[(int)$limite['id']])) { return [false, "Id limite non valido: " . $limite['id']]; }
            $keepIds[] = (int)$limite['id'];
            $params[] = $limite['id'];
            $rLimite = MSSQL::queryP($conn, "UPDATE rsw.dbo.ROBOT_LASER_LIMITI SET robot_id = ?, limite_z_down = ?, step_up = ?, step_down = ?, step_up_sx = ?, step_up_dx = ?, step_down_sx = ?, step_down_dx = ?, step_left = ?, step_right = ?, step_y = ?, tipo_controrotaia = ? WHERE id = ?", $params);
        }

        if ($rLimite === false) { return [false, "Salvataggio limiti non avvenuto"]; }
    }

    $deleteIds = [];
    foreach ($currentById as $id => $limite) { if (!in_array($id, $keepIds, true)) { $deleteIds[] = $id; } }

    if (count($deleteIds) > 0)
    {
        $placeholders = implode(", ", array_fill(0, count($deleteIds), "?"));
        $rDelete = MSSQL::queryP($conn, "DELETE FROM rsw.dbo.ROBOT_LASER_LIMITI WHERE id IN (" . $placeholders . ")", $deleteIds);
        if ($rDelete === false) { return [false, "Cancellazione limiti non avvenuta"]; }
    }

    $finalLimiti = getRobotLaserLimitiByRobotId($conn, $robotId);
    if ($finalLimiti === false) { return [false, "Lettura limiti non avvenuta"]; }

    return [$finalLimiti, null];
}

// ---------------------------------------------------------------
// PUNTI LASER
// ---------------------------------------------------------------

function getLaserPunti($conn, $post, $files)
{
    $headers = apache_request_headers();
    checkClient($headers);
    checkAuthorization($conn, $headers);
    checkParametri(["seriale_robot"], $post);

    $serialeRobot = trim($post['seriale_robot']);

    $q = MSSQL::queryP(
        $conn,
        "SELECT id, seriale_robot, dataora, nome, punti
         FROM rsw.dbo.ROBOT_LASER_PUNTI
         WHERE seriale_robot = ?
         ORDER BY dataora DESC, id DESC",
        [$serialeRobot]
    );

    if ($q === false) { responseError(500, 0, "Errore nel recupero punti laser"); return; }

    $result = [];
    while ($r = sqlsrv_fetch_array($q, SQLSRV_FETCH_ASSOC))
    {
        $dataora = null;
        if (!empty($r['dataora']) && $r['dataora'] instanceof DateTime) {
            $dataora = $r['dataora']->format('Y-m-d H:i:s');
        }

        $result[] = [
            "id"            => $r['id'],
            "seriale_robot" => DBU::ss($r['seriale_robot']),
            "dataora"       => $dataora,
            "nome"          => DBU::ss($r['nome']),
            "punti"         => DBU::ss($r['punti'])
        ];
    }

    $json = json_encode($result);
    if ($json === false) { responseError(500, 0, "Errore codifica JSON"); return; }

    echo $json;
}

function saveLaserPunti($conn, $post, $files)
{
    $headers = apache_request_headers();
    checkClient($headers);
    checkAuthorization($conn, $headers);
    checkParametri(["seriale_robot", "nome", "punti"], $post);

    $serialeRobot = trim($post['seriale_robot']);
    $nome = trim($post['nome']);
    $punti = $post['punti'];

    json_decode($punti, true);
    if (json_last_error() !== JSON_ERROR_NONE) { responseError(400, 0, "Formato punti non valido (JSON atteso)"); return; }

    $ins = MSSQL::queryP(
        $conn,
        "INSERT INTO rsw.dbo.ROBOT_LASER_PUNTI (seriale_robot, dataora, nome, punti) VALUES (?, GETDATE(), ?, ?)",
        [$serialeRobot, $nome, $punti]
    );

    if ($ins === false) { responseError(500, 0, "Errore nel salvataggio punti laser"); return; }

    $qid = MSSQL::queryP($conn, "SELECT CAST(SCOPE_IDENTITY() AS INT) AS id");
    $id = null;
    if ($qid && ($rid = sqlsrv_fetch_array($qid, SQLSRV_FETCH_ASSOC))) { $id = (int)$rid['id']; }

    echo json_encode(
        ["ok" => 1, "id" => $id, "message" => "Punti salvati correttamente"],
        JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE
    );
}

function deleteLaserPunti($conn, $post, $files)
{
    $headers = apache_request_headers();
    checkClient($headers);
    checkAuthorization($conn, $headers);
    checkParametri(["id"], $post);

    $id = (int)$post['id'];

    $qCheck = MSSQL::queryP($conn, "SELECT id FROM rsw.dbo.ROBOT_LASER_PUNTI WHERE id = ?", [$id]);
    if ($qCheck === false || sqlsrv_num_rows($qCheck) === 0) { responseError(404, 0, "Record non trovato"); return; }

    $del = MSSQL::queryP($conn, "DELETE FROM rsw.dbo.ROBOT_LASER_PUNTI WHERE id = ?", [$id]);
    if ($del === false) { responseError(500, 0, "Errore eliminazione punti laser"); return; }

    echo json_encode(
        ["ok" => 1, "message" => "Punti eliminati correttamente"],
        JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE
    );
}

// ---------------------------------------------------------------
// UTILITIES
// ---------------------------------------------------------------

function string_to_int($n)
{
	try { return intval($n); }
	catch (Exception $e) { return 0; }
}

function lval($is_lavorato, $value, $default)
{
	return $is_lavorato ? ($value ?? $default) : $default;
}

function getRealUserIp()
{
	switch (true)
	{
		case (!empty($_SERVER['HTTP_X_REAL_IP'])): return $_SERVER['HTTP_X_REAL_IP'];
		case (!empty($_SERVER['HTTP_CLIENT_IP'])): return $_SERVER['HTTP_CLIENT_IP'];
		case (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])): return $_SERVER['HTTP_X_FORWARDED_FOR'];
		default: return $_SERVER['REMOTE_ADDR'];
	}
}

function responseSuccess($RESPONSE_CODE, $MESSAGE)
{
	http_response_code($RESPONSE_CODE);
	echo json_encode(["message" => $MESSAGE]);
	die();
}

function responseError($RESPONSE_CODE, $ERROR_CODE, $ERROR_MESSAGE)
{
	http_response_code($RESPONSE_CODE);
	echo json_encode(["code" => $ERROR_CODE, "message" => $ERROR_MESSAGE]);
	die();
}

function getTokenForUser($conn, $userID, $platform, $deviceID, $package)
{
	$finalToken = "";
	$TYPE = "APP_AUTHORIZATION";

	$result = MSSQL::queryP($conn, "SELECT token FROM USER_TOKENS WHERE userid = ? AND platform = ? AND deviceid = ? AND packagename = ? AND type = ?", [$userID, $platform, $deviceID, $package, $TYPE]);
	if (sqlsrv_num_rows($result) > 0)
	{
		$data = sqlsrv_fetch_array($result);
		$finalToken = $data["token"];
	}
	else
	{
		$finalToken = generateToken($userID, $deviceID);
		MSSQL::queryP($conn, "INSERT INTO USER_TOKENS (userid, token, createdAt, platform, deviceid, packagename, type) VALUES (?,?,GETDATE(),?,?,?,?)", [$userID, $finalToken, $platform, $deviceID, $package, $TYPE]);
	}

	return $finalToken;
}

function generateToken($userID, $deviceID)
{
	return Utils::c($userID) . Utils::c($userID . "_" . $deviceID . "_" . time() . "_" . rand(1, 200));
}

function checkAuthorization($conn, $headers, $callname = "")
{
	$AUTH_KEY = "Authorization";

	if (!isset($headers[$AUTH_KEY])) { http_response_code(401); echo json_encode(["code" => 0, "message" => "Operazione non autorizzata, rieffettuare il login (0)"]); die(); }
	if (trim($headers[$AUTH_KEY]) == "" || count(explode(" ", trim($headers[$AUTH_KEY]))) != 2) { http_response_code(401); echo json_encode(["code" => 1, "message" => "Operazione non autorizzata, rieffettuare il login (1)"]); die(); }

	$authorization = explode(" ", trim($headers[$AUTH_KEY]));
	$AUTHORIZATION_HEAD = $authorization[0];
	$USER_TOKEN = $authorization[1];

	if ($AUTHORIZATION_HEAD != "Token") { http_response_code(401); echo json_encode(["code" => 2, "message" => "Operazione non autorizzata, rieffettuare il login (2)"]); die(); }

	$result = MSSQL::queryP($conn, "SELECT id FROM USER_TOKENS WHERE token = ? AND type = ?", [$USER_TOKEN, "APP_AUTHORIZATION"]);
	if (sqlsrv_num_rows($result) == 0) { http_response_code(401); echo json_encode(["code" => 3, "message" => "Operazione non autorizzata, rieffettuare il login ($callname)"]); die(); }
}

function checkClient($headers)
{
	if (!isset($headers["Client-Token"])) { http_response_code(401); echo json_encode(["code" => 0, "message" => "Client non autorizzato (0)"]); die(); }
	if (trim($headers["Client-Token"]) != trim(CLIENT_TOKEN)) { http_response_code(401); echo json_encode(["code" => 0, "message" => "Client non autorizzato (1)"]); die(); }
}

function tokenFromHeaders($headers)
{
	$AUTH_KEY = "Authorization";
	if (!isset($headers[$AUTH_KEY])) { return null; }
	if (trim($headers[$AUTH_KEY]) == "" || count(explode(" ", trim($headers[$AUTH_KEY]))) != 2) { return null; }

	$authorization = explode(" ", trim($headers[$AUTH_KEY]));
	if ($authorization[0] != "Token") { return null; }

	return $authorization[1];
}

function getUserByToken($conn, $userToken)
{
	$user = null;
	$result = MSSQL::queryP($conn, "SELECT * FROM UTENTI WHERE id = ( SELECT TOP 1 userid FROM USER_TOKENS WHERE token = ? AND type = ? )", [$userToken, "APP_AUTHORIZATION"]);
	if ($result !== false && sqlsrv_num_rows($result) > 0) { $user = sqlsrv_fetch_array($result, SQLSRV_FETCH_ASSOC); }
	return $user;
}

function checkParametri($chiaviDaCercare, $arrayAssociativo)
{
	foreach ($chiaviDaCercare as $chiave)
	{
		if (!array_key_exists($chiave, $arrayAssociativo) || !isset($arrayAssociativo[$chiave]) || is_null($arrayAssociativo[$chiave]))
		{
			responseError(400, 0, "Parametri mancanti o errati");
		}
	}
}
