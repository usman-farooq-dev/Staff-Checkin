import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final sourceFile = File('assets/images/app_icon_foreground.png');
  if (!sourceFile.existsSync()) {
    print('Source file not found');
    return;
  }

  final rawBytes = sourceFile.readAsBytesSync();
  final source = img.decodeImage(rawBytes);
  if (source == null) {
    print('Failed to decode source image');
    return;
  }

  final bgColor = img.ColorRgba8(183, 57, 44, 255); // #B7392C dark red

  // ─── 1. FULL ICON (non-adaptive: iOS + older Android) ─────────────────
  // Red background with white icon composited on top
  final fullIcon = img.Image(width: 1024, height: 1024);
  img.fill(fullIcon, color: bgColor);

  final scaledFg = img.copyResize(source, width: 780, height: 780,
      interpolation: img.Interpolation.linear);
  img.compositeImage(fullIcon, scaledFg,
      dstX: (1024 - 780) ~/ 2, dstY: (1024 - 780) ~/ 2);

  File('assets/images/app_icon.png').writeAsBytesSync(img.encodePng(fullIcon));
  print('✓ Created app_icon.png (1024x1024, red bg)');

  // ─── 2. ADAPTIVE FOREGROUND (Android 8+) ──────────────────────────────
  // The background color #B7392C comes from colors.xml
  // The foreground must be white icon on TRANSPARENT background
  // We detect and strip the red/dark background from source image first

  // Create transparent canvas
  final adaptiveFg = img.Image(width: 1024, height: 1024);
  img.fill(adaptiveFg, color: img.ColorRgba8(0, 0, 0, 0));

  // Try to create a clean white-on-transparent version:
  // If source has dark or colored background pixels, make them transparent
  final cleanedSource = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );

  for (int y = 0; y < source.height; y++) {
    for (int x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      final a = source.numChannels >= 4 ? pixel.a.toInt() : 255;

      // If pixel is already transparent, keep it
      if (a < 30) {
        cleanedSource.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }

      // If pixel looks like the red background (#B7392C ± tolerance)
      // or very dark (background artifact), make it transparent
      final isRedBg = r > 140 && r < 220 && g < 80 && b < 70;
      final isDarkBg = r < 50 && g < 50 && b < 50;

      if (isRedBg || isDarkBg) {
        cleanedSource.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        cleanedSource.setPixelRgba(x, y, r, g, b, a);
      }
    }
  }

  // Scale cleaned foreground to 820x820 inside 1024x1024 canvas
  final scaledAdapt = img.copyResize(cleanedSource, width: 820, height: 820,
      interpolation: img.Interpolation.linear);
  img.compositeImage(adaptiveFg, scaledAdapt,
      dstX: (1024 - 820) ~/ 2, dstY: (1024 - 820) ~/ 2);

  File('assets/images/app_icon.png')
      .writeAsBytesSync(img.encodePng(adaptiveFg));
  print('✓ Created app_icon.png (transparent bg)');
}
