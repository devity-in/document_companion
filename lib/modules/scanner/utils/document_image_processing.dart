/// Pure-Dart document image processing: corner detection, perspective
/// correction and scan filters.
///
/// Everything here is a top-level function working on plain data so it can
/// run inside `compute()` and be unit tested without a device.
library;

import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../models/filter_type.dart';

/// Longest side, in pixels, that filters are applied at.
const maxFilterDimension = 2600;

/// Decodes [bytes] and applies the EXIF rotation, so pixel coordinates match
/// what the user sees on screen.
img.Image? decodeUpright(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final upright = decoded.exif.imageIfd.hasOrientation
      ? img.bakeOrientation(decoded)
      : decoded;
  return upright.numChannels == 3 && upright.format == img.Format.uint8
      ? upright
      : upright.convert(format: img.Format.uint8, numChannels: 3);
}

/// Tightly packed RGB bytes of [image].
Uint8List _rgbBytes(img.Image image) {
  final rgb = image.numChannels == 3 && image.format == img.Format.uint8
      ? image
      : image.convert(format: img.Format.uint8, numChannels: 3);
  return rgb.getBytes(order: img.ChannelOrder.rgb);
}

img.Image _fromRgb(Uint8List rgb, int width, int height) {
  return img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgb.buffer,
    numChannels: 3,
  );
}

/// Luminance (0-255) of every pixel of [image].
Uint8List _luminance(Uint8List rgb, int pixelCount) {
  final out = Uint8List(pixelCount);
  for (var i = 0, j = 0; i < pixelCount; i++, j += 3) {
    out[i] = (rgb[j] * 77 + rgb[j + 1] * 150 + rgb[j + 2] * 29) >> 8;
  }
  return out;
}

// ---------------------------------------------------------------------------
// Corner detection
// ---------------------------------------------------------------------------

/// Finds the four corners of a document in [image].
///
/// Returns `[topLeft, topRight, bottomRight, bottomLeft]` in pixel
/// coordinates of [image], or `null` when no plausible document is found (the
/// caller then offers a default crop area).
///
/// The page is assumed to be the largest bright region against a darker
/// background, which covers the usual "paper on a desk" photo. The image is
/// analysed at a small size, so this takes a few milliseconds.
List<Point<double>>? detectDocumentCorners(img.Image image) {
  const analysisSize = 320;
  final scale = analysisSize / max(image.width, image.height);
  final small = scale < 1
      ? img.copyResize(
          image,
          width: max(1, (image.width * scale).round()),
          height: max(1, (image.height * scale).round()),
          interpolation: img.Interpolation.average,
        )
      : image;
  final w = small.width;
  final h = small.height;
  final count = w * h;
  final blurred = img.gaussianBlur(small, radius: 2);
  final lum = _luminance(_rgbBytes(blurred), count);

  // Otsu's threshold separates page from background.
  final histogram = List<int>.filled(256, 0);
  for (final value in lum) {
    histogram[value]++;
  }
  var sumAll = 0.0;
  for (var i = 0; i < 256; i++) {
    sumAll += i * histogram[i];
  }
  var sumBack = 0.0;
  var weightBack = 0;
  var bestVariance = -1.0;
  var threshold = 127;
  for (var i = 0; i < 256; i++) {
    weightBack += histogram[i];
    if (weightBack == 0) continue;
    final weightFront = count - weightBack;
    if (weightFront == 0) break;
    sumBack += i * histogram[i];
    final meanBack = sumBack / weightBack;
    final meanFront = (sumAll - sumBack) / weightFront;
    final variance =
        weightBack *
        weightFront *
        (meanBack - meanFront) *
        (meanBack - meanFront);
    if (variance > bestVariance) {
      bestVariance = variance;
      threshold = i;
    }
  }

  // Largest connected bright region.
  final labels = Int32List(count);
  var bestLabel = 0;
  var bestSize = 0;
  var nextLabel = 0;
  final queue = Queue<int>();
  for (var start = 0; start < count; start++) {
    if (labels[start] != 0 || lum[start] <= threshold) continue;
    nextLabel++;
    var size = 0;
    labels[start] = nextLabel;
    queue.add(start);
    while (queue.isNotEmpty) {
      final index = queue.removeFirst();
      size++;
      final x = index % w;
      final y = index ~/ w;
      void visit(int nx, int ny) {
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) return;
        final neighbour = ny * w + nx;
        if (labels[neighbour] != 0 || lum[neighbour] <= threshold) return;
        labels[neighbour] = nextLabel;
        queue.add(neighbour);
      }

      visit(x - 1, y);
      visit(x + 1, y);
      visit(x, y - 1);
      visit(x, y + 1);
    }
    if (size > bestSize) {
      bestSize = size;
      bestLabel = nextLabel;
    }
  }

  // Too small to be the subject, or it already fills the frame.
  if (bestSize < count * 0.12 || bestSize > count * 0.95) return null;

  // The corners of a convex quad are its extreme points along the diagonals.
  var tl = const Point<int>(0, 0), tr = tl, br = tl, bl = tl;
  var minSum = 1 << 30, maxSum = -1, maxDiff = -(1 << 30), minDiff = 1 << 30;
  for (var index = 0; index < count; index++) {
    if (labels[index] != bestLabel) continue;
    final x = index % w;
    final y = index ~/ w;
    if (x + y < minSum) {
      minSum = x + y;
      tl = Point(x, y);
    }
    if (x + y > maxSum) {
      maxSum = x + y;
      br = Point(x, y);
    }
    if (x - y > maxDiff) {
      maxDiff = x - y;
      tr = Point(x, y);
    }
    if (x - y < minDiff) {
      minDiff = x - y;
      bl = Point(x, y);
    }
  }

  // The region must roughly be the quad it implies, otherwise it is some
  // other bright shape (a window, a lamp, a patterned table).
  final quadArea =
      ((tl.x * tr.y - tr.x * tl.y) +
              (tr.x * br.y - br.x * tr.y) +
              (br.x * bl.y - bl.x * br.y) +
              (bl.x * tl.y - tl.x * bl.y))
          .abs() /
      2;
  if (quadArea <= 0) return null;
  final fill = bestSize / quadArea;
  if (fill < 0.75 || fill > 1.25) return null;

  final back = 1 / (scale < 1 ? scale : 1);
  Point<double> restore(Point<int> p) => Point(
    (p.x * back).clamp(0, image.width - 1).toDouble(),
    (p.y * back).clamp(0, image.height - 1).toDouble(),
  );
  return [restore(tl), restore(tr), restore(br), restore(bl)];
}

// ---------------------------------------------------------------------------
// Perspective correction
// ---------------------------------------------------------------------------

/// Maps the quadrilateral given by [corners]
/// (`[topLeft, topRight, bottomRight, bottomLeft]`) onto an upright rectangle.
img.Image warpPerspective(img.Image image, List<Point<double>> corners) {
  final p0 = corners[0], p1 = corners[1], p2 = corners[2], p3 = corners[3];

  final outWidth = max(
    p0.distanceTo(p1),
    p3.distanceTo(p2),
  ).round().clamp(1, 6000);
  final outHeight = max(
    p0.distanceTo(p3),
    p1.distanceTo(p2),
  ).round().clamp(1, 6000);

  // Projective mapping from the unit square to the quad (Heckbert, 1989).
  final sx = p0.x - p1.x + p2.x - p3.x;
  final sy = p0.y - p1.y + p2.y - p3.y;
  double a, b, d, e, g, hh;
  final c = p0.x, f = p0.y;
  if (sx.abs() < 1e-9 && sy.abs() < 1e-9) {
    a = p1.x - p0.x;
    b = p3.x - p0.x;
    d = p1.y - p0.y;
    e = p3.y - p0.y;
    g = 0;
    hh = 0;
  } else {
    final dx1 = p1.x - p2.x, dx2 = p3.x - p2.x;
    final dy1 = p1.y - p2.y, dy2 = p3.y - p2.y;
    final den = dx1 * dy2 - dx2 * dy1;
    if (den.abs() < 1e-9) {
      throw ArgumentError('Crop corners do not form a quadrilateral');
    }
    g = (sx * dy2 - dx2 * sy) / den;
    hh = (dx1 * sy - sx * dy1) / den;
    a = p1.x - p0.x + g * p1.x;
    b = p3.x - p0.x + hh * p3.x;
    d = p1.y - p0.y + g * p1.y;
    e = p3.y - p0.y + hh * p3.y;
  }

  final src = _rgbBytes(image);
  final sw = image.width, sh = image.height;
  final out = Uint8List(outWidth * outHeight * 3);
  final uStep = outWidth > 1 ? 1 / (outWidth - 1) : 0.0;
  final vStep = outHeight > 1 ? 1 / (outHeight - 1) : 0.0;

  var o = 0;
  for (var y = 0; y < outHeight; y++) {
    final v = y * vStep;
    for (var x = 0; x < outWidth; x++) {
      final u = x * uStep;
      final wgt = g * u + hh * v + 1;
      var fx = (a * u + b * v + c) / wgt;
      var fy = (d * u + e * v + f) / wgt;
      if (fx < 0) fx = 0;
      if (fy < 0) fy = 0;
      if (fx > sw - 1) fx = sw - 1.0;
      if (fy > sh - 1) fy = sh - 1.0;

      // Bilinear sample.
      final x0 = fx.floor(), y0 = fy.floor();
      final x1 = x0 + 1 < sw ? x0 + 1 : x0;
      final y1 = y0 + 1 < sh ? y0 + 1 : y0;
      final tx = fx - x0, ty = fy - y0;
      final i00 = (y0 * sw + x0) * 3, i10 = (y0 * sw + x1) * 3;
      final i01 = (y1 * sw + x0) * 3, i11 = (y1 * sw + x1) * 3;
      for (var ch = 0; ch < 3; ch++) {
        final top = src[i00 + ch] + (src[i10 + ch] - src[i00 + ch]) * tx;
        final bottom = src[i01 + ch] + (src[i11 + ch] - src[i01 + ch]) * tx;
        out[o++] = (top + (bottom - top) * ty).round();
      }
    }
  }
  return _fromRgb(out, outWidth, outHeight);
}

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

/// Estimates the brightness of the paper around every pixel, ignoring text
/// and small marks, so that shadows and uneven lighting can be divided out.
///
/// Returns a coarse grid plus its dimensions; sample it with [_sampleGrid].
({Float32List grid, int columns, int rows, double cell}) _paperBrightness(
  Uint8List lum,
  int width,
  int height,
) {
  final cell = max(8.0, max(width, height) / 40);
  final columns = (width / cell).ceil();
  final rows = (height / cell).ceil();
  final raw = Float32List(columns * rows);
  final histogram = List<int>.filled(256, 0);

  for (var row = 0; row < rows; row++) {
    final yStart = (row * cell).floor();
    final yEnd = min(height, ((row + 1) * cell).ceil());
    for (var column = 0; column < columns; column++) {
      final xStart = (column * cell).floor();
      final xEnd = min(width, ((column + 1) * cell).ceil());
      histogram.fillRange(0, 256, 0);
      var samples = 0;
      for (var y = yStart; y < yEnd; y++) {
        final offset = y * width;
        for (var x = xStart; x < xEnd; x++) {
          histogram[lum[offset + x]]++;
          samples++;
        }
      }
      // The 85th percentile is paper even where a cell is half text.
      var remaining = (samples * 0.15).ceil();
      var level = 255;
      while (level > 0) {
        remaining -= histogram[level];
        if (remaining <= 0) break;
        level--;
      }
      raw[row * columns + column] = max(level, 32).toDouble();
    }
  }

  // Smooth the grid so cell borders do not show up in the result.
  final grid = Float32List(columns * rows);
  for (var row = 0; row < rows; row++) {
    for (var column = 0; column < columns; column++) {
      var total = 0.0;
      var n = 0;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final r = row + dy, cIdx = column + dx;
          if (r < 0 || cIdx < 0 || r >= rows || cIdx >= columns) continue;
          total += raw[r * columns + cIdx];
          n++;
        }
      }
      grid[row * columns + column] = total / n;
    }
  }
  return (grid: grid, columns: columns, rows: rows, cell: cell);
}

double _sampleGrid(
  Float32List grid,
  int columns,
  int rows,
  double cell,
  int x,
  int y,
) {
  final gx = ((x + 0.5) / cell - 0.5).clamp(0.0, columns - 1.0);
  final gy = ((y + 0.5) / cell - 0.5).clamp(0.0, rows - 1.0);
  final x0 = gx.floor(), y0 = gy.floor();
  final x1 = min(x0 + 1, columns - 1), y1 = min(y0 + 1, rows - 1);
  final tx = gx - x0, ty = gy - y0;
  final top = grid[y0 * columns + x0] * (1 - tx) + grid[y0 * columns + x1] * tx;
  final bottom =
      grid[y1 * columns + x0] * (1 - tx) + grid[y1 * columns + x1] * tx;
  return top * (1 - ty) + bottom * ty;
}

/// Applies [filter] to [image].
///
/// * [FilterType.natural] – unchanged.
/// * [FilterType.enhance] – evens out lighting and whitens the paper while
///   keeping colours.
/// * [FilterType.gray] – plain grayscale.
/// * [FilterType.blackWhite] – high-contrast black text on white paper.
img.Image applyDocumentFilter(img.Image image, FilterType filter) {
  if (filter == FilterType.natural) return image;

  final width = image.width, height = image.height;
  final count = width * height;
  final rgb = _rgbBytes(image);
  final lum = _luminance(rgb, count);
  final out = Uint8List(count * 3);

  if (filter == FilterType.gray) {
    for (var i = 0, j = 0; i < count; i++, j += 3) {
      out[j] = out[j + 1] = out[j + 2] = lum[i];
    }
    return _fromRgb(out, width, height);
  }

  final paper = _paperBrightness(lum, width, height);

  // Tone curves, precomputed for speed.
  final enhanceCurve = Uint8List(256);
  final blackWhiteCurve = Uint8List(256);
  for (var i = 0; i < 256; i++) {
    // Gentle S-curve: deepens ink, keeps mid-tones of photos and stamps.
    final t = i / 255;
    final s = t * t * (3 - 2 * t);
    enhanceCurve[i] = ((t * 0.45 + s * 0.55) * 255).round().clamp(0, 255);
    // Everything brighter than light gray becomes white, dark becomes black,
    // with a short ramp in between so text edges stay smooth.
    blackWhiteCurve[i] = ((i - 105) * 255 / 95).round().clamp(0, 255);
  }

  var i = 0, j = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++, i++, j += 3) {
      final background = _sampleGrid(
        paper.grid,
        paper.columns,
        paper.rows,
        paper.cell,
        x,
        y,
      );
      // Scale so the local paper brightness lands just below pure white.
      final gain = min(4.0, 250 / background);
      if (filter == FilterType.blackWhite) {
        final value = blackWhiteCurve[min(255, (lum[i] * gain).round())];
        out[j] = out[j + 1] = out[j + 2] = value;
      } else {
        out[j] = enhanceCurve[min(255, (rgb[j] * gain).round())];
        out[j + 1] = enhanceCurve[min(255, (rgb[j + 1] * gain).round())];
        out[j + 2] = enhanceCurve[min(255, (rgb[j + 2] * gain).round())];
      }
    }
  }
  return _fromRgb(out, width, height);
}

// ---------------------------------------------------------------------------
// Isolate entry points
// ---------------------------------------------------------------------------

/// `compute()` entry point for [detectDocumentCorners]. Returns the corners
/// as `[x0, y0, x1, y1, x2, y2, x3, y3]`, or `null`.
List<double>? detectCornersInIsolate(Uint8List bytes) {
  final image = decodeUpright(bytes);
  if (image == null) return null;
  final corners = detectDocumentCorners(image);
  if (corners == null) return null;
  return [
    for (final corner in corners) ...[corner.x, corner.y],
  ];
}

/// `compute()` entry point for [warpPerspective]. [request] is
/// `(bytes, [x0, y0, ... x3, y3])`; returns JPEG bytes or `null`.
Uint8List? warpInIsolate((Uint8List, List<double>) request) {
  final image = decodeUpright(request.$1);
  if (image == null) return null;
  final c = request.$2;
  final warped = warpPerspective(image, [
    for (var i = 0; i < 8; i += 2) Point(c[i], c[i + 1]),
  ]);
  return img.encodeJpg(warped, quality: 92);
}

/// `compute()` entry point for [applyDocumentFilter]. [request] is
/// `(bytes, filter name)`; returns JPEG bytes.
Uint8List filterInIsolate((Uint8List, String) request) {
  final filter = FilterType.values.firstWhere(
    (value) => value.name == request.$2,
    orElse: () => FilterType.natural,
  );
  if (filter == FilterType.natural) return request.$1;
  var image = decodeUpright(request.$1);
  if (image == null) return request.$1;
  final longest = max(image.width, image.height);
  if (longest > maxFilterDimension) {
    final scale = maxFilterDimension / longest;
    image = img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
      interpolation: img.Interpolation.average,
    );
  }
  return img.encodeJpg(applyDocumentFilter(image, filter), quality: 90);
}
