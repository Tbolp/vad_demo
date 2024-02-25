import 'dart:developer';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';

class VadView extends StatefulWidget {
  const VadView({super.key});

  @override
  State<StatefulWidget> createState() {
    return VadViewState();
  }
}

// typedef LoadFun = Int32 Function(Pointer<Int8>, Int32, Pointer<Int8>, Int32);
// typedef Load = int Function(Pointer<Int8>, int, Pointer<Int8>, int);
// typedef RunFun = Float Function(
//     Pointer<Float>, Int32, Pointer<Float>, Pointer<Float>);
// typedef Run = double Function(
//     Pointer<Float>, int, Pointer<Float>, Pointer<Float>);

// Load load = DynamicLibrary.open('vad_demo.exe')
//     .lookup<NativeFunction<LoadFun>>('load')
//     .asFunction<Load>();
// Run run = DynamicLibrary.open('vad_demo.exe')
//     .lookup<NativeFunction<RunFun>>('run')
//     .asFunction<Run>();

typedef CreateFun = Int64 Function(Pointer<Int8>, Int32, Pointer<Int8>, Int32);
typedef Create = int Function(Pointer<Int8>, int, Pointer<Int8>, int);
typedef RunFun = Int32 Function(Int64, Pointer<Uint8>, Int32);
typedef Run = int Function(int, Pointer<Uint8>, int);
typedef DestroyFun = Void Function(Int64);
typedef Destroy = void Function(int);

Create create = DynamicLibrary.open('libvad_demo.so')
    .lookup<NativeFunction<CreateFun>>('create')
    .asFunction<Create>();
Run run = DynamicLibrary.open('libvad_demo.so')
    .lookup<NativeFunction<RunFun>>('run')
    .asFunction<Run>();
Destroy destroy = DynamicLibrary.open('libvad_demo.so')
    .lookup<NativeFunction<DestroyFun>>('destroy')
    .asFunction<Destroy>();

class VadViewState extends State<VadView> {
  bool detect = false;
  bool running = false;
  bool need_stop = false;

  @override
  void initState() {
    super.initState();
    // init();
  }

  // void init() async {
  //   var param_blob = await rootBundle.load("models/vad.param");
  //   var param = malloc.allocate<Int8>(param_blob.lengthInBytes);
  //   param
  //       .asTypedList(param_blob.lengthInBytes)
  //       .setAll(0, param_blob.buffer.asInt8List());
  //   var n = param.asTypedList(param_blob.lengthInBytes);
  //   var model_blob = await rootBundle.load("models/vad.bin");
  //   var model = malloc.allocate<Int8>(model_blob.lengthInBytes);
  //   model
  //       .asTypedList(model_blob.lengthInBytes)
  //       .setAll(0, model_blob.buffer.asInt8List());
  //   var ret =
  //       load(param, param_blob.lengthInBytes, model, model_blob.lengthInBytes);
  //   log("load model $ret");
  //   malloc.free(param);
  //   malloc.free(model);
  // }

  // void vad_check() async {
  //   setState(() {
  //     running = true;
  //   });
  //   need_stop = false;
  //   var speaking = false;
  //   var count = 0;
  //   var record = AudioRecorder();
  //   var stream = await record.startStream(const RecordConfig(
  //       encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1));
  //   var c = malloc.allocate<Float>(2 * 64 * 4, alignment: 32);
  //   var h = malloc.allocate<Float>(2 * 64 * 4, alignment: 32);
  //   var d = malloc.allocate<Float>(512 * 4, alignment: 32);
  //   c.asTypedList(64 * 2).fillRange(0, 64 * 2, 0);
  //   h.asTypedList(64 * 2).fillRange(0, 64 * 2, 0);
  //   var start = 0;
  //   var o =
  //       await File('test.pcm').writeAsBytes(Uint8List(0), mode: FileMode.write);
  //   await for (Uint8List data in stream) {
  //     // await o.writeAsBytes(data, mode: FileMode.append);
  //     for (var i = 0; i < data.length / 2; i++) {
  //       d[start] =
  //           (data.buffer.asByteData().getInt16(i * 2, Endian.big) / 32768)
  //               .toDouble();
  //       start++;
  //       if (start == 512) {
  //         var v = run(d, 512, c, h);
  //         // print(v);
  //         if (v > 0.5) {
  //           print(v);
  //           if (!speaking) {
  //             setState(() {
  //               detect = true;
  //             });
  //           }
  //           speaking = true;
  //         } else {
  //           count++;
  //           if (count > 5) {
  //             c.asTypedList(64 * 2).fillRange(0, 64 * 2, 0);
  //             h.asTypedList(64 * 2).fillRange(0, 64 * 2, 0);
  //             count = 0;
  //             if (speaking) {
  //               setState(() {
  //                 detect = false;
  //               });
  //               speaking = false;
  //             }
  //           }
  //         }
  //         if (speaking) {
  //           var mem = Uint8List(512 * 2);
  //           for (var j = 0; j < 512; j++) {
  //             var tmp = (d[j] * 32768).toInt();
  //             mem[2 * j] = tmp & 0xff;
  //             mem[2 * j + 1] = (tmp >> 8) & 0xff;
  //           }
  //           await o.writeAsBytes(mem, mode: FileMode.append);
  //         }
  //         start = 0;
  //       }
  //     }
  //     if (need_stop) {
  //       break;
  //     }
  //   }
  //   malloc.free(c);
  //   malloc.free(h);
  //   malloc.free(d);
  //   need_stop = false;
  //   setState(() {
  //     running = false;
  //   });
  // }

  // void test() async {
  //   // var data_blob = await rootBundle.load("assets/test1.wav");
  //   var data_blob = await File("test.pcm").readAsBytes();
  //   var data = data_blob.buffer.asInt16List();
  //   var c = malloc.allocate<Float>(2 * 64 * 4, alignment: 32);
  //   var h = malloc.allocate<Float>(2 * 64 * 4, alignment: 32);
  //   var d = malloc.allocate<Float>(512 * 4, alignment: 32);
  //   c.asTypedList(64 * 2).fillRange(0, 64 * 2, 0);
  //   h.asTypedList(64 * 2).fillRange(0, 64 * 2, 0);
  //   var start = 0;
  //   var speaking = false;
  //   for (var i = 0; i < data.length; i++) {
  //     d[start] = (data[i] / 32768).toDouble();
  //     start++;
  //     if (start == 512) {
  //       var ct = c.asTypedList(64 * 2);
  //       var v = run(d, 512, c, h);
  //       // print(v);
  //       if (v > 0.5) {
  //         if (!speaking) {
  //           print('start $i');
  //         }
  //         speaking = true;
  //       } else {
  //         if (speaking) {
  //           print('stop $i');
  //         }
  //         speaking = false;
  //       }
  //       start = 0;
  //     }
  //   }
  //   if (speaking) {
  //     print('stop $data.length');
  //   }
  //   malloc.free(c);
  //   malloc.free(h);
  //   malloc.free(d);
  // }

  Future<int> init() async {
    var param_blob = await rootBundle.load("models/vad.param");
    var param = malloc.allocate<Int8>(param_blob.lengthInBytes);
    param
        .asTypedList(param_blob.lengthInBytes)
        .setAll(0, param_blob.buffer.asInt8List());
    var n = param.asTypedList(param_blob.lengthInBytes);
    var model_blob = await rootBundle.load("models/vad.bin");
    var model = malloc.allocate<Int8>(model_blob.lengthInBytes);
    model
        .asTypedList(model_blob.lengthInBytes)
        .setAll(0, model_blob.buffer.asInt8List());
    var ret = create(
        param, param_blob.lengthInBytes, model, model_blob.lengthInBytes);
    malloc.free(param);
    malloc.free(model);
    return ret;
  }

  void vad_check() async {
    setState(() {
      running = true;
    });
    need_stop = false;
    var handle = await init();
    var record = AudioRecorder();
    var stream = await record.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1));
    // var o =
    //     await File('test.pcm').writeAsBytes(Uint8List(0), mode: FileMode.write);
    var chunk = malloc.allocate<Uint8>(512 * 2, alignment: 32);
    var start = 0;
    await for (Uint8List data in stream) {
      for (var i = 0; i < data.length; i++) {
        chunk[start] = data[i];
        start++;
        if (start == 512 * 2) {
          if (run(handle, chunk, 512 * 2) == 1) {
            // await o.writeAsBytes(chunk.asTypedList(512 * 2),
            //     mode: FileMode.append);
            setState(() {
              detect = true;
            });
          } else {
            setState(() {
              detect = false;
            });
          }
          start = 0;
        }
      }
      if (need_stop) {
        break;
      }
    }
    destroy(handle);
    await record.dispose();
    need_stop = false;
    setState(() {
      detect = false;
      running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Demo"),
      ),
      body: Container(
          padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: detect ? Colors.green : Colors.red,
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
                      child: ElevatedButton(
                    onPressed: () {
                      if (!running) {
                        vad_check();
                      } else {
                        need_stop = true;
                      }
                    },
                    child: Text(running ? 'Stop' : 'Start'),
                  )),
                ],
              ),
            ],
          )),
    );
  }
}
