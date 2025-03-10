import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';

class RentacarSubpage extends StatefulWidget {
  const RentacarSubpage({super.key});

  @override
  State<RentacarSubpage> createState() => _RentacarSubpageState();
}

class _RentacarSubpageState extends State<RentacarSubpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('렌터카 예약'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            '렌터카 예약/조회/수정/삭제 페이지입니다.\n\n업데이트 예정입니다.',
            style: AppTheme.fieldLabelTextStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
