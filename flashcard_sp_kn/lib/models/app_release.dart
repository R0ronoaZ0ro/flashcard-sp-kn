
class AppRelease {
  final String version;
  final int buildNumber;
  final List<String> releaseNotes;
  final String apkUrl;
  final String sha256;

  const AppRelease({
    required this.version,
    required this.buildNumber,
    required this.releaseNotes,
    required this.apkUrl,
    required this.sha256,
  });

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final buildNumber = json['build_number'];
    final notes = json['release_notes'];
    final apkUrl = json['apk_url'];
    final hash = json['sha256'];

    if (version is! String ||
        version.trim().isEmpty ||
        buildNumber is! int ||
        buildNumber < 1 ||
        apkUrl is! String ||
        apkUrl.trim().isEmpty ||
        hash is! String ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(hash)) {
      throw const FormatException(
        'El manifiesto de actualización no es válido.',
      );
    }

    if (!apkUrl.startsWith('http://') &&
        !apkUrl.startsWith('https://')) {
      throw const FormatException(
        'La URL del APK no es válida.',
      );
    }

    return AppRelease(
      version: version,
      buildNumber: buildNumber,
      releaseNotes: notes is List
          ? notes.whereType<String>().toList()
          : const [],
      apkUrl: apkUrl,
      sha256: hash.toLowerCase(),
    );
  }
}
