/// Where DueDesk keeps the workspace.
enum StorageMode {
  /// Records and attachments are written as files on this device's drive.
  device,

  /// Records live on the organisation's self-hosted DueDesk server.
  server,
}

class StorageSettings {
  final StorageMode mode;
  final String serverUrl;
  const StorageSettings({required this.mode, this.serverUrl = ''});
  bool get isDevice => mode == StorageMode.device;
  bool get isServer => mode == StorageMode.server;
}

/// Checks a self-hosted server address and returns it normalised, without a
/// trailing slash. HTTPS is required, except for addresses that stay on the
/// local network (localhost, private IPv4 ranges and `.local` hosts).
({String? url, String? error}) parseServerUrl(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return (url: null, error: 'Enter your server address.');
  if (!text.contains('://')) text = 'https://$text';
  final uri = Uri.tryParse(text);
  if (uri == null ||
      uri.host.isEmpty ||
      !['https', 'http'].contains(uri.scheme) ||
      uri.hasQuery ||
      uri.hasFragment ||
      uri.userInfo.isNotEmpty) {
    return (
      url: null,
      error: 'Enter a valid address, like https://due.example.com.',
    );
  }
  if (uri.scheme == 'http' && !isLocalNetworkHost(uri.host)) {
    return (
      url: null,
      error: 'Use https:// for servers outside your local network.',
    );
  }
  var url = uri.toString();
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  return (url: url, error: null);
}

bool isLocalNetworkHost(String host) {
  final h = host.toLowerCase();
  if (h == 'localhost' || h.endsWith('.local') || h == '::1' || h == '[::1]') {
    return true;
  }
  final parts = h.split('.').map(int.tryParse).toList();
  if (parts.length != 4 || parts.any((p) => p == null || p < 0 || p > 255)) {
    return false;
  }
  final a = parts[0]!, b = parts[1]!;
  return a == 10 ||
      a == 127 ||
      (a == 192 && b == 168) ||
      (a == 172 && b >= 16 && b <= 31);
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
