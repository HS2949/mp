// Copyright 2024 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';



class SchemePreview extends StatefulWidget {
  const SchemePreview({
    super.key,
    required this.label,
    required this.scheme,
    required this.brightness,
    required this.colorMatch,
    required this.contrast,
  });

  final String label;
  final ColorScheme scheme;
  final Brightness brightness;
  final bool colorMatch;
  final double contrast;

  @override
  State<SchemePreview> createState() => _SchemePreviewState();
}

class _SchemePreviewState extends State<SchemePreview> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fonts = theme.textTheme;
    // final colors = theme.colorScheme;
    // final dark = widget.brightness == Brightness.dark;

    final scheme = widget.scheme;

    return Theme(
      data: theme.copyWith(colorScheme: scheme),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: fonts.titleMedium!.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
        ],
      ),
    );
  }
}
