import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressor extends StatefulWidget {
  @override
  _ImageCompressorState createState() => _ImageCompressorState();
}

class _ImageCompressorState extends State<ImageCompressor> {
  String? _selectedFolderPath;
  List<File>? _selectedFiles;
  double _compressionQuality = 1.0; // Start with 100% quality
  bool _isCompressing = false;

  Future<void> pickFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _selectedFolderPath = selectedDirectory;
        _selectedFiles = null; // Reset files if folder is picked
      });
    }
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      setState(() {
        _selectedFiles = result.paths.map((path) => File(path!)).toList();
        _selectedFolderPath = null; // Reset folder if files are picked
      });
    }
  }

  Future<void> _compressImages() async {
    if (_selectedFolderPath == null && _selectedFiles == null) {
      print('No folder or files selected.');
      return;
    }

    setState(() {
      _isCompressing = true;
    });

    try {
      Directory outputDirectory = Directory('/storage/emulated/0/PR');
      if (!outputDirectory.existsSync()) {
        outputDirectory.createSync(recursive: true);
      }

      if (_selectedFolderPath != null) {
        Directory inputDirectory = Directory(_selectedFolderPath!);
        if (!inputDirectory.existsSync()) {
          print('Directory does not exist.');
          return;
        }
        await _compressDirectory(inputDirectory, outputDirectory);
      } else if (_selectedFiles != null) {
        for (var file in _selectedFiles!) {
          await _compressFile(file, outputDirectory.path);
        }
      }

      print('Compression completed for all images.');
    } catch (e) {
      print('Error compressing images: $e');
    } finally {
      setState(() {
        _isCompressing = false;
      });
    }
  }

  Future<void> _compressDirectory(Directory inputDir, Directory outputDir) async {
    List<FileSystemEntity> entities = inputDir.listSync();

    for (var entity in entities) {
      if (entity is File && _isImageFile(entity)) {
        await _compressFile(entity, outputDir.path, basePath: inputDir.path);
      } else if (entity is Directory) {
        String newOutputDirPath = '${outputDir.path}/${entity.path.split('/').last}';
        Directory newOutputDir = Directory(newOutputDirPath);
        if (!newOutputDir.existsSync()) {
          newOutputDir.createSync(recursive: true);
        }
        await _compressDirectory(entity, newOutputDir);
      }
    }
  }

  bool _isImageFile(File file) {
    final supportedExtensions = ['jpg', 'jpeg', 'png'];
    final extension = file.path.split('.').last.toLowerCase();
    return supportedExtensions.contains(extension);
  }

  Future<void> _compressFile(File inputFile, String outputBasePath, {String? basePath}) async {
    String relativePath = basePath != null ? inputFile.path.replaceFirst(basePath, '') : '/${inputFile.path.split('/').last}';
    String outputFilePath = '$outputBasePath$relativePath';

    // Create necessary directories for output file path
    String outputFileDir = outputFilePath.substring(0, outputFilePath.lastIndexOf('/'));
    Directory(outputFileDir).createSync(recursive: true);

    XFile? result = await FlutterImageCompress.compressAndGetFile(
      inputFile.path,
      outputFilePath,
      quality: (_compressionQuality * 100).toInt(),
    );

    if (result != null) {
      print('File ${result.path} size after compression: ${await result.length()} bytes');
    } else {
      print('Compression failed for ${inputFile.path}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Compressor',),centerTitle: true,),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                children: [
                  containerBox(Colors.green,"Pick Files",_pickFiles),
                  containerBox(Colors.red,"Pick Folder",pickFolder),

                ],
              )
              ,
              if (_selectedFolderPath != null) ...[
                Text('Selected Folder: $_selectedFolderPath'),
              ],
              if (_selectedFiles != null) ...[
                Text('Selected Files: ${_selectedFiles!.map((e) => e.path.split('/').last).join(', ')}'),
              ],
              const SizedBox(height: 20.0),
             Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                  Text('Image Quality:'),
                SizedBox(width: 10), Slider(
                  value: _compressionQuality,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  label: '${(_compressionQuality * 100).toInt()}%',
                  onChanged: (newValue) {
                    setState(() {
                      _compressionQuality = newValue;
                    });
                  },
                ),],
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: _isCompressing ? null : _compressImages,
                child: _isCompressing ? CircularProgressIndicator() : Text('Compress Images'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

 containerBox(MaterialColor color, String txt, goto) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: goto,
        child: Container(
          height: Get.height / 4,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(42)),
            boxShadow: [
              BoxShadow(
                color: color.shade400, // Using MaterialColor shades
                offset: const Offset(0, 20),
                blurRadius: 30,
                spreadRadius: -5,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: [
                color.shade200, // Using MaterialColor shades
                color.shade300, // Using MaterialColor shades
                color.shade500, // Using MaterialColor shades
                color.shade500, // Using MaterialColor shades
              ],
              stops: const [0.1, 0.3, 0.9, 1.0],
            ),
          ),
          child: Center(
            child: Text(
              txt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    ),
  );
}

