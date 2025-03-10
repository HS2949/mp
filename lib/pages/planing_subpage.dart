import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';

class PlaningSubpage extends StatefulWidget {
  const PlaningSubpage({super.key});

  @override
  State<PlaningSubpage> createState() => _PlaningSubpageState();
}

class _PlaningSubpageState extends State<PlaningSubpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('일정 작성'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            '일정 작성 관련련 페이지입니다.\n\n업데이트 예정입니다.',
            style: AppTheme.fieldLabelTextStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
