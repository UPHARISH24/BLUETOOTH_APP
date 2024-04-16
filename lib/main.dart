import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: Colors.blue,
      ),
      home: const BulbPage(),
    );
  }
}

class BulbPage extends StatefulWidget {
  const BulbPage({Key? key});

  @override
  State<BulbPage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<BulbPage> {
  final String serviceUuid = '';
  final String characterUuid = '';
  bool _isBulbON = false;
  bool isLoading = false;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? currentCharacteristic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isBulbON ? Colors.yellow.shade50 : Colors.blue.shade50,
      body: ModalProgressHUD(
        inAsyncCall: isLoading,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isBulbON ? 'Bulb is On' : 'Bulb is OFF',
                style: TextStyle(
                  fontSize: 24,
                  color:
                      _isBulbON ? Colors.yellow.shade100 : Colors.blue.shade100,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color:
                      _isBulbON ? Colors.yellow.shade100 : Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isBulbON ? Icons.lightbulb : Icons.lightbulb_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    connectedDevice == null
                        ? () {}
                        : () async {
                            _isBulbON = !_isBulbON;
                            final dataToSend = _isBulbON ? "01" : "00";
                            final List<int> finalDataToWrite =
                                hex.decode(dataToSend);
                            currentCharacteristic!.write(finalDataToWrite);
                            setState(() {});
                          };
                  },
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      connectedDevice != null ? Colors.red : Colors.blue,
                ),
                onPressed: connectedDevice != null
                    ? () async {
                        await connectedDevice!.disconnect();
                        setState(() {
                          connectedDevice = null;
                          currentCharacteristic = null;
                          _isBulbON = false;
                        });
                      }
                    : () async {
                        setState(() {
                          isLoading = true;
                        });
                        ////////   List<ScanResult> scanResult =
                        //    FlutterBluePlus.startScan(
                        //      timeout: const Duration(seconds: 2));
                        final List<ScanResult> scanResult =
                            FlutterBluePlus.startScan(
                                    timeout: const Duration(seconds: 2))
                                as List<ScanResult>;
                        Object? device = await showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  child: ListView.separated(
                                      itemBuilder: (context, index) {
                                        //  final Future<void><ScanResult>  scanResult= FlutterBluePlus.startScan();

                                        final result = scanResult[index];
                                        return ListTile(
                                          title: Text(result.device.name.isEmpty
                                              ? "UK"
                                              : result.device.name),
                                          trailing: ElevatedButton(
                                              onPressed: () async {
                                                await result.device.connect();
                                                Navigator.of(context)
                                                    .pop(result.device);
                                              },
                                              child: const Text('CONNECT')),
                                        );
                                      },
                                      separatorBuilder: (context, index) {
                                        return const SizedBox(
                                          height: 2,
                                        );
                                      },
                                      itemCount: scanResult.length),
                                );
                              },
                            );
                          },
                        );
                        if (device is BluetoothDevice) {
                          final List<BluetoothService> services =
                              await device.discoverServices();
                          for (var i = 0; i < services.length; i++) {
                            if (services[i].uuid.toString().toLowerCase() ==
                                serviceUuid) {
                              final lsOfChar = services[i].characteristics;
                              for (var i = 0; i < lsOfChar.length; i++) {
                                if (lsOfChar[i].uuid.toString().toLowerCase() ==
                                    characterUuid) {
                                  currentCharacteristic = lsOfChar[i];
                                }
                              }
                            }
                            if (currentCharacteristic == null) {
                              print('not found');
                            } else {
                              final List<int> raw =
                                  await currentCharacteristic!.read();
                              final value = hex.encode(raw);
                              final actualValue = int.parse(value, radix: 16);
                              _isBulbON = actualValue == 1;
                              connectedDevice = device;
                            }
                          }
                          await device.disconnect();
                        }
                        setState(() {
                          isLoading = false;
                        });
                      },
                child: Text(
                  connectedDevice == null
                      ? 'Device is not Connected'
                      : 'Disconntect',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
