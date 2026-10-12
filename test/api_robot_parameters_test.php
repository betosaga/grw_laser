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

class TestRollback extends RuntimeException {}

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
    public static $modes = [
        ['id_robot' => 1, 'id' => 2, 'nome' => 'Semplice', 'codice' => 'controrotaiasemplice'],
        ['id_robot' => 2, 'id' => 3, 'nome' => 'Piano', 'codice' => 'piano'],
    ];
    public static $values = [];
    public static $commits = 0;
    public static $robotWrites = 0;
    public static $parameterWrites = 0;
    public static $failParameter = null;
    private static $snapshot;
    public static function begin($conn, $db) { self::$snapshot = [self::$robot, self::$values]; }
    public static function commit($conn, $db) { self::$commits++; }
    public static function rollback($conn, $db)
    {
        [self::$robot, self::$values] = self::$snapshot;
        throw new TestRollback('Transaction rolled back');
    }
    public static function queryP($conn, $sql, $params)
    {
        if (strpos($sql, 'INNER JOIN rsw.dbo.ROBOT_LASER_LAVORAZIONI m') !== false)
        {
            if (strpos($sql, 'FROM rsw.dbo.ROBOT_LASER_LAVORAZIONI_ABILITATE a') === false ||
                strpos($sql, 'a.id_robot = r.id AND a.modalita = m.id') === false ||
                strpos($sql, 'WHERE r.abilitato = 1') === false) {
                throw new RuntimeException('Modes must be scoped to enabled robots and their associations');
            }
            $rows = self::$modes;
            if ($params !== []) {
                expectParameterValue($params, ['TEST']);
                $rows = array_values(array_filter($rows, function ($row) { return $row['id_robot'] === 1; }));
            }
            return new ArrayIterator($rows);
        }
        if (strpos($sql, 'SELECT id, seriale_robot, color FROM rsw.dbo.ROBOT_LASER') !== false)
        {
            return new ArrayIterator([
                ['id' => 1, 'seriale_robot' => 'TEST', 'color' => ''],
                ['id' => 2, 'seriale_robot' => 'OTHER', 'color' => ''],
                ['id' => 3, 'seriale_robot' => 'NO-MODES', 'color' => ''],
            ]);
        }
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
            if ($params[2] === self::$failParameter) { return false; }
            self::$parameterWrites++;
            self::$values[$params[2]] = $params[0];
            return true;
        }
        if (strpos($sql, 'UPDATE ROBOT_LASER SET') !== false)
        {
            self::$robotWrites++;
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

// The two tables deliberately disagree about host, port and all pins.
MSSQL::$values = [
    'network.fastapi.host' => '10.99.0.10:9000', 'network.fastapi.port' => '9001',
    'io.gas_output_pin' => '71', 'io.laser_output_pin' => '73', 'io.mass_output_pin' => '74',
];
foreach (['192.168.10.13', '192.168.10.13:8824', ''] as $address)
{
    MSSQL::$robot['ip_server'] = $address;
    foreach (['getRobotLaserDetail', 'getImpostazioniRobotLaser'] as $endpoint)
    {
        $read = endpointResult($endpoint, ['seriale_robot' => 'TEST']);
        foreach (['ip_robot', 'ip_server', 'pin_gas', 'pin_laser', 'pin_massa'] as $key)
        {
            expectParameterValue($read[$key], MSSQL::$robot[$key]);
        }
    }
    $beforeParameters = MSSQL::$values;
    $writes = MSSQL::$parameterWrites;
    $post = array_merge(MSSQL::$robot, [
        'seriale_start' => 'TEST', 'ip_robot' => '192.168.10.12',
        'pin_gas' => '2', 'pin_laser' => '5', 'pin_massa' => '6',
        // The copy must use the saved ROBOT_LASER row, not catalog input.
        'parametri' => json_encode(['network.fastapi.host' => 'should-not-be-saved']),
    ]);
    $saved = endpointResult('setImpostazioniRobotLaser', $post);
    foreach (['ip_robot', 'ip_server', 'pin_gas', 'pin_laser', 'pin_massa'] as $key)
    {
        expectParameterValue($saved[$key], $post[$key]);
        expectParameterValue(MSSQL::$robot[$key], $post[$key]);
    }
    $expectedParameters = array_merge($beforeParameters, [
        'network.fastapi.host' => $address,
        'io.gas_output_pin' => '2', 'io.laser_output_pin' => '5', 'io.mass_output_pin' => '6',
    ]);
    expectParameterValue(MSSQL::$values, $expectedParameters);
    expectParameterValue(MSSQL::$parameterWrites, $writes + 4);
    expectParameterValue(parameterValues($saved)['network.fastapi.host'], $address);
    expectParameterValue(parameterValues($saved)['network.fastapi.port'], 9001);
    expectParameterValue(parameterValues($saved)['io.gas_output_pin'], 2);
    expectParameterValue(parameterValues($saved)['io.laser_output_pin'], 5);
    expectParameterValue(parameterValues($saved)['io.mass_output_pin'], 6);
}

// The parameter endpoint writes only the catalog, never ROBOT_LASER.
$beforeRobot = MSSQL::$robot;
$writes = MSSQL::$robotWrites;
$saved = endpointResult('setParametriRobotLaser', [
    'seriale_robot' => 'TEST',
    'parametri' => json_encode([
        ['parametro' => 'network.fastapi.host', 'valore' => '10.98.0.10:9900'],
        ['parametro' => 'io.gas_output_pin', 'valore' => 81],
        ['parametro' => 'io.laser_output_pin', 'valore' => 83],
        ['parametro' => 'io.mass_output_pin', 'valore' => 84],
        ['parametro' => 'path.weld_width_mm', 'valore' => 4.5],
    ]),
]);
expectParameterValue(MSSQL::$robot, $beforeRobot);
expectParameterValue(MSSQL::$robotWrites, $writes);
expectParameterValue(parameterValues($saved)['network.fastapi.host'], '10.98.0.10:9900');
expectParameterValue(parameterValues($saved)['network.fastapi.port'], 9001);
expectParameterValue(parameterValues($saved)['io.gas_output_pin'], 81);
expectParameterValue(parameterValues($saved)['io.laser_output_pin'], 83);
expectParameterValue(parameterValues($saved)['io.mass_output_pin'], 84);
expectParameterValue(parameterValues($saved)['path.weld_width_mm'], 4.5);
$reloaded = endpointResult('getRobotLaserDetail', ['seriale_robot' => 'TEST']);
foreach (['ip_robot', 'ip_server', 'pin_gas', 'pin_laser', 'pin_massa'] as $key)
{
    expectParameterValue($reloaded[$key], $beforeRobot[$key]);
}
expectParameterValue(MSSQL::$commits, 4);
// Saving base settings again replaces catalog overrides only for copied fields.
$saved = endpointResult('setImpostazioniRobotLaser', array_merge(MSSQL::$robot, ['seriale_start' => 'TEST']));
expectParameterValue(parameterValues($saved)['network.fastapi.host'], $beforeRobot['ip_server']);
expectParameterValue(parameterValues($saved)['io.gas_output_pin'], 2);
expectParameterValue(parameterValues($saved)['io.laser_output_pin'], 5);
expectParameterValue(parameterValues($saved)['io.mass_output_pin'], 6);
expectParameterValue(parameterValues($saved)['network.fastapi.port'], 9001);
expectParameterValue(parameterValues($saved)['path.weld_width_mm'], 4.5);
expectParameterValue(MSSQL::$robot, $beforeRobot);
expectParameterValue(MSSQL::$commits, 5);
// A failed catalog copy must roll back the base update and preceding copies.
$beforeParameters = MSSQL::$values;
MSSQL::$failParameter = 'io.laser_output_pin';
try {
    setImpostazioniRobotLaser(null, array_merge(MSSQL::$robot, [
        'seriale_start' => 'TEST', 'ip_server' => '192.168.10.77', 'pin_gas' => '7',
    ]));
    throw new RuntimeException('Expected rollback on catalog failure');
} catch (TestRollback $error) {
    expectParameterValue(MSSQL::$robot, $beforeRobot);
    expectParameterValue(MSSQL::$values, $beforeParameters);
    expectParameterValue(MSSQL::$commits, 5);
}
echo "Robot settings: one-way ROBOT_LASER -> catalog copy, exact addresses and reload OK\n";

// List and every detail/save response expose the same per-robot permissions.
$list = endpointResult('getRobotLaserList', []);
expectParameterValue(array_column($list[0]['modalita_abilitate'], 'codice'), ['controrotaiasemplice']);
expectParameterValue(array_column($list[1]['modalita_abilitate'], 'codice'), ['piano']);
expectParameterValue($list[2]['modalita_abilitate'], []);
expectParameterValue($saved['modalita_abilitate'], $list[0]['modalita_abilitate']);
expectParameterValue($reloaded['modalita_abilitate'], $list[0]['modalita_abilitate']);
MSSQL::$modes = [];
foreach (['getRobotLaserDetail', 'getImpostazioniRobotLaser'] as $endpoint) {
    expectParameterValue(endpointResult($endpoint, ['seriale_robot' => 'TEST'])['modalita_abilitate'], []);
}
echo "Robot modes: per-robot lists, details, saves and empty permissions OK\n";
