// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vector_graphics/vector_graphics.dart';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart'
    hide FontWeight;

/// The heading text style used for section titles in the demo.
const TextStyle _headingStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
);

/// Entry point for the example app.
void main() {
  runApp(const MyApp());
}

/// The main example app widget.
class MyApp extends StatelessWidget {
  /// Creates a new [MyApp].
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vector Graphics Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: const Text('Vector Graphics Demo')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const <Widget>[
            Text('Runtime SVG (NetworkSvgLoader)', style: _headingStyle),
            SizedBox(height: 8),
            Text(
              'This SVG is downloaded and compiled at runtime '
              'using encodeSvg via NetworkSvgLoader.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            SizedBox(
              width: 200,
              height: 200,
              child: VectorGraphic(
                loader: NetworkSvgLoader(
                  'https://upload.wikimedia.org/wikipedia/commons/f/fd/Ghostscript_Tiger.svg',
                ),
                semanticsLabel: 'Ghostscript Tiger',
              ),
            ),
            SizedBox(height: 32),
            Divider(),
            SizedBox(height: 16),
            AssetTransformerDemo(),
          ],
        ),
      ),
    );
  }
}

/// Demonstrates using [VectorGraphic] with [AssetBytesLoader] to display
/// an SVG that was precompiled at build time by `vector_graphics_compiler`
/// via the Flutter asset transformer system.
class AssetTransformerDemo extends StatelessWidget {
  /// Creates a new [AssetTransformerDemo].
  const AssetTransformerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Build-time Transformer (AssetBytesLoader)', style: _headingStyle),
        SizedBox(height: 8),
        Text(
          'This SVG was precompiled at build time by '
          'vector_graphics_compiler via the Flutter asset '
          'transformer system.',
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        SizedBox(
          width: 150,
          height: 150,
          child: VectorGraphic(
            loader: AssetBytesLoader('assets/dart_logo.svg'),
            semanticsLabel: 'Dart logo',
          ),
        ),
      ],
    );
  }
}

/// A [BytesLoader] that converts a network URL into encoded SVG data.
class NetworkSvgLoader extends BytesLoader {
  /// Creates a [NetworkSvgLoader] that loads an SVG from [url].
  const NetworkSvgLoader(this.url);

  /// The SVG URL.
  final String url;

  @override
  Future<ByteData> loadBytes(BuildContext? context) async {
    return compute(
      (String svgUrl) async {
        final http.Response request = await http.get(Uri.parse(svgUrl));
        final task = TimelineTask()..start('encodeSvg');
        final Uint8List compiledBytes = encodeSvg(
          xml: request.body,
          debugName: svgUrl,
          enableClippingOptimizer: false,
          enableMaskingOptimizer: false,
          enableOverdrawOptimizer: false,
        );
        task.finish();
        // sendAndExit will make sure this isn't copied.
        return compiledBytes.buffer.asByteData();
      },
      url,
      debugLabel: 'Load Bytes',
    );
  }

  @override
  int get hashCode => url.hashCode;

  @override
  bool operator ==(Object other) {
    return other is NetworkSvgLoader && other.url == url;
  }
}
