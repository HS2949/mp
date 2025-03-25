import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mp_db/Functions/value_history.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:mp_db/utils/formatters.dart';
import 'package:mp_db/utils/widget_help.dart';
import 'package:provider/provider.dart';

class SubItemAttributes extends StatelessWidget {
  final List<Map<String, dynamic>> attributes;
  final String itemId;
  final String subItemId;
  final String subTitle;
  final Function(BuildContext, String, String, String, String, String, String,
      bool, List<String>) onEdit; 
  const SubItemAttributes({
    Key? key,
    required this.attributes,
    required this.itemId,
    required this.subItemId,
    required this.subTitle,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 40, right: 16),
          child: Wrap(
            spacing: 50.0,
            runSpacing: 20.0,
            children: (List.from(attributes)
                  ..sort((a, b) {
                    final aOrder = (a['FieldOrder']?.toString() ?? '9999');
                    final bOrder = (b['FieldOrder']?.toString() ?? '9999');
                    return int.parse(aOrder).compareTo(int.parse(bOrder));
                  }))
                .map<Widget>((attribute) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final dynamic result =
                      formatValue(context, attribute['FieldValue']);
                  final String fieldKey = attribute['FieldKey'];
                  final String fieldName = attribute['FieldName'];
                  final historyData = itemProvider
                      .getHistoryForTab()?['${fieldKey}_$subItemId'];

                  // 날짜 포맷팅
                  String formattedTime = '';
                  int daysDiff = 0;
                  final timestamp = historyData?['setTime'] as Timestamp?;
                  if (timestamp != null) {
                    final historyDate = timestamp.toDate();
                    daysDiff = DateTime.now().difference(historyDate).inDays;
                    formattedTime =
                        DateFormat("yy. MM. dd", "ko_KR").format(historyDate);
                  }

                  final tooltipText = historyData != null
                      ? '$formattedTime  ${historyData['userName']}  D+$daysDiff'
                      : '';

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.all(0),
                    child: IntrinsicWidth(
                      child: Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Tooltip(
                              message: tooltipText,
                              child: GestureDetector(
                                onDoubleTap: () async {
                                  DateTime initialDate =
                                      timestamp?.toDate() ?? DateTime.now();
                                  DateTime? selectedDate = await showDatePicker(
                                    context: context,
                                    initialDate: initialDate,
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime(2100),
                                    helpText: '날짜를 선택하세요',
                                    cancelText: '취소',
                                    confirmText: '변경',
                                    barrierDismissible: true,
                                  );

                                  if (selectedDate != null) {
                                    String formattedDate =
                                        DateFormat("yy. MM. dd(E)", "ko_KR")
                                            .format(selectedDate);
                                    recordHistory(
                                      context: context,
                                      itemId: itemId,
                                      subItemId: subItemId,
                                      field: fieldKey,
                                      before: '정보 확인:\n$formattedDate',
                                      after: attribute['FieldValue'],
                                      setTime: selectedDate,
                                    );
                                    showOverlayMessage(context,
                                        "$fieldName의 확인 날짜를 $formattedDate 로 갱신하였습니다.");
                                  }
                                },
                                onLongPress: () {
                                  showHistoryDialog(
                                    context: context,
                                    itemId: itemId,
                                    itemName: subTitle,
                                    fieldKey: fieldKey,
                                    subItemId: subItemId,
                                    subTitle: subTitle,
                                  );
                                },
                                child: copyTextWidget(
                                  context,
                                  text: fieldName,
                                  widgetType: TextWidgetType.plain,
                                  style: AppTheme.bodySmallTextStyle.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: const VisualDensity(
                                  horizontal: -4, vertical: -4),
                              constraints: const BoxConstraints(
                                  minWidth: 10, minHeight: 10),
                              tooltip: "Edit",
                              icon: Icon(Icons.edit,
                                  size: 10, color: AppTheme.toolColor),
                              onPressed: () {
                                onEdit(
                                  context,
                                  attribute['FieldKey'],
                                  attribute['FieldName'],
                                  attribute['FieldValue'],
                                  itemId,
                                  subItemId,
                                  subTitle,
                                  false,
                                  attributes
                                      .map((e) => e['FieldKey'].toString())
                                      .toList(),
                                );
                              },
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: result is Widget
                                  ? result
                                  : copyTextWidget(
                                      context,
                                      text: result,
                                      widgetType: TextWidgetType.textField,
                                      controller:
                                          TextEditingController(text: result),
                                      style:
                                          AppTheme.bodySmallTextStyle.copyWith(
                                        fontSize: 13,
                                      ),
                                      maxLines: 0,
                                    ),
                            ),
                            const SizedBox(width: 5),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
