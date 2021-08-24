import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_mind2/ProgressButton.dart';
import 'package:flutter_mind2/dataSaver.dart';
import 'package:flutter_mind2/filesPage.dart';
import 'package:flutter_mind2/graphic_painter.dart';
import 'package:path_provider/path_provider.dart';

import 'myParser.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  var gw = GraphicWidget(
    GlobalKey(),
    changeScaleOnPop: false,
  );
  var gw2 = GraphicWidget(
    GlobalKey(),
    changeScaleOnPop: false,
    window: [0, 0, 300],
  );
  DataSaver dataSaver = new DataSaver();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  static final StreamController<double> streamController =
      StreamController<double>.broadcast();
  Stream<double> stream = streamController.stream;
  BluetoothConnection? connection;
  late MyParser myParser;
  bool expanded = true;

  late AnimationController _animationController =
      AnimationController(duration: Duration(milliseconds: 500), vsync: this);
  late var _animation =
      Tween<double>(begin: 0.0, end: 1.0).animate(_animationController)
        ..addListener(() {
          setState(() {});
        });

  bool test = false;

  StreamController<String> infoController = StreamController();
  late var infoStream = infoController.stream;

  @override
  void initState() {
    _animationController.value = 1;
    super.initState();
  }

  void onRecieved(int type, int val) {
    switch (type) {
      case 128:
        streamController.add(val.toDouble());
        break;
      case 5:
        break;
      case 4:
        break;
      case 131:
        break;
      case 2:
        int poorSignal = val;
        break;
      case 1001:
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body: SafeArea(
        child: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    var topRowHeight = MediaQuery.of(context).size.width / 6;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Stack(
                          children: [
                            Positioned(
                              child: Container(
                                height: topRowHeight,
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        new MaterialPageRoute(
                                            builder: (context) => FilesPage()));
                                  },
                                  child: Container(
                                    width: 70,
                                    height: topRowHeight * 0.9,
                                    child: Material(
                                        color: Colors.green,
                                        elevation: 8,
                                        borderRadius: BorderRadius.horizontal(
                                            left: Radius.circular(8)),
                                        child: Icon(
                                          Icons.insert_drive_file_rounded,
                                          color: Colors.white,
                                        )),
                                  ),
                                ),
                              ),
                              right: 0,
                              top: _animation.value *
                                  MediaQuery.of(context).size.height *
                                  7 /
                                  8,
                            ),
                            Positioned(
                              child:  StreamBuilder(
                                stream: infoStream,
                                builder: (context, snapshot) =>
                                Text(
                                  (snapshot.data ?? "  " ) as String,
                                  style: TextStyle(
                                      color: Colors.black38,
                                      fontWeight: FontWeight.normal
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              bottom: MediaQuery.of(context).size.height/4,
                              width: MediaQuery.of(context).size.width,
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              height: topRowHeight +
                                  _animation.value *
                                      (constraints.maxHeight - topRowHeight),
                              child: Align(
                                alignment: Alignment.lerp(Alignment.centerLeft,
                                    Alignment.center, _animation.value)!,
                                child: Container(
                                  width: MediaQuery.of(context).size.width / 2,
                                  child: ProgressButton(
                                    colorExpanded: Colors.lightBlueAccent[400],
                                    buttonHeight: topRowHeight * 0.9,
                                    expanded: expanded,
                                    animation: _animation,
                                    onTap: () {
                                      infoController.add("...");
                                      print('Tapped expanded: ${expanded}, connection ${connection}');
                                      if ((connection != null && connection!.isConnected) && expanded) {
                                        setState(() {
                                          expanded = false;
                                          _animationController.animateBack(0);
                                        });
                                      } else if (connection == null || !connection!.isConnected) {
                                        return connect().then((value) {
                                          print('got ${value}');
                                          if (value) {
                                            setState(() {
                                              expanded = false;
                                              _animationController.animateBack(0);
                                            });
                                            start();
                                          } else {
                                            infoController.add("Not connected");
                                          }
                                        });
                                      } else {
                                        return connection!.close().then((value) {
                                          print('Connection closed');
                                          connection = null;
                                          setState(() {
                                            expanded = true;
                                            _animationController.forward();
                                          });
                                        });
                                      }
                                      /*void foo() async {
                                        test = false;
                                        await Future.delayed(
                                            Duration(seconds: 1));
                                        test = true;
                                        int counter = 1000;
                                        gw.setStream(stream);
                                        gw2.setStream(stream);
                                        while (counter-- > 0 && test) {
                                          var d = Random().nextDouble() * 100;
                                          streamController.add(d);
                                          dataSaver.add(d);
                                          await Future.delayed(
                                              Duration(milliseconds: 200));
                                        }
                                      }
                                      foo();*/

                                      return Future.value(true);
                                    },
                                    child: FittedBox(
                                      fit: BoxFit.fitWidth,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12.0, horizontal: 24),
                                        child: Text(
                                          expanded ? "Connect" : "Disconnect",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          fit: StackFit.loose,
                        ),
                        Container(
                          height: (1 - _animation.value) *
                              (constraints.maxHeight - topRowHeight),
                          color: Colors.lightBlueAccent[100],
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Row(
                              //   children: [
                              //     MaterialButton(
                              //         child: Text('Open'),
                              //         onPressed: () async {
                              //           FilePicker.platform
                              //               .pickFiles()
                              //               .then((value) async {
                              //             var tempFile = File(
                              //                 '${(await getTemporaryDirectory()).path}/tempFile')
                              //               ..createSync(recursive: true);
                              //             await File(value!.files.first.path!)
                              //                 .copy(tempFile.path);
                              //           });
                              //         })
                              //   ],
                              // ),
                              // Row(
                              //   children: [
                              //     Text('Adjust height'),
                              //     Switch(
                              //         value: gw.isTrimming,
                              //         onChanged: (b) {
                              //           gw.isTrimming = b;
                              //         })
                              //   ],
                              // ),
                              StreamBuilder(
                                stream: stream,
                                builder: (context, snapshot) {
                                  return Text(snapshot.hasData
                                      ? (snapshot.data!.toString())
                                      : "No data");
                                },
                              ),
                              Expanded(child: Container(child: gw)),
                              SizedBox(
                                height: 100,
                                child: gw2,
                              )
                            ],
                          ),
                        ),
                      ],
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

  void start() {
    myParser = MyParser(onRecieved);
    connection!.input!.listen((event) {
      myParser.parse(event.buffer.asByteData(), event.length);
    }).asFuture().then((value) {
      setState(() {
        expanded = true;
        _animationController.forward();
        infoController.add('');
      });
      dataSaver.close();
    });
    dataSaver.close();
    gw.clear();
    gw2.clear();
    gw.setStream(stream);
    gw2.setStream(stream);
    stream.listen((event) {
      dataSaver.add(event);
    });
  }

  Future showInfo(info, {delay}) {
    delay ??= delay = Duration(seconds: 2);
    var k = scaffoldKey.currentState!.showBottomSheet((context) {
      return Container(
        padding: EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        height: 70,
        width: MediaQuery.of(context).size.width,
        child: Text(info, textAlign: TextAlign.center),
      );
    }, backgroundColor: Colors.transparent);
    return Future.delayed(delay, () => k.close());
  }

  Future<bool> connect() async {

    bool enabled = (await FlutterBluetoothSerial.instance.isEnabled)!;
    if (!enabled) {
      var requested = (await FlutterBluetoothSerial.instance.requestEnable())!;
      if (!requested) {
        await Future.delayed(Duration(seconds: 2));
        enabled = (await FlutterBluetoothSerial.instance.isEnabled)!;
        if (!enabled)
          return false;
      }
    }

    //  var t = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
    //   infoController.add(r.device.name ?? r.device.address);
    //   if (r.device.name!.contains("MindWave")) {
    //     print('found ${r.device.name}');
    //     await BluetoothConnection.toAddress(r.device.address).then((value) {
    //       connection = value;
    //       print('Connected!');
    //       infoController.add("Waiting for data...");
    //     });
    //     return connection != null;
    //   }
    // });

    infoController.add("Discovering devices...");
    var devices = await FlutterBluetoothSerial.instance.startDiscovery().toList();
    for (var r in devices) {
      infoController.add(r.device.name ?? r.device.address);
      if (r.device.name?.contains("Mind") ?? false) {
        print('found ${r.device.name}');
        await BluetoothConnection.toAddress(r.device.address).then((value) {
          connection = value;
          print('Connected!');
        });
        return connection != null;
      }
    }
    infoController.add("  ");
    return false;
  }
}
