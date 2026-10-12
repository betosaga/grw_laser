/// Combina le due rappresentazioni storiche: ip_server e host/porta separati.
/// In lettura ip_server conserva anche l'assenza della porta per lo stesso host.
/// Una porta del catalogo si applica solo quando viene modificata esplicitamente.
class LaserServerAddress {
  static Uri? parse(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text.contains('://') ? text : 'http://$text');
    return uri != null && uri.host.isNotEmpty ? uri : null;
  }

  static int? portOf(String value) {
    final uri = parse(value);
    if (uri == null) return null;
    // Uri normalizza via le porte standard (http:80, https:443).
    final explicit = RegExp(r':(\d+)/?$').firstMatch(value.trim());
    return explicit != null
        ? int.tryParse(explicit.group(1)!)
        : uri.hasPort
        ? uri.port
        : null;
  }

  static String resolve({
    required String legacy,
    String? host,
    dynamic port,
    bool hostChanged = false,
    bool portChanged = false,
  }) {
    final raw = host?.trim().isNotEmpty == true ? host!.trim() : legacy.trim();
    final current = parse(raw);
    if (current == null) return raw;
    final previous = parse(legacy);
    final configuredPort = int.tryParse(port?.toString() ?? '');
    final validPort =
        configuredPort != null && configuredPort > 0 && configuredPort <= 65535
        ? configuredPort
        : null;
    final explicitPort = portOf(raw);
    final int? resolvedPort;
    if (portChanged) {
      resolvedPort = validPort;
    } else if (hostChanged) {
      resolvedPort = explicitPort;
    } else if (previous?.host == current.host) {
      resolvedPort = portOf(legacy);
    } else {
      resolvedPort = explicitPort;
    }
    final scheme = raw.contains('://') ? '${current.scheme}://' : '';
    final hostname = current.host.contains(':')
        ? '[${current.host}]'
        : current.host;
    return '$scheme$hostname${resolvedPort == null ? '' : ':$resolvedPort'}';
  }
}
