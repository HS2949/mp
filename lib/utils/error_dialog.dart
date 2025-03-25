
import 'package:flutter/cupertino.dart';
import 'package:mp_db/models/custom_error.dart';

void errorDialog(BuildContext context, CustomError e) {
  showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(e.code),
          content: Text('${e.plugin}\n${e.message}'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      });
}
