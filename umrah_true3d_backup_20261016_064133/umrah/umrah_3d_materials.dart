import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Photographic materials on the original interactive 3D geometry.
/// No WebView, remote textures, new renderer or additional dependencies.
class Umrah3DMaterials {
  const Umrah3DMaterials(this.front, this.side, this.marble);
  final ui.Image front;
  final ui.Image side;
  final ui.Image marble;

  static Future<Umrah3DMaterials>? _instance;
  static Future<Umrah3DMaterials> load() => _instance ??= _load();

  static Future<Umrah3DMaterials> _load() async {
    Future<ui.Image> read(String file) async {
      final bytes = await rootBundle.load('assets/umrah/$file');
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      try {
        return (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
    }

    return Umrah3DMaterials(
      await read('kaaba_front_texture.jpg'),
      await read('kaaba_side_texture.jpg'),
      await read('haram_marble.jpg'),
    );
  }

  /// The 3D camera projects each polygon corner; a subdivided triangle mesh
  /// maps image pixels to the projected face while the user orbits the scene.
  static void quad(
    Canvas canvas,
    List<Offset> corners,
    ui.Image texture, {
    double opacity = 1,
    double repeatX = 1,
    double repeatY = 1,
    int subdivisions = 10,
  }) {
    if (corners.length != 4) return;
    final points = <Offset>[];
    final uv = <Offset>[];
    final tris = <int>[];
    final width = texture.width.toDouble();
    final height = texture.height.toDouble();
    for (var r = 0; r <= subdivisions; r++) {
      final v = r / subdivisions;
      final left = Offset.lerp(corners[0], corners[3], v)!;
      final right = Offset.lerp(corners[1], corners[2], v)!;
      for (var col = 0; col <= subdivisions; col++) {
        final u = col / subdivisions;
        points.add(Offset.lerp(left, right, u)!);
        uv.add(Offset(u * width * repeatX, v * height * repeatY));
      }
    }
    final stride = subdivisions + 1;
    for (var r = 0; r < subdivisions; r++) {
      for (var col = 0; col < subdivisions; col++) {
        final a = r * stride + col;
        final b = a + 1;
        final d = a + stride;
        final e = d + 1;
        tris.addAll([a, b, d, b, e, d]);
      }
    }
    final matrix = Float64List(16);
    matrix[0] = matrix[5] = matrix[10] = matrix[15] = 1;
    final shader = ui.ImageShader(
      texture,
      ui.TileMode.repeated,
      ui.TileMode.repeated,
      matrix,
      filterQuality: FilterQuality.medium,
    );
    final vertices = ui.Vertices(ui.VertexMode.triangles, points,
        textureCoordinates: uv, indices: tris);
    canvas.drawVertices(
        vertices,
        BlendMode.modulate,
        Paint()
          ..shader = shader
          ..color = Colors.white.withOpacity(opacity)
          ..isAntiAlias = true);
    vertices.dispose();
    shader.dispose();
  }
}
