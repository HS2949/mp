// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:mp_db/providers/profile/profile_provider.dart';
import 'package:mp_db/providers/user_provider.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _selectedUserUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 기본 선택은 현재 사용자 uid로 설정 (이미 ProfileProvider에서 관리 중)
    final currentUser = context.read<ProfileProvider>().state.user;
    if (_selectedUserUid == null) {
      _selectedUserUid = currentUser.id;
    }
  }

  Widget _buildProfileCard() {
    final profileProvider = context.watch<ProfileProvider>();
    final user = profileProvider.state.user;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user.profileImage.isNotEmpty)
                Column(
                  children: [
                    CachedNetworkImage(
                      imageUrl: user.profileImage,
                      width: 350,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        // 중앙 정렬
                        child: SizedBox(
                          // 크기 강제 조정
                          width: 50,
                          height: 50,
                          child: Image.asset(
                            'assets/images/loading.gif',
                            fit: BoxFit.contain, // 이미지 비율 유지
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                    const SizedBox(height: 10.0),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: Text(
                    'No profile image available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('- 이메일 : ${user.email}'),
                    const SizedBox(height: 10.0),
                    Text('- 이름 : ${user.name}'),
                    const SizedBox(height: 10.0),
                    Text('- 직책 : ${user.position}'),
                    const SizedBox(height: 10.0),
                    Text(
                      '- ID: ${user.id}',
                      style: AppTheme.tagTextStyle,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    final itemProvider = context.watch<ItemProvider>();
    final userProvider = context.watch<UserProvider>();
    final double width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
      child: SizedBox(
        width: double.infinity,
        // 높이를 고정하거나 flexible하게 만들 수 있음
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User History',
              style: AppTheme.appbarTitleTextStyle,
            ),
            const SizedBox(height: 10),
            Center(
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 20,
                runSpacing: 5,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    width: 200,
                    child: DropdownButton<String>(
                      value: _selectedUserUid,
                      items: userProvider.users.map((userDoc) {
                        final data = userDoc.data() as Map<String, dynamic>;
                        final uid = userDoc.id;
                        return DropdownMenuItem<String>(
                          value: uid,
                          child: Text(
                              "${data['name'] ?? 'No Name'} ${data['position'] ?? ''}님",
                              style: AppTheme.bodyMediumTextStyle),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUserUid = value;
                        });
                      },
                      isExpanded: true,
                    ),
                  ),
                  if (width > narrowScreenWidthThreshold*1.15) ...[
                    Opacity(
                      opacity: 0.3,
                      child: Container(
                        width: 300, // 화면 너비의 50%
                        height: 30,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                                'assets/images/miceplan_font.png'), // 배경 이미지 경로
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '변경 내역:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            // collectionGroup 쿼리를 사용해 모든 아이템의 history 서브컬렉션에서
            // 선택한 사용자(userId) 기준 변경 내역을 가져옴.
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collectionGroup('history')
                    .where('userId', isEqualTo: _selectedUserUid)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 100, // 원하는 크기 설정
                        height: 100, // 원하는 크기 설정
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final historyDocs = snapshot.data!.docs;
                  if (historyDocs.isEmpty) {
                    return const Text('변경 이력이 없습니다.');
                  }
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: historyDocs.length,
                    itemBuilder: (context, index) {
                      final doc = historyDocs[index];
                      final historyData = doc.data() as Map<String, dynamic>;
                      final rawField = historyData['field'] ?? '';
                      final mappedField = itemProvider.fieldMappings[rawField]
                              ?['FieldName'] ??
                          rawField;
                      final before = historyData['before'];
                      final after = historyData['after'];
                      final timestamp =
                          (historyData['timestamp'] as Timestamp?)?.toDate();
                      final formattedTime = timestamp != null
                          ? DateFormat("yy.MM.dd(EEE)", "ko_KR")
                              .format(timestamp)
                          : '';
                      String action = "변경";
                      if (before == null) {
                        action = "추가";
                      } else if (after == null) {
                        action = "삭제";
                      }
                      final subItemId = historyData['subItemId'];
                      final parentRef = doc.reference.parent.parent;
                      // subItemId가 있으면 상위 문서와 SubItems 컬렉션의 문서를 동시에 가져옴
                      final subItemRef =
                          parentRef?.collection('Sub_Items').doc(subItemId);
                      print('데이터 읽기 ');
                      return FutureBuilder<List<DocumentSnapshot>>(
                        future: Future.wait([
                          parentRef!.get(),
                          subItemRef!.get(),
                        ]),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: CircularProgressIndicator(
                                        color: AppTheme.backgroundColor)));
                          }
                          final parentSnapshot = snapshot.data![0];
                          final subItemSnapshot = snapshot.data![1];
                          String itemName = '';
                          String subItemName = '';
                          if (parentSnapshot.exists) {
                            final parentData =
                                parentSnapshot.data() as Map<String, dynamic>;
                            itemName = parentData['ItemName'] ?? '';
                          }
                          if (subItemSnapshot.exists) {
                            final subItemData =
                                subItemSnapshot.data() as Map<String, dynamic>;
                            subItemName = subItemData['SubName'] ?? '';
                          }
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              leading: Icon(
                                subItemId != null
                                    ? Icons.label_important_outline
                                    : Icons.loyalty_outlined,
                                color: AppTheme.textHintColor,
                                size: 20,
                              ),
                              title: Padding(
                                padding: const EdgeInsets.only(
                                    right: 20, bottom: 10),
                                child: Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      itemName,
                                      style: AppTheme.bodyMediumTextStyle
                                          .copyWith(
                                              fontWeight: FontWeight.w400),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      subItemName,
                                      style: AppTheme.bodyMediumTextStyle
                                          .copyWith(
                                              color: AppTheme.itemList0Color,
                                              fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "$formattedTime",
                                      style: AppTheme.bodyMediumTextStyle
                                          .copyWith(
                                              fontSize: 13,
                                              color: AppTheme.textLabelColor),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
                                    ),
                                  ],
                                ),
                              ),
                              subtitle: Padding(
                                padding:
                                    const EdgeInsets.only(top: 2, right: 20),
                                child: Wrap(
                                  spacing: 70,
                                  runSpacing: 10,
                                  // alignment: WrapAlignment.spaceBetween,
                                  children: [
                                    if (action.contains('변경')) ...[
                                      Text(
                                        mappedField == after
                                            ? "항목"
                                            : mappedField,
                                        style: AppTheme.bodySmallTextStyle
                                            .copyWith(
                                          color: mappedField == after
                                              ? AppTheme.textHintColor
                                              : AppTheme.text4Color,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "$action",
                                        style: AppTheme.bodySmallTextStyle
                                            .copyWith(
                                                fontSize: 13,
                                                color: AppTheme.text9Color
                                                    .withOpacity(0.3)),
                                      ),
                                      Wrap(
                                        spacing: 20,
                                        runSpacing: 5,
                                        alignment: WrapAlignment.start,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          SelectableText(
                                            before.toString(),
                                            style: AppTheme.bodyMediumTextStyle
                                                .copyWith(
                                                    fontSize: 13,
                                                    color:
                                                        AppTheme.textHintColor),
                                            maxLines: null,
                                          ),
                                          const Text("→",
                                              style: TextStyle(fontSize: 13)),
                                          SelectableText(
                                            after ?? '',
                                            style: AppTheme.bodyMediumTextStyle
                                                .copyWith(
                                                    fontSize: 13,
                                                    color: AppTheme.text4Color),
                                            maxLines: null,
                                          ),
                                        ],
                                      ),
                                    ] else if (action.contains('추가')) ...[
                                      Text(
                                        "$mappedField",
                                        style: AppTheme.bodySmallTextStyle
                                            .copyWith(
                                                color: AppTheme.text7Color
                                                    .withOpacity(0.5)),
                                      ),
                                      Text(
                                        "$action",
                                        style: AppTheme.bodySmallTextStyle
                                            .copyWith(
                                                fontSize: 13,
                                                color: AppTheme.text7Color
                                                    .withOpacity(0.5)),
                                      ),
                                      SelectableText(
                                        after ?? '',
                                        style: AppTheme.bodyMediumTextStyle
                                            .copyWith(
                                                fontSize: 13,
                                                color: AppTheme.text7Color
                                                    .withOpacity(0.7)),
                                        maxLines: null,
                                      ),
                                    ] else ...[
                                      Text(
                                        "$mappedField",
                                        style: AppTheme.bodySmallTextStyle
                                            .copyWith(
                                                color:
                                                    AppTheme
                                                        .itemListColor
                                                        .withOpacity(0.5),
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                decorationColor:
                                                    AppTheme.itemListColor),
                                      ),
                                      Text(
                                        "$action",
                                        style: AppTheme.bodySmallTextStyle
                                            .copyWith(
                                                fontSize: 13,
                                                color: AppTheme.itemListColor
                                                    .withOpacity(0.5)),
                                      ),
                                      SelectableText(
                                        before ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.itemListColor,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          decorationColor:
                                              AppTheme.itemListColor,
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('프로필 관리', style: AppTheme.appbarTitleTextStyle),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= mediumWidthBreakpoint;
          // AnimatedSwitcher로 전환 시 애니메이션 효과 추가
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isWide
                ? Row(
                    key: const ValueKey('wideLayout'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          flex: 2,
                          child: SingleChildScrollView(
                              child: _buildProfileCard())),
                      Expanded(flex: 3, child: _buildHistorySection()),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      key: const ValueKey('narrowLayout'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProfileCard(),
                        SizedBox(
                          height: MediaQuery.of(context).size.height,
                          child: _buildHistorySection(),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
