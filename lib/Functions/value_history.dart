// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:mp_db/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:mp_db/providers/auth/auth_provider.dart';

Future<void> recordHistory({
  required BuildContext context,
  required String itemId,
  String? subItemId,
  required String field,
  required dynamic before,
  required dynamic after,
  DateTime? setTime,
}) async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final user = authProvider.state.user;
  final userId = user?.uid ?? "unknown";

  CollectionReference historyRef = FirebaseFirestore.instance
      .collection('Items')
      .doc(itemId)
      .collection('history');

  Timestamp setTimestamp = setTime == null
      ? Timestamp.fromDate(DateTime.now())
      : Timestamp.fromDate(setTime);

  final Map<String, dynamic> historyRecord = {
    if (subItemId != null) 'subItemId': subItemId,
    'field': field,
    'userId': userId,
    'timestamp': FieldValue.serverTimestamp(),
    'setTime': setTimestamp,
    'before': before,
    'after': after, // after 값은 항상 포함됨
  };

  await historyRef.add(historyRecord);
}

Widget buildHistoryList(
    {required BuildContext context,
    required String itemId, // 아이템의 고유 id
    String? subItemId, // 필터 조건: subItemId가 있을 경우 해당 조건으로 쿼리
    String? fieldKey, // 특정 필드만 보고 싶다면 전달 (옵션)
    String? subTitle}) {
  // Firestore에서 해당 아이템의 history 서브컬렉션 참조
  CollectionReference historyRef = FirebaseFirestore.instance
      .collection('Items')
      .doc(itemId)
      .collection('history');

  // 쿼리 생성: timestamp 내림차순, 최대 5건
  Query query = historyRef.orderBy('timestamp', descending: true).limit(5);

  // field 조건 추가
  if (fieldKey != null && fieldKey.isNotEmpty) {
    query = query.where('field', isEqualTo: fieldKey);
  }
  // subItemId 조건 추가 (존재할 경우, compositeKey처럼 중복 없이 올바른 데이터를 가져옴)
  if (subItemId != null && subItemId.isNotEmpty) {
    query = query.where('subItemId', isEqualTo: subItemId);
  }

  return StreamBuilder<QuerySnapshot>(
    stream: query.snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text('히스토리 데이터가 없습니다.'));
      }
      final historyDocs = snapshot.data!.docs;

      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        itemCount: historyDocs.length,
        itemBuilder: (context, index) {
          final doc = historyDocs[index];
          final historyData = doc.data() as Map<String, dynamic>;
          final rawField = historyData['field'] ?? '';
          // Provider를 통해 필드 매핑을 사용하는 예시 (provider 설정이 되어있어야 함)
          final mappedField = Provider.of<ItemProvider>(context, listen: false)
                  .fieldMappings[rawField]?['FieldName'] ??
              rawField;
          final before = historyData['before'];
          final after = historyData['after'];
          final timestamp = (historyData['timestamp'] as Timestamp?)?.toDate();
          final formattedTime = timestamp != null
              ? DateFormat("yy.MM.dd(EEE)", "ko_KR").format(timestamp)
              : '';
          String action = "변경";
          if (before == null) {
            action = "추가";
          } else if (after == null) {
            action = "삭제";
          }
          // 문서에 저장된 subItemId (쿼리조건과 다를 수 있으므로 별도 변수로 처리)
          final historySubItemId = historyData['subItemId'];
          // 사용자 id 추출 (historyData['userId']를 통해 가져옴)
          final userId = historyData['userId'];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: Icon(
                // 문서의 subItemId가 존재하면 subItem 관련 아이콘 표시
                historySubItemId != null
                    ? Icons.label_important_outline
                    : Icons.loyalty_outlined,
                color: AppTheme.textHintColor,
                size: 20,
              ),
              // title 영역에 아이템 이름, 시간과 함께 사용자 정보 표시
              title: Padding(
                padding: const EdgeInsets.only(right: 20, bottom: 20),
                child: Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 50,
                  runSpacing: 5,
                  children: [
                    if (subTitle != null) ...[
                      SelectableText(
                        subTitle,
                        style: AppTheme.bodyMediumTextStyle
                            .copyWith(color: AppTheme.itemList0Color),
                      )
                    ],
                    // 사용자 정보 표시 (이름과 직책)
                    Text(
                      Provider.of<UserProvider>(context, listen: false)
                          .getUserName(userId),
                      style: AppTheme.bodySmallTextStyle.copyWith(
                          fontSize: 13, color: AppTheme.textLabelColor),
                    ),
                    Text(
                      "$formattedTime",
                      style: AppTheme.bodyMediumTextStyle.copyWith(
                          fontSize: 13, color: AppTheme.textLabelColor),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
              // 기존의 subtitle 영역: 변경/추가/삭제 내역 표시
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2, right: 20),
                child: Wrap(
                  spacing: 70,
                  runSpacing: 10,
                  children: [
                    if (action.contains('변경')) ...[
                      Text(
                        mappedField == after ? "항목" : mappedField,
                        style: AppTheme.bodySmallTextStyle.copyWith(
                          color: mappedField == after
                              ? AppTheme.textHintColor
                              : AppTheme.text4Color,
                        ),
                      ),
                      Text(
                        "$action",
                        style: AppTheme.bodySmallTextStyle.copyWith(
                            fontSize: 13,
                            color: AppTheme.text9Color.withOpacity(0.3)),
                      ),
                      Wrap(
                        spacing: 20,
                        runSpacing: 5,
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SelectableText(
                            before.toString(),
                            style: AppTheme.bodyMediumTextStyle.copyWith(
                                fontSize: 13, color: AppTheme.textHintColor),
                            maxLines: null,
                          ),
                          const Text("  →  ", style: TextStyle(fontSize: 13)),
                          SelectableText(
                            after ?? '',
                            style: AppTheme.bodyMediumTextStyle.copyWith(
                                fontSize: 13, color: AppTheme.text4Color),
                            maxLines: null,
                          ),
                        ],
                      ),
                    ] else if (action.contains('추가')) ...[
                      Text(
                        "$mappedField",
                        style: AppTheme.bodySmallTextStyle.copyWith(
                            color: AppTheme.text7Color.withOpacity(0.5)),
                      ),
                      Text(
                        "$action",
                        style: AppTheme.bodySmallTextStyle.copyWith(
                            fontSize: 13,
                            color: AppTheme.text7Color.withOpacity(0.5)),
                      ),
                      SelectableText(
                        after ?? '',
                        style: AppTheme.bodyMediumTextStyle.copyWith(
                            fontSize: 13,
                            color: AppTheme.text7Color.withOpacity(0.7)),
                        maxLines: null,
                      ),
                    ] else ...[
                      Text(
                        "$mappedField",
                        style: AppTheme.bodySmallTextStyle.copyWith(
                            color: AppTheme.itemListColor.withOpacity(0.5),
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppTheme.itemListColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "$action",
                        style: AppTheme.bodySmallTextStyle.copyWith(
                            fontSize: 13,
                            color: AppTheme.itemListColor.withOpacity(0.5)),
                      ),
                      SelectableText(
                        before ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.itemListColor,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppTheme.itemListColor,
                        ),
                        maxLines: null,
                      ),
                    ],
                  ],
                ),
              ),
              isThreeLine: false,
            ),
          );
        },
      );
    },
  );
}

void showHistoryDialog({
  required BuildContext context,
  required String itemName,
  required String itemId,
  required String fieldKey,
  String? subItemId,
  String? subTitle,
}) {
  // final double width = MediaQuery.of(context).size.width;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Wrap(
        spacing: 20,
        runSpacing: 5,
        crossAxisAlignment: WrapCrossAlignment.end,
        alignment: WrapAlignment.center,
        children: [
          Text('변경 내역',
              style: AppTheme.appbarTitleTextStyle
                  .copyWith(color: AppTheme.textHintColor, fontSize: 16)),
          Text(
            itemName,
            style: AppTheme.appbarTitleTextStyle
                .copyWith(color: AppTheme.text2Color, fontSize: 26),
          ),
        ],
      ),
      content: Container(
        width: 800,
        height: 400, // 필요에 따라 높이를 조정하세요.
        child: buildHistoryList(
          context: context,
          itemId: itemId,
          fieldKey: fieldKey,
          subItemId: subItemId,
          subTitle: subTitle,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    ),
  );
}
