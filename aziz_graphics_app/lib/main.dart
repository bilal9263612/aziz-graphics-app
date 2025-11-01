import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';

void main() {
  runApp(const AzizGraphicsApp());
}

class AzizGraphicsApp extends StatelessWidget {
  const AzizGraphicsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AZIZ GRAPHICS',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> htmlFiles = [];
  String? selectedFile;
  late WebViewController _webViewController;
  DateTime? _lastLongPressTime;
  Timer? _longPressTimer;
  bool _isLongPressing = false;
  double _longPressProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadHtmlFiles();
    _initWebViewController();
  }

  void _initWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {},
        ),
      );
  }

  Future<void> _loadHtmlFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final htmlDir = Directory('${appDir.path}/html_files');
      
      if (!await htmlDir.exists()) {
        await htmlDir.create(recursive: true);
      }

      final files = htmlDir.listSync();
      setState(() {
        htmlFiles = files
            .where((f) => f.path.endsWith('.html'))
            .map((f) => f.path.split('/').last)
            .toList();
      });
    } catch (e) {
      _showError('Error loading files: $e');
    }
  }

  Future<void> _pickAndSaveHtmlFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['html'],
      );

      if (result != null) {
        final sourceFile = File(result.files.single.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final htmlDir = Directory('${appDir.path}/html_files');
        
        if (!await htmlDir.exists()) {
          await htmlDir.create(recursive: true);
        }

        final fileName = result.files.single.name;
        final destFile = File('${htmlDir.path}/$fileName');
        
        await sourceFile.copy(destFile.path);
        
        _loadHtmlFiles();
        _showSuccess('File saved: $fileName');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _deleteFile(String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/html_files/$fileName');
      
      if (await file.exists()) {
        await file.delete();
        setState(() {
          htmlFiles.remove(fileName);
          if (selectedFile == fileName) {
            selectedFile = null;
          }
        });
        _showSuccess('File deleted');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _openFile(String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/html_files/$fileName');
      
      if (await file.exists()) {
        setState(() {
          selectedFile = fileName;
        });
        
        final htmlContent = await file.readAsString();
        _webViewController.loadHtmlString(htmlContent);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HtmlViewerScreen(
              fileName: fileName,
              webViewController: _webViewController,
              htmlContent: htmlContent,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _onLogoLongPress() {
    _lastLongPressTime = DateTime.now();
    _isLongPressing = true;
    _longPressProgress = 0;

    _longPressTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        _longPressProgress += 0.1;
      });

      if (_longPressProgress >= 1.0) {
        _longPressTimer?.cancel();
        _showLogoChangeDialog();
        _isLongPressing = false;
      }
    });
  }

  void _onLogoLongPressEnd() {
    _longPressTimer?.cancel();
    _isLongPressing = false;
    setState(() {
      _longPressProgress = 0;
    });
  }

  void _showLogoChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.cyan.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Logo',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.cyan,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 24),
              Text(
                'Current: 🍌',
                style: TextStyle(fontSize: 48),
              ),
              SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter emoji...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.cyan.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.cyan.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.cyan),
                  ),
                ),
                style: TextStyle(color: Colors.white, fontSize: 24),
                maxLength: 1,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.cyan.withOpacity(0.5)),
                  ),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.withOpacity(0.8),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.cyan.withOpacity(0.8),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        title: Row(
          children: [
            GestureDetector(
              onLongPress: _onLogoLongPress,
              onLongPressEnd: (_) => _onLogoLongPressEnd(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isLongPressing)
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: _longPressProgress,
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                      ),
                    ),
                  Text(
                    '🍌',
                    style: TextStyle(fontSize: 32),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Text(
              'AZIZ GRAPHICS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: htmlFiles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey[700]),
                  SizedBox(height: 16),
                  Text(
                    'No HTML Files',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first HTML file',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: htmlFiles.length,
              itemBuilder: (context, index) {
                final fileName = htmlFiles[index];
                return Card(
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.cyan.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Icon(Icons.html, color: Colors.cyan),
                    title: Text(
                      fileName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: PopupMenuButton(
                      color: Colors.grey[900],
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Text('Open', style: TextStyle(color: Colors.cyan)),
                          onTap: () => _openFile(fileName),
                        ),
                        PopupMenuItem(
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                          onTap: () => _deleteFile(fileName),
                        ),
                      ],
                    ),
                    onTap: () => _openFile(fileName),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndSaveHtmlFile,
        backgroundColor: Colors.cyan.withOpacity(0.8),
        child: Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }
}

class HtmlViewerScreen extends StatefulWidget {
  final String fileName;
  final WebViewController webViewController;
  final String htmlContent;

  const HtmlViewerScreen({
    Key? key,
    required this.fileName,
    required this.webViewController,
    required this.htmlContent,
  }) : super(key: key);

  @override
  State<HtmlViewerScreen> createState() => _HtmlViewerScreenState();
}

class _HtmlViewerScreenState extends State<HtmlViewerScreen> {
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(widget.htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        title: Text(
          widget.fileName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.cyan),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: WebViewWidget(controller: _webViewController),
    );
  }
}
