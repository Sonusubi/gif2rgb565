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
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
        fontFamily: 'SF Pro Display',
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
  int _selectedTabIndex = 0;

  late AnimationController _uploadController;
  late AnimationController _successController;
  late AnimationController _slideController;
  late Animation<double> _uploadAnimation;
  late Animation<double> _successAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _uploadController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _uploadAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _uploadController, curve: Curves.easeInOut),
    );

    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _slideController.forward();
  }

  @override
  void dispose() {
    _uploadController.dispose();
    _successController.dispose();
    _slideController.dispose();
    _targetWidthController.dispose();
    _targetHeightController.dispose();
    _arrayPrefixController.dispose();
    _maxFramesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SlideTransition(position: _slideAnimation, child: _buildBody()),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFEC4899)],
          ),
        ),
      ),
      title: const Text(
        'RGB565 Converter',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: () => _showHelpDialog(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _selectedTabIndex,
      children: [_buildMainView(), _buildPreviewView(), _buildCodeView()],
    );
  }

  Widget _buildMainView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeroSection(),
          _buildUploadCard(),
          _buildConfigCard(),
          _buildProcessButton(),
          if (_statusMessage != null) _buildStatusCard(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.image, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                'GIF to RGB565',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Convert animated GIFs and images to RGB565 format for TFT displays with precision color mapping.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard() {
    return AnimatedBuilder(
      animation: _uploadAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Transform.scale(
            scale: _fileName == null ? _uploadAnimation.value : 1.0,
            child: _buildUploadArea(),
          ),
        );
      },
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _pickFile,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _fileName != null
                ? const Color(0xFF10B981)
                : const Color(0xFFE5E7EB),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _fileName != null
                        ? ScaleTransition(
                            scale: _successAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.cloud_upload_outlined,
                              color: Color(0xFF6B7280),
                              size: 32,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _fileName ?? 'Select your file',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _fileName != null
                          ? const Color(0xFF10B981)
                          : const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fileName != null
                        ? 'Ready to process'
                        : 'GIF, PNG, JPG, BMP supported',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (_isProcessing)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4F46E5),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Processing file...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          _buildConfigGrid(),
          const SizedBox(height: 20),
          _buildKeepOriginalSizeToggle(),
        ],
      ),
    );
  }

  Widget _buildConfigGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.0,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        if (!_disableResize) ...[
          _buildConfigField('Width', _targetWidthController, 'px'),
          _buildConfigField('Height', _targetHeightController, 'px'),
        ],
        _buildConfigField('Prefix', _arrayPrefixController, ''),
        _buildConfigField('Max Frames', _maxFramesController, ''),
      ],
    );
  }

  Widget _buildConfigField(
    String label,
    TextEditingController controller,
    String suffix,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: const TextStyle(color: Color(0xFF6B7280)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
        ),
      ],
    );
  }

  Widget _buildKeepOriginalSizeToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Switch(
            value: _disableResize,
            onChanged: (value) {
              setState(() {
                _disableResize = value;
              });
            },
            activeColor: const Color(0xFF4F46E5),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Keep Original Size',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessButton() {
    return Container(
      margin: const EdgeInsets.all(20),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _extractedFrames.isNotEmpty && !_isProcessing
            ? _convertToRGB565
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
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
                  SizedBox(width: 12),
                  Text(
                    'Converting...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : const Text(
                'Convert to RGB565',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isError ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isError ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isError
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                color: _isError
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF059669),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewView() {
    if (_extractedFrames.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 64,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 16),
            Text(
              'No frames to preview',
              style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview (${_extractedFrames.length} frames)',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _extractedFrames.length,
            itemBuilder: (context, index) {
              return _buildFrameCard(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFrameCard(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.memory(
                Uint8List.fromList(img.encodePng(_extractedFrames[index])),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Frame ${index + 1}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeView() {
    if (_generatedCode.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.code_outlined, size: 64, color: Color(0xFF9CA3AF)),
            SizedBox(height: 16),
            Text(
              'No code generated yet',
              style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF1F2937),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
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
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Text(
                _generatedCode,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  color: Color(0xFF374151),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF4F46E5),
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Colors.transparent,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Convert',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.preview_outlined),
            activeIcon: Icon(Icons.preview),
            label: 'Preview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.code_outlined),
            activeIcon: Icon(Icons.code),
            label: 'Code',
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('How to Use'),
        content: const Text(
          '1. Select a GIF, PNG, JPG, or BMP file\n'
          '2. Configure target dimensions and settings\n'
          '3. Click "Convert to RGB565" to generate arrays\n'
          '4. Preview frames and copy the generated code\n\n'
          'The generated code is ready to use in Arduino/ESP32 projects.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
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
          _successController.forward();
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

    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        _generateRGB565Arrays();
        _setSuccess('RGB565 arrays generated successfully!');
        setState(() {
          _selectedTabIndex = 2; // Switch to code view
        });
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
