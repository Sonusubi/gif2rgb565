import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;

void main() {
  runApp(const GifToRGB565App());
}

class GifToRGB565App extends StatelessWidget {
  const GifToRGB565App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GIF to RGB565 Converter',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      home: const ConverterHomePage(),
    );
  }
}

class ConverterHomePage extends StatefulWidget {
  const ConverterHomePage({super.key});

  @override
  State<ConverterHomePage> createState() => _ConverterHomePageState();
}

class _ConverterHomePageState extends State<ConverterHomePage>
    with TickerProviderStateMixin {
  final _targetWidthController = TextEditingController(text: '160');
  final _targetHeightController = TextEditingController(text: '160');
  final _arrayPrefixController = TextEditingController(text: 'frame');
  final _maxFramesController = TextEditingController(text: '10');

  bool _disableResize = false;
  bool _isProcessing = false;
  String? _fileName;
  List<img.Image> _extractedFrames = [];
  String _generatedCode = '';
  String? _statusMessage;
  bool _isError = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _targetWidthController.dispose();
    _targetHeightController.dispose();
    _arrayPrefixController.dispose();
    _maxFramesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildUploadSection(),
                const SizedBox(height: 30),
                _buildConfigSection(),
                const SizedBox(height: 20),
                _buildInfoCard(),
                if (_extractedFrames.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  _buildFramesSection(),
                ],
                const SizedBox(height: 30),
                _buildConvertButton(),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 20),
                  _buildStatusMessage(),
                ],
                if (_generatedCode.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  _buildCodeOutput(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🎨 GIF to RGB565 Converter',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d3748),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Convert animated GIFs to accurate RGB565 arrays for TFT displays',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fileName == null ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: _pickFile,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _fileName != null
                      ? Colors.green.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.3),
                  width: 3,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _fileName != null ? Icons.check_circle : Icons.folder_open,
                    size: 60,
                    color: _fileName != null ? Colors.green : Colors.grey[400],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _fileName ?? 'Tap to select GIF file',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _fileName != null
                          ? Colors.green[700]
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Supports GIF, PNG, JPG, and BMP files',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfigSection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d3748),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              if (!_disableResize) ...[
                _buildConfigField('Target Width (px)', _targetWidthController),
                _buildConfigField(
                  'Target Height (px)',
                  _targetHeightController,
                ),
              ],
              _buildConfigField('Array Prefix', _arrayPrefixController),
              _buildConfigField('Max Frames', _maxFramesController),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Checkbox(
                value: _disableResize,
                onChanged: (value) {
                  setState(() {
                    _disableResize = value ?? false;
                  });
                },
              ),
              const Text(
                'Keep Original Size',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigField(String label, TextEditingController controller) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4a5568),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF5E7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF6AD55), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✨ Enhanced Flutter Version',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC05621),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This Flutter app includes native image processing with proper frame extraction, accurate RGB565 conversion, and beautiful Material Design UI. Works with both animated GIFs and static images.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[800],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFramesSection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFE6FFFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF81E6D9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Extracted Frames',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d3748),
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: _extractedFrames.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          Uint8List.fromList(
                            img.encodePng(_extractedFrames[index]),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Frame $index',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConvertButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 60,
      child: ElevatedButton(
        onPressed: _extractedFrames.isNotEmpty && !_isProcessing
            ? _convertToRGB565
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667eea),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 10,
          shadowColor: const Color(0xFF667eea).withOpacity(0.3),
        ),
        child: _isProcessing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Converting...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : const Text(
                'Convert to RGB565 Arrays',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _isError ? const Color(0xFFFED7D7) : const Color(0xFFC6F6D5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isError ? const Color(0xFFFEB2B2) : const Color(0xFF9AE6B4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isError ? Icons.error : Icons.check_circle,
            color: _isError ? const Color(0xFFC53030) : const Color(0xFF2F855A),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                color: _isError
                    ? const Color(0xFFC53030)
                    : const Color(0xFF2F855A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeOutput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF2d3748),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Generated Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _copyCode,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF48BB78),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Text(
                _generatedCode,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF2d3748),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gif', 'png', 'jpg', 'jpeg', 'bmp'],
      );

      if (result != null) {
        setState(() {
          _fileName = result.files.single.name;
          _isProcessing = true;
          _statusMessage = null;
          _extractedFrames.clear();
          _generatedCode = '';
        });

        Uint8List? fileBytes = result.files.single.bytes;
        if (fileBytes == null) {
          final String? path = result.files.single.path;
          if (path != null) {
            fileBytes = await File(path).readAsBytes();
          }
        }

        if (fileBytes != null) {
          await _processFile(fileBytes);
        } else {
          _setError('Failed to read file bytes.');
        }
      }
    } catch (e) {
      _setError('Failed to pick file: $e');
    }
  }

  Future<void> _processFile(Uint8List bytes) async {
    try {
      // Check if it's a GIF
      if (_fileName!.toLowerCase().endsWith('.gif')) {
        await _processGif(bytes);
      } else {
        await _processStaticImage(bytes);
      }
    } catch (e) {
      _setError('Failed to process file: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processGif(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image != null) {
        final frames = image.frames.isNotEmpty ? image.frames : [image];
        final maxFrames = math.min(
          int.parse(_maxFramesController.text),
          frames.length,
        );
        _extractedFrames = frames.take(maxFrames).toList();
        _setSuccess(
          'Successfully extracted ${_extractedFrames.length} frames.',
        );
      } else {
        throw Exception('Failed to decode image file.');
      }
    } catch (e) {
      _setError('Failed to process GIF: $e');
    }
  }

  Future<void> _processStaticImage(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image != null) {
        _extractedFrames = [image];
        _setSuccess('Image loaded successfully!');
      } else {
        throw Exception('Failed to decode image');
      }
    } catch (e) {
      _setError('Failed to process image: $e');
    }
  }

  void _convertToRGB565() {
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    // Use a future to allow UI to update
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        _generateRGB565Arrays();
        _setSuccess('RGB565 arrays generated successfully!');
      } catch (e) {
        _setError('Failed to generate arrays: $e');
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  void _generateRGB565Arrays() {
    int targetWidth = int.parse(_targetWidthController.text);
    int targetHeight = int.parse(_targetHeightController.text);
    final arrayPrefix = _arrayPrefixController.text;

    if (_disableResize && _extractedFrames.isNotEmpty) {
      targetWidth = _extractedFrames.first.width;
      targetHeight = _extractedFrames.first.height;
    }

    StringBuffer code = StringBuffer();
    code.writeln(
      '// RGB565 arrays generated by Flutter GIF to RGB565 Converter',
    );
    code.writeln(
      '// Original dimensions: ${_extractedFrames.first.width}x${_extractedFrames.first.height}',
    );
    code.writeln('// Target dimensions: ${targetWidth}x$targetHeight');
    code.writeln('// Total frames: ${_extractedFrames.length}');
    code.writeln();

    for (int i = 0; i < _extractedFrames.length; i++) {
      final rgb565Data = _convertImageToRGB565(
        _extractedFrames[i],
        targetWidth,
        targetHeight,
        _disableResize,
      );

      code.writeln('// Frame $i');
      code.writeln(
        'const uint16_t ${arrayPrefix}_$i[${targetWidth * targetHeight}] PROGMEM = {',
      );

      for (int row = 0; row < targetHeight; row++) {
        code.write('  ');
        for (int col = 0; col < targetWidth; col++) {
          final pixelIndex = row * targetWidth + col;
          final value = rgb565Data[pixelIndex];
          code.write(
            '0x${value.toRadixString(16).padLeft(4, '0').toUpperCase()}',
          );
          if (pixelIndex < rgb565Data.length - 1) {
            code.write(', ');
          }
        }
        code.writeln();
      }
      code.writeln('};');
      code.writeln();
    }

    // Add array of pointers
    code.writeln('// Array of frame pointers');
    code.writeln(
      'const uint16_t* const ${arrayPrefix}_frames[${_extractedFrames.length}] PROGMEM = {',
    );
    for (int i = 0; i < _extractedFrames.length; i++) {
      code.write('  ${arrayPrefix}_$i');
      if (i < _extractedFrames.length - 1) code.write(',');
      code.writeln();
    }
    code.writeln('};');

    setState(() {
      _generatedCode = code.toString();
    });
  }

  List<int> _convertImageToRGB565(
    img.Image sourceImage,
    int targetWidth,
    int targetHeight,
    bool disableResize,
  ) {
    img.Image processImage;

    if (disableResize) {
      processImage = sourceImage;
      targetWidth = sourceImage.width;
      targetHeight = sourceImage.height;
    } else {
      processImage = img.copyResize(
        sourceImage,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.nearest,
      );
    }

    final rgb565Array = <int>[];

    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final pixel = processImage.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        final a = pixel.a;

        // Handle transparency
        final alpha = a / 255.0;
        final finalR = (r * alpha).round();
        final finalG = (g * alpha).round();
        final finalB = (b * alpha).round();

        // Convert to RGB565
        final r5 = ((finalR * 31) / 255).round();
        final g6 = ((finalG * 63) / 255).round();
        final b5 = ((finalB * 31) / 255).round();

        final rgb565 = (r5 << 11) | (g6 << 5) | b5;
        rgb565Array.add(rgb565);
      }
    }

    return rgb565Array;
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _generatedCode));
    _setSuccess('Code copied to clipboard!');
  }

  void _setError(String message) {
    setState(() {
      _statusMessage = message;
      _isError = true;
    });
  }

  void _setSuccess(String message) {
    setState(() {
      _statusMessage = message;
      _isError = false;
    });
  }
}
