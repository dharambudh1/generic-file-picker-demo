import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:thumbnailer/thumbnailer.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FilePickerResult result = const FilePickerResult([]);
  List<File> permanentFilesList = [];
  final List<FileType> fileTypeList = [
    FileType.any,
    FileType.media,
    FileType.image,
    FileType.video,
    FileType.audio,
  ];
  FileType dropdownValue = FileType.any;
  bool allowMultiple = false;
  ScaffoldMessengerState? messengerState;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    messengerState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    messengerState = ScaffoldMessenger.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("File Picker"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                PermissionStatus status = await permissionCheck();
                if (status != PermissionStatus.granted) {
                  return;
                } else {
                  if (!mounted) {
                    return;
                  } else {
                    bool shouldShowSnackBarMessage = false;
                    FilePickerResult tempList = await pickFiles();
                    for (var e in tempList.paths) {
                      var exists = permanentFilesList.where((v) => v.path == e);
                      if (exists.isEmpty) {
                        permanentFilesList += tempList.paths.map(
                          (value) {
                            return File(value ?? "");
                          },
                        ).toList();
                      } else {
                        permanentFilesList = tempList.paths.map(
                          (value) {
                            return File(value ?? "");
                          },
                        ).toList();
                        shouldShowSnackBarMessage = true;
                      }
                    }
                    if (shouldShowSnackBarMessage) {
                      SnackBar snackBar = const SnackBar(
                        content: Text(
                          "If the newly selected item exists in the current list, that newer item will get discarded. Else, those newly selected items will display in the current list.",
                        ),
                        duration: Duration(seconds: 10),
                      );
                      messengerState?.showSnackBar(snackBar).setState;
                    } else {
                      setState(() {});
                    }
                  }
                }
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              Row(
                children: [
                  const Text("File type"),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<FileType>(
                          icon: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.expand_circle_down),
                          ),
                          value: dropdownValue,
                          onChanged: (FileType? value) {
                            dropdownValue = value ?? FileType.any;
                            setState(() {});
                          },
                          items: fileTypeList.map<DropdownMenuItem<FileType>>(
                            (FileType value) {
                              return DropdownMenuItem<FileType>(
                                value: value,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(value.name),
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text("Multi-select"),
                  const SizedBox(width: 4),
                  Switch.adaptive(
                    value: allowMultiple,
                    onChanged: (value) {
                      allowMultiple = value;
                      setState(() {});
                    },
                  )
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: permanentFilesList.length,
                  itemBuilder: (BuildContext context, int index) {
                    // File file = permanentFilesList[index];
                    final File file = permanentFilesList[index];
                    const String lmt = "application/pdf";
                    final bool isPDF = (lookupMimeType(file.path) ?? "") == lmt;
                    return Dismissible(
                      key: UniqueKey(),
                      onDismissed: (direction) {
                        permanentFilesList.removeAt(index);
                        setState(() {});
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 8,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(18),
                          title: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Thumbnail(
                                  widgetSize: 50,
                                  name: basename(file.path),
                                  dataSize: file.lengthSync(),
                                  useWaterMark: false,
                                  mimeType: lookupMimeType(file.path) ?? "",
                                  dataResolver: () async {
                                    return Future.value(
                                      file.readAsBytesSync(),
                                    );
                                  },
                                  decoration: isPDF
                                      ? WidgetDecoration(
                                          wrapperBgColor: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  basename(file.path),
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                borderRadius: BorderRadius.circular(50),
                                onTap: () {
                                  Share.shareFiles([
                                    file.path
                                  ], mimeTypes: [
                                    lookupMimeType(file.path) ?? "",
                                  ], text: "Share ${basename(file.path)}");
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Icons.share),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              const Divider(),
                              Text(
                                "Extension: ${".${file.path.split('.').last}"}",
                              ),
                              const SizedBox(height: 8),
                              Text("Size (in bytes): ${file.lengthSync()}"),
                              const SizedBox(height: 8),
                              Text("Path: ${file.path}"),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<PermissionStatus> permissionCheck() async {
    PermissionStatus status = PermissionStatus.denied;
    bool isGranted = await Permission.storage.status.isGranted;
    if (isGranted) {
      status = PermissionStatus.granted;
    } else {
      String message = "";
      status = await Permission.storage.request();
      switch (status) {
        case PermissionStatus.denied:
          message = "Storage permission status is denied";
          break;
        case PermissionStatus.granted:
          message = "Storage permission status is granted";
          break;
        case PermissionStatus.restricted:
          message = "Storage permission status is restricted";
          break;
        case PermissionStatus.limited:
          message = "Storage permission status is limited";
          break;
        case PermissionStatus.permanentlyDenied:
          message = "Storage permission status is permanently denied";
          break;
      }
      log("permissionCheck : $message");
      SnackBar snackBar = SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 8),
        action: const SnackBarAction(
          label: "Open settings",
          onPressed: openAppSettings,
        ),
      );
      messengerState?.showSnackBar(snackBar).setState;
    }
    return Future.value(status);
  }

  Future<FilePickerResult> pickFiles() async {
    try {
      result = await FilePicker.platform.pickFiles(
            allowMultiple: allowMultiple,
            type: dropdownValue,
          ) ??
          const FilePickerResult([]);
    } catch (e) {
      log("pickFiles catch : ${e.toString()}}");
      SnackBar snackBar = SnackBar(
        content: Text(
          e.toString(),
        ),
        duration: const Duration(seconds: 8),
      );
      messengerState?.showSnackBar(snackBar).setState;
    }
    return Future.value(result);
  }
}
