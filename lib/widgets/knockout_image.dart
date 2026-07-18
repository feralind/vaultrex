import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool isAssetImageUrl(String url) =>
    url.startsWith('assets/') || url.startsWith('asset:');

String normalizeAssetPath(String url) =>
    url.startsWith('asset:') ? url.substring('asset:'.length) : url;

/// Product photo with studio white/light background knocked out so only the
/// pack / box / deck silhouette remains transparent.
class KnockoutProductImage extends StatefulWidget {
  const KnockoutProductImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.error,
    /// Studio-white floor (higher = safer for cream product art).
    this.threshold = 250,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? error;
  final int threshold;

  @override
  State<KnockoutProductImage> createState() => _KnockoutProductImageState();
}

class _KnockoutProductImageState extends State<KnockoutProductImage> {
  static final Map<String, ui.Image> _cache = {};

  ui.Image? _image;
  Object? _error;
  bool _loading = true;
  bool _useRawAsset = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant KnockoutProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.threshold != widget.threshold) {
      _load();
    }
  }

  Future<void> _load() async {
    // Local featured/cutout art is already transparent — show as-is.
    // Avoids isolate decode failures / fringe choke on large pack PNGs.
    if (isAssetImageUrl(widget.url)) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _image = null;
        _useRawAsset = true;
      });
      return;
    }

    // v2: fringe choke also runs on assets that already have alpha.
    final key = 'v2:${widget.url}@${widget.threshold}';
    final cached = _cache[key];
    if (cached != null) {
      setState(() {
        _image = cached;
        _error = null;
        _loading = false;
        _useRawAsset = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _image = null;
      _useRawAsset = false;
    });

    try {
      final provider = CachedNetworkImageProvider(widget.url);
      final src = await _resolveImage(provider);
      final bd = await src.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bd == null) throw StateError('No pixel data');

      final pixels = Uint8List.fromList(bd.buffer.asUint8List());
      final w = src.width;
      final h = src.height;

      final hasAlpha = _hasMeaningfulAlpha(pixels);
      late final Uint8List processed;
      if (kIsWeb) {
        processed = hasAlpha
            ? _fringeChokePixels(_PixelJob(pixels, w, h, widget.threshold))
            : _knockoutPixels(_PixelJob(pixels, w, h, widget.threshold));
      } else {
        processed = await compute(
          hasAlpha ? _fringeChokePixels : _knockoutPixels,
          _PixelJob(pixels, w, h, widget.threshold),
        );
      }
      final out = await _imageFromRgba(processed, w, h);

      _cache[key] = out;
      if (!mounted) return;
      setState(() {
        _image = out;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<ui.Image> _resolveImage(ImageProvider provider) {
    final stream = provider.resolve(const ImageConfiguration());
    final completer = Completer<ui.Image>();
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(info.image);
      },
      onError: (e, st) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.completeError(e, st);
      },
    );
    stream.addListener(listener);
    // Avoid hanging forever on stalled network / decode (pack theater cover).
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        stream.removeListener(listener);
        throw TimeoutException('Image resolve timed out');
      },
    );
  }

  Future<ui.Image> _imageFromRgba(Uint8List rgba, int w, int h) {
    final c = Completer<ui.Image>();
    ui.decodeImageFromPixels(rgba, w, h, ui.PixelFormat.rgba8888, c.complete);
    return c.future;
  }

  @override
  Widget build(BuildContext context) {
    if (_useRawAsset) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Image.asset(
          normalizeAssetPath(widget.url),
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) =>
              widget.error ?? widget.placeholder ?? const SizedBox.shrink(),
        ),
      );
    }
    if (_loading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.placeholder ??
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
      );
    }
    if (_error != null || _image == null) {
      // Prefer caller error widget — never flash raw white-bg product JPG/PNG.
      if (widget.error != null) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: widget.error,
        );
      }
      if (isAssetImageUrl(widget.url)) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: widget.placeholder ?? const SizedBox.shrink(),
        );
      }
      // Last-resort visual: multiply blend hides white on dark UI.
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: CachedNetworkImage(
          imageUrl: widget.url,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          color: Colors.white,
          colorBlendMode: BlendMode.multiply,
          errorWidget: (_, _, _) =>
              widget.placeholder ?? const SizedBox.shrink(),
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: RawImage(
        image: _image,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _PixelJob {
  const _PixelJob(this.pixels, this.width, this.height, this.threshold);
  final Uint8List pixels;
  final int width;
  final int height;
  final int threshold;
}

bool _hasMeaningfulAlpha(Uint8List rgba) {
  final total = rgba.length ~/ 4;
  if (total == 0) return false;
  // Sample every Nth pixel so this stays cheap on large product shots.
  final step = math.max(1, total ~/ 4000);
  var transparent = 0;
  var sampled = 0;
  for (var i = 3; i < rgba.length; i += 4 * step) {
    sampled++;
    if (rgba[i] < 12) transparent++;
  }
  if (sampled == 0) return false;
  return transparent / sampled >= 0.02;
}

/// Edge flood-fill knockout: only remove studio white connected to the border.
/// Protects cream/light product surfaces and interior bright art swirls.
Uint8List _knockoutPixels(_PixelJob job) {
  final bytes = job.pixels;
  final w = job.width;
  final h = job.height;
  final threshold = job.threshold;
  const chromaMax = 14;

  bool isStudioWhite(int i) {
    final a = bytes[i + 3];
    if (a < 12) return true;
    final r = bytes[i];
    final g = bytes[i + 1];
    final b = bytes[i + 2];
    final minC = math.min(r, math.min(g, b));
    final maxC = math.max(r, math.max(g, b));
    if (maxC - minC > chromaMax) return false;
    return minC >= threshold;
  }

  final visited = Uint8List(w * h);
  final queue = <int>[];

  void tryPush(int x, int y) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    final idx = y * w + x;
    if (visited[idx] != 0) return;
    final i = idx * 4;
    if (!isStudioWhite(i)) return;
    visited[idx] = 1;
    queue.add(idx);
  }

  for (var x = 0; x < w; x++) {
    tryPush(x, 0);
    tryPush(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    tryPush(0, y);
    tryPush(w - 1, y);
  }

  var q = 0;
  while (q < queue.length) {
    final idx = queue[q++];
    final i = idx * 4;
    bytes[i + 3] = 0;
    final x = idx % w;
    final y = idx ~/ w;
    tryPush(x - 1, y);
    tryPush(x + 1, y);
    tryPush(x, y - 1);
    tryPush(x, y + 1);
  }

  // 1px feather on near-white pixels touching transparency (no flood expand).
  final softFloor = math.max(0, threshold - 8);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final idx = y * w + x;
      final i = idx * 4;
      final a = bytes[i + 3];
      if (a < 250) continue;
      final r = bytes[i];
      final g = bytes[i + 1];
      final b = bytes[i + 2];
      final minC = math.min(r, math.min(g, b));
      final maxC = math.max(r, math.max(g, b));
      if (maxC - minC > chromaMax || minC < softFloor) continue;
      var touchesClear = false;
      for (final n in [idx - 1, idx + 1, idx - w, idx + w]) {
        if (n < 0 || n >= w * h) continue;
        if (bytes[n * 4 + 3] == 0) {
          touchesClear = true;
          break;
        }
      }
      if (touchesClear) {
        bytes[i + 3] = (a * 0.35).round().clamp(0, 255);
      }
    }
  }

  return bytes;
}

/// Cheap fringe cleanup for assets that already have transparency: clear
/// near-white / light-gray pixels on the border or touching transparency.
Uint8List _fringeChokePixels(_PixelJob job) {
  final bytes = job.pixels;
  final w = job.width;
  final h = job.height;
  const chromaMax = 30;
  const whiteFloor = 205;
  const borderPx = 14;

  bool isNearWhite(int i) {
    final a = bytes[i + 3];
    if (a < 12) return true;
    final r = bytes[i];
    final g = bytes[i + 1];
    final b = bytes[i + 2];
    final minC = math.min(r, math.min(g, b));
    final maxC = math.max(r, math.max(g, b));
    if (maxC - minC > chromaMax) return false;
    return minC >= whiteFloor;
  }

  int borderDist(int x, int y) {
    final left = x;
    final top = y;
    final right = w - 1 - x;
    final bottom = h - 1 - y;
    return math.min(math.min(left, top), math.min(right, bottom));
  }

  // Pass 1: clear near-white within border band.
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      if (bytes[i + 3] < 12) continue;
      if (borderDist(x, y) > borderPx) continue;
      if (isNearWhite(i)) bytes[i + 3] = 0;
    }
  }

  // Pass 2: edge flood of near-white / clear from borders.
  final visited = Uint8List(w * h);
  final queue = <int>[];

  void tryPush(int x, int y) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    final idx = y * w + x;
    if (visited[idx] != 0) return;
    final i = idx * 4;
    if (!isNearWhite(i)) return;
    visited[idx] = 1;
    queue.add(idx);
  }

  for (var x = 0; x < w; x++) {
    tryPush(x, 0);
    tryPush(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    tryPush(0, y);
    tryPush(w - 1, y);
  }

  var q = 0;
  while (q < queue.length) {
    final idx = queue[q++];
    final i = idx * 4;
    bytes[i + 3] = 0;
    final x = idx % w;
    final y = idx ~/ w;
    tryPush(x - 1, y);
    tryPush(x + 1, y);
    tryPush(x, y - 1);
    tryPush(x, y + 1);
  }

  // Pass 3: peel near-white touching transparency (2px).
  for (var pass = 0; pass < 2; pass++) {
    final kill = <int>[];
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final idx = y * w + x;
        final i = idx * 4;
        final a = bytes[i + 3];
        if (a < 20) continue;
        final r = bytes[i];
        final g = bytes[i + 1];
        final b = bytes[i + 2];
        final minC = math.min(r, math.min(g, b));
        final maxC = math.max(r, math.max(g, b));
        if (maxC - minC > chromaMax || minC < 200) continue;
        var touch = false;
        for (final n in [idx - 1, idx + 1, idx - w, idx + w]) {
          if (n < 0 || n >= w * h) continue;
          if (bytes[n * 4 + 3] < 20) {
            touch = true;
            break;
          }
        }
        if (touch) kill.add(i);
      }
    }
    for (final i in kill) {
      bytes[i + 3] = 0;
    }
  }

  // Harden soft alpha haze.
  for (var i = 3; i < bytes.length; i += 4) {
    final a = bytes[i];
    if (a < 40) {
      bytes[i] = 0;
    } else if (a > 220) {
      bytes[i] = 255;
    }
  }

  return bytes;
}
