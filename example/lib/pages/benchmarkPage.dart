// Copyright (c) 2021
// Author: Hugo Pointcheval
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:native_crypto/native_crypto.dart';

import '../session.dart';
import '../widgets/button.dart';
import '../widgets/output.dart';

class BenchmarkPage extends StatefulWidget {
  const BenchmarkPage({key}) : super(key: key);

  @override
  _BenchmarkPageState createState() => _BenchmarkPageState();
}

class _BenchmarkPageState extends State<BenchmarkPage> {
  final Output keyContent = Output(
    textEditingController: TextEditingController(),
  );
  final Output benchmarkStatus = Output(
    textEditingController: TextEditingController(),
    large: true,
  );

  Future<void> _benchmark() async {
    if (Session.secretKey == null || Session.secretKey.isEmpty) {
      benchmarkStatus
          .print('No SecretKey!\nGo in Key tab and generate or derive one.');
      return;
    } else if (!Session.aesCipher.isInitialized) {
      benchmarkStatus.print(
          'Cipher not initialized!\nGo in Key tab and generate or derive one.');
      return;
    }

    benchmarkStatus.print("Benchmark 2/4/8/16/32/64/128/256MB\n");
    List<int> testedSizes = [2, 4, 8, 16, 32, 64, 128, 256];
    String csv =
        "size;encryption time;encode time;decryption time;crypto time\n";

    var beforeBench = DateTime.now();
    for (int size in testedSizes) {
      var bigFile = Uint8List(size * 1000000);
      csv += "${size * 1000000};";
      var cryptoTime = 0;

      // Encryption
      var before = DateTime.now();
      var encryptedBigFile = await Session.aesCipher.encrypt(bigFile);
      var after = DateTime.now();

      var benchmark =
          after.millisecondsSinceEpoch - before.millisecondsSinceEpoch;
      benchmarkStatus.append('[$size MB] Encryption took $benchmark ms\n');

      csv += "$benchmark;";
      cryptoTime += benchmark;

      // Encoding
      before = DateTime.now();
      encryptedBigFile.encode();
      after = DateTime.now();

      benchmark = after.millisecondsSinceEpoch - before.millisecondsSinceEpoch;
      benchmarkStatus.append('[$size MB] Encoding took $benchmark ms\n');

      csv += "$benchmark;";

      // Decryption
      before = DateTime.now();
      await Session.aesCipher.decrypt(encryptedBigFile);
      after = DateTime.now();

      benchmark = after.millisecondsSinceEpoch - before.millisecondsSinceEpoch;
      benchmarkStatus.append('[$size MB] Decryption took $benchmark ms\n');

      csv += "$benchmark;";
      cryptoTime += benchmark;
      csv += "$cryptoTime\n";
    }
    var afterBench = DateTime.now();
    var benchmark =
        afterBench.millisecondsSinceEpoch - beforeBench.millisecondsSinceEpoch;
    var sum = testedSizes.reduce((a, b) => a + b);
    benchmarkStatus.append(
        'Benchmark finished.\nGenerated, encrypted and decrypted $sum MB in $benchmark ms');
    log(csv, name: "Benchmark");
  }

  void _clear() {
    benchmarkStatus.clear();
  }

  @override
  void initState() {
    super.initState();
    if (Session.secretKey != null) {
      keyContent.print(Session.secretKey.encoded.toString());
      Session.aesCipher = AESCipher(
        Session.secretKey,
        CipherParameters(
          // CBC mode
          //BlockCipherMode.CBC,
          //PlainTextPadding.PKCS5,
          // GCM mode
          BlockCipherMode.GCM,
          PlainTextPadding.None,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Align(
              child: Text("Secret Key"),
              alignment: Alignment.centerLeft,
            ),
            keyContent,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Button(
                  onPressed: _benchmark,
                  label: "Launch benchmark",
                ),
                Button(
                  onPressed: _clear,
                  label: "Clear",
                ),
              ],
            ),
            benchmarkStatus,
          ],
        ),
      ),
    );
  }
}
