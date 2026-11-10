import 'dart:math';

import 'package:document_companion/modules/scanner/models/filter_type.dart';
import 'package:document_companion/modules/scanner/utils/document_image_processing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// A dark desk with a white, skewed sheet of paper on it.
const _corners = [
  Point<double>(150, 100),
  Point<double>(650, 140),
  Point<double>(600, 500),
  Point<double>(120, 460),
];

img.Image _deskWithPaper() {
  final image = img.Image(width: 800, height: 600);
  img.fill(image, color: img.ColorRgb8(45, 40, 38));
  img.fillPolygon(
    image,
    vertices: [for (final c in _corners) img.Point(c.x, c.y)],
    color: img.ColorRgb8(240, 240, 235),
  );
  return image;
}

void main() {
  group('detectDocumentCorners', () {
    test('finds the corners of a sheet on a dark background', () {
      final found = detectDocumentCorners(_deskWithPaper());

      expect(found, isNotNull);
      for (var i = 0; i < 4; i++) {
        expect(
          found![i].distanceTo(_corners[i]),
          lessThan(12),
          reason: 'corner $i was ${found[i]}, expected ${_corners[i]}',
        );
      }
    });

    test('returns null when there is no document', () {
      final blank = img.Image(width: 400, height: 300);
      img.fill(blank, color: img.ColorRgb8(200, 200, 200));
      expect(detectDocumentCorners(blank), isNull);
    });

    test('returns null for a bright shape that is not a quadrilateral', () {
      final image = img.Image(width: 400, height: 400);
      img.fill(image, color: img.ColorRgb8(30, 30, 30));
      // An L shape: its extreme points span far more area than it covers.
      img.fillRect(
        image,
        x1: 60,
        y1: 60,
        x2: 120,
        y2: 340,
        color: img.ColorRgb8(240, 240, 240),
      );
      img.fillRect(
        image,
        x1: 60,
        y1: 280,
        x2: 340,
        y2: 340,
        color: img.ColorRgb8(240, 240, 240),
      );
      expect(detectDocumentCorners(image), isNull);
    });
  });

  group('warpPerspective', () {
    test('straightens the sheet into a rectangle of matching size', () {
      final warped = warpPerspective(_deskWithPaper(), _corners);

      // Longest opposing edges of the quad.
      expect(warped.width, closeTo(_corners[0].distanceTo(_corners[1]), 2));
      expect(warped.height, closeTo(_corners[1].distanceTo(_corners[2]), 2));

      // The result is all paper: no desk left anywhere, including the edges.
      for (final (x, y) in [
        (4, 4),
        (warped.width - 5, 4),
        (4, warped.height - 5),
        (warped.width - 5, warped.height - 5),
        (warped.width ~/ 2, warped.height ~/ 2),
      ]) {
        expect(warped.getPixel(x, y).r, greaterThan(200), reason: '($x, $y)');
      }
    });

    test('maps each corner of the quad to the matching output corner', () {
      // Paint a distinct colour near each source corner.
      final image = _deskWithPaper();
      final marks = [
        img.ColorRgb8(255, 0, 0),
        img.ColorRgb8(0, 255, 0),
        img.ColorRgb8(0, 0, 255),
        img.ColorRgb8(255, 255, 0),
      ];
      final centre = Point<double>(380, 300);
      for (var i = 0; i < 4; i++) {
        // Slightly inside the sheet, towards its centre.
        final p = _corners[i] + (centre - _corners[i]) * 0.12;
        img.fillCircle(
          image,
          x: p.x.round(),
          y: p.y.round(),
          radius: 14,
          color: marks[i],
        );
      }

      final warped = warpPerspective(image, _corners);
      final w = warped.width, h = warped.height;
      // Where each mark must land, as fractions of the output size.
      const expected = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)];
      for (var i = 0; i < 4; i++) {
        var sumX = 0.0, sumY = 0.0, n = 0;
        for (final pixel in warped) {
          if (pixel.r == marks[i].r &&
              pixel.g == marks[i].g &&
              pixel.b == marks[i].b) {
            sumX += pixel.x;
            sumY += pixel.y;
            n++;
          }
        }
        expect(n, greaterThan(100), reason: 'mark $i is missing');
        expect(sumX / n / w, closeTo(expected[i].$1, 0.2), reason: 'mark $i x');
        expect(sumY / n / h, closeTo(expected[i].$2, 0.2), reason: 'mark $i y');
      }
    });
  });

  group('applyDocumentFilter', () {
    /// Paper lit unevenly (dim on the left, bright on the right) with a
    /// block of dark "text" and a red stamp.
    img.Image page() {
      final image = img.Image(width: 600, height: 400);
      for (var y = 0; y < 400; y++) {
        for (var x = 0; x < 600; x++) {
          final v = 120 + (x * 110 ~/ 600);
          image.setPixelRgb(x, y, v, v, v - 6);
        }
      }
      for (var y = 100; y < 300; y += 12) {
        img.fillRect(
          image,
          x1: 100,
          y1: y,
          x2: 500,
          y2: y + 3,
          color: img.ColorRgb8(35, 35, 40),
        );
      }
      img.fillRect(
        image,
        x1: 520,
        y1: 330,
        x2: 560,
        y2: 370,
        color: img.ColorRgb8(200, 40, 40),
      );
      return image;
    }

    test('natural leaves the image untouched', () {
      final source = page();
      expect(
        identical(applyDocumentFilter(source, FilterType.natural), source),
        isTrue,
      );
    });

    test('gray removes colour', () {
      final out = applyDocumentFilter(page(), FilterType.gray);
      final stamp = out.getPixel(540, 350);
      expect(stamp.r, stamp.g);
      expect(stamp.g, stamp.b);
      // ...without changing brightness of the paper.
      expect(out.getPixel(20, 20).r, closeTo(120, 4));
    });

    test('black & white gives white paper and black text despite shadows', () {
      final out = applyDocumentFilter(page(), FilterType.blackWhite);
      // Paper on the dim side and on the bright side both end up white.
      expect(out.getPixel(20, 200).r, greaterThan(245));
      expect(out.getPixel(580, 200).r, greaterThan(245));
      // Text on both sides is black.
      expect(out.getPixel(110, 101).r, lessThan(40));
      expect(out.getPixel(490, 101).r, lessThan(40));
    });

    test('enhance whitens paper evenly and keeps colour', () {
      final out = applyDocumentFilter(page(), FilterType.enhance);
      final left = out.getPixel(20, 200).r;
      final right = out.getPixel(580, 200).r;
      expect(left, greaterThan(235));
      expect((left - right).abs(), lessThan(8));

      final stamp = out.getPixel(540, 350);
      expect(stamp.r, greaterThan(stamp.g + 80));
      // Differs from every other filter.
      expect(stamp.r, isNot(stamp.b));
    });
  });

  test('isolate entry points round-trip JPEG bytes', () {
    final jpeg = img.encodeJpg(_deskWithPaper(), quality: 95);

    final corners = detectCornersInIsolate(jpeg);
    expect(corners, hasLength(8));

    final warped = img.decodeJpg(warpInIsolate((jpeg, corners!))!)!;
    expect(warped.width, closeTo(500, 15));
    expect(
      warped.getPixel(warped.width ~/ 2, warped.height ~/ 2).r,
      greaterThan(200),
    );

    expect(identical(filterInIsolate((jpeg, 'natural')), jpeg), isTrue);
    final bw = img.decodeJpg(filterInIsolate((jpeg, 'blackWhite')))!;
    expect(bw.width, 800);
  });
}
