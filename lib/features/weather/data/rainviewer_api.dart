import 'dart:convert';

import 'package:http/http.dart' as http;

/// Client for the RainViewer public weather maps API.
///
/// Fetches available radar frame timestamps and provides tile URL templates
/// for rendering precipitation data on a map.
class RainViewerApi {
  RainViewerApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _mapsEndpoint =
      'https://api.rainviewer.com/public/weather-maps.json';

  /// Fetches the current list of available radar frames.
  ///
  /// Returns a [RadarMapData] containing the host, past frame timestamps,
  /// and the generated tile URL for each frame.
  Future<RadarMapData> fetchRadarFrames() async {
    final uri = Uri.parse(_mapsEndpoint);

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load radar data (${response.statusCode})',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;

    return RadarMapData.fromJson(json);
  }

  void dispose() {
    _client.close();
  }
}

/// Parsed response from the RainViewer weather maps endpoint.
class RadarMapData {
  RadarMapData({
    required this.generated,
    required this.host,
    required this.pastFrames,
  });

  /// Unix timestamp when this data was generated.
  final int generated;

  /// The tile host URL prefix (e.g. "https://tilecache.rainviewer.com").
  final String host;

  /// List of past radar frames, ordered oldest → newest.
  final List<RadarFrame> pastFrames;

  factory RadarMapData.fromJson(Map<String, dynamic> json) {
    final host = json['host'] as String? ?? 'https://tilecache.rainviewer.com';
    final generated = json['generated'] as int? ?? 0;

    final radarJson = json['radar'] as Map<String, dynamic>?;
    final pastList = radarJson?['past'] as List<dynamic>? ?? [];

    final pastFrames = pastList.map((frame) {
      final frameMap = frame as Map<String, dynamic>;
      return RadarFrame(
        timestamp: frameMap['time'] as int,
        path: frameMap['path'] as String,
        host: host,
      );
    }).toList();

    return RadarMapData(
      generated: generated,
      host: host,
      pastFrames: pastFrames,
    );
  }
}

/// A single radar frame with its timestamp and tile path.
class RadarFrame {
  RadarFrame({
    required this.timestamp,
    required this.path,
    required this.host,
  });

  /// Unix timestamp of this radar snapshot.
  final int timestamp;

  /// The path component for this frame (e.g. "/v2/radar/1678886400").
  final String path;

  /// The tile host URL.
  final String host;

  /// Returns the [DateTime] for this frame.
  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  /// Returns a human-readable relative time string like "12 min ago".
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Returns the tile URL template for use with flutter_map TileLayer.
  ///
  /// Parameters:
  /// - [size] — tile size (256 or 512). Default 256.
  /// - [colorScheme] — color scheme index. 1 = Universal Blue (only free option).
  /// - [smooth] — whether to smooth tiles. 1 = yes, 0 = no.
  /// - [snow] — whether to show snow. 1 = yes, 0 = no.
  String tileUrlTemplate({
    int size = 256,
    int colorScheme = 1,
    int smooth = 1,
    int snow = 1,
  }) {
    return '$host$path/$size/{z}/{x}/{y}/$colorScheme/${smooth}_$snow.png';
  }
}
