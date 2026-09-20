import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/api_key_service.dart';
import '../../../../core/services/routine_parser_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/api_settings_dialog.dart';
import 'staging_review_sheet.dart';

class RoutineImportModal extends ConsumerStatefulWidget {
  const RoutineImportModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const RoutineImportModal(),
    );
  }

  @override
  ConsumerState<RoutineImportModal> createState() => _RoutineImportModalState();
}

class _RoutineImportModalState extends ConsumerState<RoutineImportModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _textController = TextEditingController();
  final _imagePicker = ImagePicker();

  // Picked image state
  XFile? _selectedImage;
  Uint8List? _imageBytes;

  // Picked document state
  PlatformFile? _selectedFile;
  Uint8List? _fileBytes;

  // Scanning state
  bool _isScanning = false;
  bool _isCancelled = false;
  String _scanningMessage = 'Initializing Gemini Flash...';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.status;
        if (status.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Camera permission is permanently denied. Please enable it in device Settings.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1560,
        maxHeight: 1560,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = picked;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        final msg = errorStr.contains('camera_access_denied') ||
                errorStr.contains('permission')
            ? 'Camera or gallery permission denied. Please enable permissions to scan routines.'
            : 'Could not load selected image: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'csv', 'md'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Uint8List? bytes = file.bytes;

        // If file.bytes is null (common on desktop/mobile when path is available), read from path
        if (bytes == null && file.path != null) {
          final ioFile = File(file.path!);
          if (await ioFile.exists()) {
            bytes = await ioFile.readAsBytes();
          }
        }

        if (bytes != null) {
          setState(() {
            _selectedFile = file;
            _fileBytes = bytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick document: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _pasteSampleText() {
    _textController.text = '''FALL 2026 CSE SEMESTER 4 CLASS SCHEDULE:
Monday:
- CSE 3101 Database Systems: 09:00 - 10:30, Room 301, North Tower (Prof. Sarah Khan)
- CSE 3301 Computer Networks: 11:00 - 12:30, Room 402 (Dr. Robert Metcalfe)

Tuesday:
- CSE 3102 Database Systems Lab: 09:00 - 12:00, Lab 3, Software Wing (Dr. Alex Mercer) - Note: Bring Project Wireframes & Git repo push
- CSE 3201 Operating Systems: 14:00 - 15:30, Room 305 (Prof. Alan Turing)

Wednesday:
- CSE 3302 Computer Networks Lab: 10:00 - 13:00, Networks Lab (Engr. John Doe)
- MATH 2205 Discrete Mathematics: 14:30 - 16:00, Room 205 (TA Emily Thornton)

Thursday:
- CSE 3101 Database Systems Class Test (CT): 09:00 - 10:00, Room 301 (Prof. Sarah Khan) - Topics: SQL joins & indexing
- CSE 3202 OS Kernel Lab: 14:00 - 16:00, Lab 1, Systems Wing (Dr. Linus Vance)''';
  }

  Future<void> _startParsing() async {
    final apiKeyAsync = ref.read(geminiApiKeyProvider);
    final hasKey = apiKeyAsync.valueOrNull?.isNotEmpty ?? false;

    if (!hasKey) {
      _showMissingKeyDialog();
      return;
    }

    setState(() {
      _isScanning = true;
      _isCancelled = false;
      _scanningMessage = 'Uploading to Gemini 1.5 Flash...';
    });

    final parser = ref.read(routineParserServiceProvider);

    try {
      // Periodic status update simulation for better user feedback
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted && _isScanning) {
          setState(() {
            _scanningMessage = 'Scanning course codes, rooms & time slots...';
          });
        }
      });

      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted && _isScanning) {
          setState(() {
            _scanningMessage = 'Categorizing lectures, labs & exams...';
          });
        }
      });

      final currentTabIndex = _tabController.index;
      List<dynamic> results = [];

      if (currentTabIndex == 0) {
        // Image
        if (_imageBytes == null) {
          throw Exception('Please select or capture a routine image first.');
        }
        final mime = _selectedImage?.name.toLowerCase().endsWith('.png') == true
            ? 'image/png'
            : 'image/jpeg';
        results = await parser.parseFromImage(_imageBytes!, mime);
      } else if (currentTabIndex == 1) {
        // Document
        if (_fileBytes == null) {
          throw Exception('Please upload a PDF or text routine file first.');
        }
        final isPdf = _selectedFile?.name.toLowerCase().endsWith('.pdf') == true;
        results = await parser.parseFromDocument(
          _fileBytes!,
          _selectedFile?.name ?? 'routine.pdf',
          isPdf ? 'application/pdf' : 'text/plain',
        );
      } else {
        // Text
        final text = _textController.text.trim();
        if (text.isEmpty) {
          throw Exception('Please paste schedule text to parse.');
        }
        results = await parser.parseFromText(text);
      }

      if (_isCancelled) return;

      setState(() => _isScanning = false);

      if (results.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No academic events detected. Try providing a clearer image or text.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (mounted) {
        // Dismiss this modal and open StagingReviewSheet
        Navigator.of(context).pop();
        StagingReviewSheet.show(
          context,
          stagedEvents: List.from(results),
        );
      }
    } catch (e) {
      if (_isCancelled) return;

      setState(() => _isScanning = false);
      if (mounted) {
        if (e is GeminiApiKeyMissingException) {
          _showMissingKeyDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Parsing error: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.of(context).antiHabit,
            ),
          );
        }
      }
    }
  }

  void _cancelScanning() {
    setState(() {
      _isCancelled = true;
      _isScanning = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI routine scan cancelled.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMissingKeyDialog() {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.key, size: 20),
            SizedBox(width: 8),
            Text('Gemini Key Required'),
          ],
        ),
        content: const Text(
          'Please configure your Gemini API Key in settings before using the Multimodal Routine Importer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dlgCtx);
              ApiSettingsDialog.show(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = AppColors.of(context);
    final apiKeyAsync = ref.watch(geminiApiKeyProvider);
    final hasKey = apiKeyAsync.valueOrNull?.isNotEmpty ?? false;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: customColors.cardBorder,
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: customColors.primaryFixed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: customColors.onPrimaryFixed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Routine (Gemini AI)',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Multimodal parsing with staging protection',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: customColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // API Key status badge if key is missing
          if (!hasKey) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: customColors.antiHabit.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: customColors.antiHabit.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.vpn_key_outlined,
                        size: 16, color: customColors.antiHabit),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gemini API Key missing. Set your key to parse files.',
                        style: TextStyle(
                          color: customColors.antiHabit,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => ApiSettingsDialog.show(context),
                      child: Text(
                        'Configure →',
                        style: TextStyle(
                          color: customColors.primaryAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // 3 Source Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: customColors.primaryAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: customColors.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                tabs: const [
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_camera_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('Camera'),
                      ],
                    ),
                  ),
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('PDF / File'),
                      ],
                    ),
                  ),
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.paste_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('Paste Text'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Tab Content Area or Scanning Animation
          Expanded(
            child: _isScanning
                ? _buildScanningAnimation(customColors, theme)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCameraTab(customColors, theme),
                      _buildFileTab(customColors, theme),
                      _buildTextTab(customColors, theme),
                    ],
                  ),
          ),

          // Bottom Action CTA
          if (!_isScanning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: customColors.cardBackground,
                border: Border(
                  top: BorderSide(color: customColors.cardBorder),
                ),
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _startParsing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: customColors.primaryAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Analyze & Parse Schedule',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanningAnimation(
      AppCustomColors customColors, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Laser Scanning Box Visual
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: customColors.primaryAccent.withOpacity(0.1),
                border: Border.all(
                  color: customColors.primaryAccent.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 40,
                    color: customColors.primaryAccent,
                  ),
                  const SizedBox(
                    width: 78,
                    height: 78,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Gemini Multimodal Parser',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _scanningMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: customColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            // Cancel Button
            OutlinedButton.icon(
              onPressed: _cancelScanning,
              icon: const Icon(Icons.stop_circle_outlined, size: 16),
              label: const Text('Cancel Scan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: customColors.antiHabit,
                side: BorderSide(color: customColors.antiHabit.withOpacity(0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraTab(AppCustomColors customColors, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_imageBytes != null) ...[
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: customColors.cardBorder),
                image: DecorationImage(
                  image: MemoryImage(_imageBytes!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Image Selected (${_selectedImage?.name ?? "routine.jpg"})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _selectedImage = null;
                    _imageBytes = null;
                  }),
                  child: const Text('Change'),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: customColors.cardBorder,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 40,
                    color: customColors.primaryAccent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Snap Timetable or Routine Sheet',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Point camera at printed university schedule, notice board paper, or upload routine screenshot',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: customColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: const Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: customColors.primaryAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined, size: 16),
                        label: const Text('Gallery'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileTab(AppCustomColors customColors, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_selectedFile != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: customColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: customColors.academic.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      color: customColors.academic,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFile!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${((_selectedFile!.size) / 1024).toStringAsFixed(1)} KB • Ready for Gemini parsing',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: customColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _selectedFile = null;
                      _fileBytes = null;
                    }),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: customColors.cardBorder),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.upload_file_outlined,
                    size: 40,
                    color: customColors.academic,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upload Routine Document',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select university PDF routine, syllabus sheet, or timetable exported as .pdf, .txt, or .csv',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: customColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(Icons.folder_open, size: 16),
                    label: const Text('Choose PDF / Document'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: customColors.academic,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextTab(AppCustomColors customColors, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PASTE SCHEDULE OR SYLLABUS TEXT',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: customColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: _pasteSampleText,
                    child: const Text('Use Sample', style: TextStyle(fontSize: 11)),
                  ),
                  TextButton(
                    onPressed: () => _textController.clear(),
                    child: const Text('Clear', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _textController,
            maxLines: 7,
            decoration: InputDecoration(
              hintText:
                  'Paste raw WhatsApp routine announcements, class test dates, or lecture slots...\ne.g. "CSE 3101 Mon & Wed 09:00 Room 301"',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: customColors.cardBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
