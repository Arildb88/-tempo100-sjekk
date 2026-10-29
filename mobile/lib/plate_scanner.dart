import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'plate_tracker.dart';

class PlateScanner extends StatefulWidget {
  const PlateScanner({super.key});
  @override
  State<PlateScanner> createState() => _PlateScannerState();
}

class _PlateScannerState extends State<PlateScanner> with WidgetsBindingObserver {
  static const _minimumFrameInterval = Duration(milliseconds: 120);

  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _tracker = PlateTracker();
  CameraController? _camera;
  CameraDescription? _description;
  bool _busy = false;
  bool _found = false;
  bool _starting = false;
  String _message = 'Starter kamera …';
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  Future<void> _start() async {
    if (_starting || _camera != null || _found) return;
    _starting = true;
    try {
      final devices = await availableCameras();
      if (!mounted) return;
      final selected = devices.where((d) => d.lensDirection == CameraLensDirection.back);
      if (selected.isEmpty) throw StateError('Fant ikke et bakre kamera.');
      final description = selected.first;
      final controller = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      // Aim the camera's automatic focus and exposure at the centre guide.
      try {
        if (controller.value.focusPointSupported) {
          await controller.setFocusPoint(const Offset(0.5, 0.5));
        }
        if (controller.value.exposurePointSupported) {
          await controller.setExposurePoint(const Offset(0.5, 0.5));
        }
      } catch (_) {
        // Some cameras do not support focus or exposure points.
      }

      _description = description;
      _camera = controller;
      setState(() => _message = 'Hold hele skiltet midt i rammen – trykk på skiltet for å fokusere');
      await controller.startImageStream(_scan);
    } catch (_) {
      if (mounted) setState(() => _message = 'Kunne ikke starte kameraet. Skriv registreringsnummeret manuelt.');
    } finally {
      _starting = false;
    }
  }

  InputImage? _convert(CameraImage image) {
    final controller = _camera;
    final description = _description;
    if (controller == null || description == null || image.planes.length != 1) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format != (Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888)) return null;
    const orientations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };
    final compensation = orientations[controller.value.deviceOrientation];
    if (compensation == null) return null;
    final degrees = Platform.isAndroid
        ? (description.sensorOrientation - compensation + 360) % 360
        : description.sensorOrientation;
    final rotation = InputImageRotationValue.fromRawValue(degrees);
    if (rotation == null) return null;
    final plane = image.planes.single;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format!,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _focusAt(Offset point) async {
    final controller = _camera;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      if (controller.value.focusPointSupported) {
        await controller.setFocusPoint(point);
      }
      if (controller.value.exposurePointSupported) {
        await controller.setExposurePoint(point);
      }
    } catch (_) {
      // Keep scanning if a device rejects a tap-to-focus request.
    }
  }

  Future<void> _scan(CameraImage frame) async {
    if (!mounted || _busy || _found ||
        DateTime.now().difference(_lastFrame) < _minimumFrameInterval) {
      return;
    }
    final input = _convert(frame);
    if (input == null) return;
    _busy = true;
    _lastFrame = DateTime.now();
    try {
      final result = await _recognizer.processImage(input);
      if (!mounted || _found) return;
      final plate = _tracker.add(result.text);
      if (plate != null) {
        _found = true;
        Navigator.of(context).pop(plate);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Skiltlesing feilet. Prøv igjen eller skriv nummeret selv.');
      }
    } finally {
      _busy = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      final camera = _camera;
      _camera = null;
      camera?.dispose();
    } else if (state == AppLifecycleState.resumed && _camera == null && !_found) {
      _start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _recognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF17161D),
    appBar: AppBar(
      title: Text(tr(context, 'Les skilt')),
      backgroundColor: const Color(0xFF17161D),
      foregroundColor: Colors.white,
    ),
    body: SafeArea(
      child: Column(children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _camera?.value.isInitialized == true
                  ? _camera!.value.aspectRatio
                  : 3 / 4,
              child: Stack(fit: StackFit.expand, children: [
                if (_camera?.value.isInitialized == true)
                  LayoutBuilder(builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final width = constraints.maxWidth;
                        final height = constraints.maxHeight;
                        if (width <= 0 || height <= 0) return;
                        final point = Offset(
                          (details.localPosition.dx / width).clamp(0.0, 1.0),
                          (details.localPosition.dy / height).clamp(0.0, 1.0),
                        );
                        _focusAt(point);
                      },
                      child: CameraPreview(_camera!),
                    );
                  })
                else
                  const Center(
                    child: Icon(Icons.camera_alt_outlined, size: 48, color: Colors.white54),
                  ),
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 280,
                      height: 116,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD3B5FF), width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            tr(context, _message),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            tr(context, 'Skiltlesingen er raskest når skiltet fyller rammen. Trykk på skiltet for å fokusere. Bruk kameraet bare som passasjer eller når bilen står stille.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ]),
    ),
  );
}
