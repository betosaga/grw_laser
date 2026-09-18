<?php
// Run in a separate PHP process: all database/logger calls below are local fakes.
// The production bootstrap is removed before evaluating the real dispatcher.
class Logger
{
    public static $calls = [];
    public static function logAPI(...$args) { self::$calls[] = $args; }
}

class MSSQL
{
    public static $logPost;
    public static function queryP_IDV($conn, $sql, $params)
    {
        self::$logPost = $params[6];
        return 1;
    }
    public static function queryP($conn, $sql, $params) { return true; }
}

function apache_request_headers()
{
    return ["Client-Token" => CLIENT_TOKEN, "Authorization" => "Token test-only"];
}
function sqlsrv_num_rows($result) { return 1; }
function sqlsrv_fetch_array($result, $mode)
{
    return ["id" => 1, "username" => "test-user"];
}
define("SQLSRV_FETCH_ASSOC", 2);

$command = $argv[1] ?? "WELD";
$payload = json_encode([
    "f" => $command,
    "path.base_points" => [[1.5, 2, 3], [4, 5, 6]],
    "custom" => ["nullable" => null, "enabled" => false, "label" => "prova è & +"],
    "large" => array_fill(0, 2000, [1, 2, 3, 4, 5, 6]),
]);
$_POST = [
    "f" => "logRobotLaserCommand",
    "comando" => $command,
    "seriale_robot" => "ROBOT-TEST",
    "destinazione" => $command === "WELD" ? "tcp://127.0.0.1:20002" : "http://127.0.0.2/interpola",
    "dataora_client" => "2026-09-18T12:00:00.000Z",
    "stato_invio" => $command === "WELD" ? "socket_write_attempted" : "request_started",
    "parametri_json" => $payload,
];
$_FILES = [];
$_SERVER["REMOTE_ADDR"] = "127.0.0.1";
$conn = null;
$source = file_get_contents(__DIR__ . "/../api.php");
$source = str_replace('require_once("../../settings.php");', '', $source, $replacements);
if ($replacements !== 1) { throw new RuntimeException("Unexpected API bootstrap; aborting test"); }

ob_start();
eval("?>" . $source);
$body = ob_get_clean();
if (http_response_code() !== 200 || json_decode($body, true)["message"] !== "Richiesta comando registrata")
{
    throw new RuntimeException("Unexpected API response: " . $body);
}
if (count(Logger::$calls) !== 1 || Logger::$calls[0][0] !== "SAGAGRWLASER" ||
    strpos(Logger::$calls[0][1], $payload) === false ||
    json_decode(MSSQL::$logPost, true)["parametri_json"] !== $payload)
{
    throw new RuntimeException("Missing, duplicated or altered command log");
}
echo "$command: dispatcher, authentication and complete Logger/LOGS payload OK\n";
