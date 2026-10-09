<?php
// Run with: php -d short_open_tag=1 test/api_robot_parameters_test.php
// Load the real API helpers without the production bootstrap or dispatcher.
$_POST = [];
$source = file_get_contents(__DIR__ . '/../api.php');
$source = str_replace('require_once("../../settings.php");', '', $source, $replacements);
if ($replacements !== 1) { throw new RuntimeException('Unexpected API bootstrap'); }
eval('?>' . $source);

function expectParameterValue($actual, $expected)
{
    if ($actual !== $expected)
    {
        throw new RuntimeException('Expected ' . var_export($expected, true) . ', got ' . var_export($actual, true));
    }
}

$cases = [
    ['path.point_order', 'array<int>', [0, 2, 1]],
    ['path.perimeter_order', 'array<int>', []],
    ['path.base_curve_indices', 'array<int>', [0, 1]],
    ['path.limit_curve_indices', 'array<int>', [2, 3]],
    ['layer.preview_offsets_mm', 'array<double>', [0.5, 1.5]],
    ['motion.points', 'array<posj>', [[1, 2, 3, 4, 5, 6]]],
    ['path.base_points', 'array', [[1, 2, 3, 4, 5, 6]]],
];

foreach ($cases as [$name, $type, $value])
{
    $definition = ['parametro' => $name, 'tipo' => $type, 'nullable' => true];
    // Both the general settings screen and the JSON text editor must round-trip.
    foreach ([$value, json_encode($value)] as $input)
    {
        [$stored, $error] = normalizeRobotLaserParametroValueForStorage($input, $definition);
        expectParameterValue($error, null);
        expectParameterValue(robotLaserParametroValueFromStorage($stored, $type), $value);
    }
    expectParameterValue(normalizeRobotLaserParametroValueForStorage(null, $definition), [null, null]);
    expectParameterValue(robotLaserParametroValueFromStorage(null, $type), null);
    [$stored, $error] = normalizeRobotLaserParametroValueForStorage('[invalid', $definition);
    expectParameterValue($stored, false);
    expectParameterValue($error, 'Il parametro ' . $name . ' non contiene JSON valido');
}

// Actual text parameters must still reject structured values.
$textDefinition = ['parametro' => 'network.fastapi.host', 'tipo' => 'string', 'nullable' => false];
expectParameterValue(
    normalizeRobotLaserParametroValueForStorage([0, 1], $textDefinition),
    [false, 'Il parametro network.fastapi.host deve essere testuale']
);
expectParameterValue(
    normalizeRobotLaserParametroValueForStorage('localhost', $textDefinition),
    ['localhost', null]
);
echo "Robot parameters: typed array saving, reading and validation OK\n";

// Exercise the actual save/read endpoints with an in-memory SQL adapter.
define('SQLSRV_FETCH_ASSOC', 2);
function apache_request_headers() { return ['Client-Token' => CLIENT_TOKEN, 'Authorization' => 'Token test']; }
function sqlsrv_num_rows($result) { return $result->count(); }
function sqlsrv_fetch_array($result, $mode)
{
    if (!$result->valid()) { return null; }
    $row = $result->current();
    $result->next();
    return $row;
}

class MSSQL
{
    public static $robot = [
        'seriale_robot' => 'TEST', 'ip_robot' => '127.0.0.1', 'ip_server' => '127.0.0.2:8000',
        'pin_gas' => '1', 'pin_laser' => '3', 'pin_massa' => '4',
        'allontanamento_x' => 0, 'allontanamento_y' => 0, 'allontanamento_z' => 0,
    ];
    public static $definitions = [
        'network.fastapi.host' => ['string', '127.0.0.2:8000'],
        'network.fastapi.port' => ['int', '8000'],
        'io.gas_output_pin' => ['int', '1'],
        'io.laser_output_pin' => ['int', '3'],
        'io.mass_output_pin' => ['int', '4'],
        'path.weld_width_mm' => ['double', '3.5'],
    ];
    public static $values = [];
    public static $commits = 0;
    public static function begin($conn, $db) {}
    public static function commit($conn, $db) { self::$commits++; }
    public static function rollback($conn, $db) { throw new RuntimeException('Unexpected rollback'); }
    public static function queryP($conn, $sql, $params)
    {
        if (strpos($sql, 'FROM USER_TOKENS') !== false || strpos($sql, 'SELECT id FROM ROBOT_LASER') !== false)
        {
            return new ArrayIterator([['id' => 1]]);
        }
        if (strpos($sql, 'FROM rsw.dbo.ROBOT_LASER_PARAMETRO p') !== false)
        {
            $rows = [];
            foreach (self::$definitions as $key => [$type, $default])
            {
                $rows[] = [
                    'parametro' => $key, 'tipo' => $type, 'nullable' => false,
                    'valore' => self::$values[$key] ?? $default, 'valore_default' => $default,
                    'valori_ammessi_json' => null, 'categoria' => 'Test', 'descrizione' => null,
                    'ordine' => 0, 'modificabile' => true, 'personalizzato' => array_key_exists($key, self::$values),
                ];
            }
            return new ArrayIterator($rows);
        }
        if (strpos($sql, 'UPDATE rsw.dbo.ROBOT_LASER_PARAMETRI') !== false)
        {
            self::$values[$params[2]] = $params[0];
            return true;
        }
        if (strpos($sql, 'UPDATE ROBOT_LASER SET') !== false)
        {
            foreach (array_keys(self::$robot) as $index => $key) { self::$robot[$key] = $params[$index]; }
            return true;
        }
        if (strpos($sql, 'FROM ROBOT_LASER WHERE') !== false) { return new ArrayIterator([self::$robot]); }
        if (strpos($sql, 'FROM rsw.dbo.ROBOT_LASER_LIMITI') !== false) { return new ArrayIterator([]); }
        throw new RuntimeException('Unexpected SQL: ' . $sql);
    }
}

function endpointResult($function, $post)
{
    ob_start();
    $function(null, $post);
    return json_decode(ob_get_clean(), true, 512, JSON_THROW_ON_ERROR);
}
function parameterValues($response) { return array_column($response['parametri'], 'valore', 'parametro'); }

// A base form restored from an older cache may not have any catalog parameters.
$post = array_merge(MSSQL::$robot, ['seriale_start' => 'TEST', 'ip_server' => '192.168.1.42:9001']);
$saved = endpointResult('setImpostazioniRobotLaser', $post);
expectParameterValue($saved['ip_server'], '192.168.1.42:9001');
expectParameterValue(parameterValues($saved)['network.fastapi.host'], '192.168.1.42:9001');
$reloaded = endpointResult('getRobotLaserDetail', ['seriale_robot' => 'TEST']);
expectParameterValue(parameterValues($reloaded)['network.fastapi.host'], '192.168.1.42:9001');

// "All parameters" must update both representations even with an old flat IP.
$post = array_merge(MSSQL::$robot, ['seriale_start' => 'TEST', 'parametri' => json_encode([
    ['parametro' => 'network.fastapi.host', 'valore' => '192.168.1.43'],
    ['parametro' => 'network.fastapi.port', 'valore' => 9002],
    ['parametro' => 'path.weld_width_mm', 'valore' => 4.5],
    ['parametro' => 'io.gas_output_pin', 'valore' => 8],
])]);
$saved = endpointResult('setImpostazioniRobotLaser', $post);
expectParameterValue($saved['ip_server'], '192.168.1.43:9002');
expectParameterValue($saved['pin_gas'], '8');
$reloaded = endpointResult('getRobotLaserDetail', ['seriale_robot' => 'TEST']);
expectParameterValue(parameterValues($reloaded)['network.fastapi.host'], '192.168.1.43');
expectParameterValue(parameterValues($reloaded)['network.fastapi.port'], 9002);
expectParameterValue(parameterValues($reloaded)['path.weld_width_mm'], 4.5);
expectParameterValue(parameterValues($reloaded)['io.gas_output_pin'], 8);
expectParameterValue(MSSQL::$commits, 2);
echo "Robot settings: base form, parameter form, database commit and reload OK\n";

// Regression: a bare catalog host must not erase the port stored on the robot.
MSSQL::$robot['ip_server'] = '192.168.10.13:8824';
MSSQL::$values['network.fastapi.host'] = '192.168.10.13';
MSSQL::$values['network.fastapi.port'] = '8000';
$reloaded = endpointResult('getRobotLaserDetail', ['seriale_robot' => 'TEST']);
expectParameterValue($reloaded['ip_server'], '192.168.10.13:8824');
$post = array_merge(MSSQL::$robot, ['seriale_start' => 'TEST', 'parametri' => json_encode([
    ['parametro' => 'network.fastapi.host', 'valore' => '192.168.10.13'],
])]);
$saved = endpointResult('setImpostazioniRobotLaser', $post);
expectParameterValue($saved['ip_server'], '192.168.10.13:8824');
expectParameterValue(MSSQL::$robot['ip_server'], '192.168.10.13:8824');

// Changing the separate port must take effect even if ip_server has an old port.
$post['parametri'] = json_encode([
    ['parametro' => 'network.fastapi.port', 'valore' => 9003],
]);
$saved = endpointResult('setImpostazioniRobotLaser', $post);
expectParameterValue($saved['ip_server'], '192.168.10.13:9003');
$reloaded = endpointResult('getRobotLaserDetail', ['seriale_robot' => 'TEST']);
expectParameterValue($reloaded['ip_server'], '192.168.10.13:9003');

// The base field also keeps the separate port consistent.
$post = array_merge(MSSQL::$robot, ['seriale_start' => 'TEST', 'ip_server' => '192.168.10.13:8824']);
$saved = endpointResult('setImpostazioniRobotLaser', $post);
expectParameterValue($saved['ip_server'], '192.168.10.13:8824');
expectParameterValue(parameterValues($saved)['network.fastapi.port'], 8824);
echo "Server address: port 8824 preserved on read/save, separate port changes and reload OK\n";
