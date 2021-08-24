import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mind2/slideToConfirm.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class FilesPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<FilesPage> {
  List<bool> checkBoxes = [];
  List<String> files = [];
  bool loaded = false;
  bool deleteDragStarted = false;

  Future<String> getChosenFiles() async {
    var chosenFiles = [];
    for (int i = 0; i < files.length; i++)
      if (checkBoxes[i]) chosenFiles.add(files[i]);
    String fileToShare;
    if (chosenFiles.isEmpty) return "";
    if (chosenFiles.length == 1)
      fileToShare = chosenFiles[0];
    else {
      var encoder = ZipFileEncoder();
      var path = (await getApplicationDocumentsDirectory()).path +
          '/stats_${DateTime.now().year}:${DateTime.now().month}:${DateTime.now().day}:${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}.zip';
      encoder.create(path);
      chosenFiles.forEach((element) {
        encoder.addFile(File(element));
      });
      encoder.close();
      fileToShare = path;
    }
    return fileToShare;
  }

  Future<void> shareFiles() async {
    var fileToShare = await getChosenFiles();
    if (fileToShare.isEmpty) return;
    return shareFile(fileToShare);
  }

  Future<void> shareFile(String fileToShare) async {
    String fileName = fileToShare.substring(fileToShare.lastIndexOf('/') + 1);
    await Share.shareFiles(
        [fileToShare],
        subject: fileName.substring(fileName.lastIndexOf('.')),
        mimeTypes: fileName.endsWith('.zip') ? ['application/zip'] : ['text/plain']
    ).then((value) =>
    fileName.endsWith('.zip') ? File(fileToShare).delete() : {});
  }

  deleteFiles() async {
    var chosenFiles = [];
    for (int i = 0; i < files.length; i++)
      if (checkBoxes[i]) {
        var file = File(files[i]);
        if (file.existsSync()) {
          file.delete();
        }
      }
    loadStats();
  }

  download() async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      status = await Permission.storage.request();
    }

    var filePath = await getChosenFiles();

    if (filePath.isNotEmpty) {
      var path = (await getExternalStorageDirectory())!.path;
      var f = File(filePath);
      f.copy(path + filePath.substring(filePath.lastIndexOf('/') + 1)).then(
          (value) => filePath.endsWith('.zip') ? File(filePath).delete() : {});
      Scaffold.of(context).showBottomSheet((context) {
        return Text('Saved');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        color: Colors.lightBlueAccent[100]!.withOpacity(0.6),
        child: loaded
            ? ListView.builder(
                itemCount: checkBoxes.length,
                itemBuilder: (BuildContext context, int index) {
                  return InkWell(
                    onTap: () {

                    },
                    onLongPress: () {
                      shareFile(files[index]);
                    },
                    child: Card(
                      color: Colors.lightBlueAccent[100]!.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8))),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                        files[index]
                                            .split('/')
                                            .last
                                            .replaceAll('.txt', ''),
                                        style: TextStyle(
                                            color: Colors.black))),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Checkbox(value: checkBoxes[index],
                                  onChanged: (b){
                                setState(() {
                                  checkBoxes[index] = b!;
                                });
                                },
                                materialTapTargetSize: MaterialTapTargetSize.padded,
                                ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                })
            : SizedBox(
                width: 300,
                height: 300,
                child: CircularProgressIndicator(
                  strokeWidth: 16,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: ConfirmationSlider(
              height: 60,
              width: 180,
              shadow: BoxShadow(color: Color.fromARGB(0, 0, 0, 0)),
              backgroundColor: Colors.redAccent[100]!,
              backgroundShape: BorderRadius.circular(30),
              icon: Icons.delete,
              onPressedIcon: Icons.chevron_left_rounded,
              foregroundColor: Colors.redAccent,
              onConfirmation: () => deleteFiles(),
              onStarted: () {},
              child: Text(
                ' Delete ',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: SizedBox(
          //     width: 60,
          //     height: 60,
          //     child: FloatingActionButton(
          //       child: Icon(Icons.file_download, color: Colors.white),
          //       backgroundColor: Colors.green,
          //       shape: CircleBorder(),
          //       onPressed: download,
          //     ),
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: SizedBox(
              width: 60,
              height: 60,
              child: FloatingActionButton(
                child: Icon(Icons.check, color: Colors.white),
                backgroundColor: Colors.orange,
                shape: CircleBorder(),
                onPressed: () {
                  for (int i = 0; i < files.length; i++)
                    if (checkBoxes[i]) {
                      for (int j = 0; j < files.length; j++)
                        checkBoxes[j] = false;
                      setState(() {});
                      return;
                    } else
                      checkBoxes[i] = true;
                  setState(() {});
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: SizedBox(
              width: 60,
              height: 60,
              child: InkWell(
                customBorder: CircleBorder(),
                onTap: shareFiles,
                onLongPress: download,
                child: Material(
                  elevation: Theme.of(context).floatingActionButtonTheme.elevation ?? 6,
                  shape: CircleBorder(),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent
                    ),
                    child: Icon(Icons.share, color: Colors.white),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  static Future<List<String>> loadStatsInit() async {
    List<String> files = [];

    var directory = (await getExternalStorageDirectory())!;
    if (!directory.existsSync()) directory.createSync();
    files = (directory
        .listSync()
        .where((element) => element is File)
        .map((e) => e.path)).toList();

    return files;
  }

  loadStats() {
    loadStatsInit().then((data) {
      setState(() {
        loaded = true;
        checkBoxes = List.generate(data.length, (e) => false);
        files = data;
      });
    });
  }

  @override
  void initState() {
    loadStats();
    super.initState();
  }
}
