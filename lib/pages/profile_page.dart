// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:mp_db/providers/profile/profile_provider.dart';
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
                      placeholder: (context, url) => Image.asset(
                        'assets/images/loading.gif',
                        width: 50,
                        fit: BoxFit.contain,
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
            // Firebase 'users' 컬렉션에서 사용자 목록 불러오기
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  width: 250,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(),
                        );
                      }
                      final usersList = snapshot.data!.docs;
                      List<DropdownMenuItem<String>> dropdownItems = [];
                      for (var doc in usersList) {
                        final data = doc.data() as Map<String, dynamic>;
                        final uid = doc.id;
                        if (uid.isNotEmpty) {
                          dropdownItems.add(
                            DropdownMenuItem<String>(
                              value: uid,
                              child: Text(
                                  "${data['name'] ?? 'No Name'} ${data['position'] ?? ''}님",
                                  style: AppTheme.bodyMediumTextStyle),
                            ),
                          );
                        }
                      }
                      // 중복 제거
                      final uniqueDropdownItems = {
                        for (var item in dropdownItems) item.value!: item
                      }.values.toList();
                      if (_selectedUserUid == null ||
                          !uniqueDropdownItems
                              .any((item) => item.value == _selectedUserUid)) {
                        _selectedUserUid = uniqueDropdownItems.isNotEmpty
                            ? uniqueDropdownItems.first.value
                            : null;
                      }
                      return DropdownButton<String>(
                        value: _selectedUserUid,
                        items: uniqueDropdownItems,
                        onChanged: (value) {
                          setState(() {
                            _selectedUserUid = value;
                          });
                        },
                        isExpanded: true,
                      );
                    },
                  ),
                ),
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
                    return SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(),
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
                      return FutureBuilder<DocumentSnapshot>(
                        future: parentRef?.get(),
                        builder: (context, snapshot) {
                          String itemName = '알 수 없음';
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final parentData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            itemName = parentData['ItemName'] ?? '알 수 없음';
                          }
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              leading: Icon(
                                subItemId != null
                                    ? Icons.subdirectory_arrow_right
                                    : Icons.history,
                                color: AppTheme.textHintColor,
                                size: 20,
                              ),
                              title: Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "$itemName",
                                        style: AppTheme.bodyMediumTextStyle
                                            .copyWith(
                                                fontWeight: FontWeight.w400),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        "$formattedTime",
                                        style: AppTheme.bodyMediumTextStyle
                                            .copyWith(
                                                fontSize: 13,
                                                color: AppTheme.textLabelColor),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              subtitle: Padding(
                                padding:
                                    const EdgeInsets.only(top: 2, right: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (action.contains('변경')) ...[
                                      Flexible(
                                        child: Text(
                                          "$mappedField",
                                          style: AppTheme.bodySmallTextStyle
                                              .copyWith(
                                                  color: AppTheme.text4Color),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        "$action",
                                        style: AppTheme.bodySmallTextStyle
                                            .copyWith(
                                                fontSize: 13,
                                                color: AppTheme.text9Color
                                                    .withOpacity(0.3)),
                                      ),
                                      Flexible(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                before ?? '',
                                                style: AppTheme
                                                    .bodyMediumTextStyle
                                                    .copyWith(
                                                        fontSize: 13,
                                                        color: AppTheme
                                                            .textHintColor),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 10,
                                              ),
                                            ),
                                            const Text("  →  ",
                                                style: TextStyle(fontSize: 13)),
                                            Flexible(
                                              flex: 3,
                                              child: SelectableText(
                                                after ?? '',
                                                style: AppTheme
                                                    .bodyMediumTextStyle
                                                    .copyWith(
                                                        fontSize: 13,
                                                        color: AppTheme
                                                            .text4Color),
                                                maxLines: null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else if (action.contains('추가')) ...[
                                      Flexible(
                                        child: Text(
                                          "$mappedField",
                                          style: AppTheme.bodySmallTextStyle
                                              .copyWith(
                                                  color: AppTheme.text4Color),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        "$action",
                                        style: AppTheme.bodySmallTextStyle
                                            .copyWith(
                                                fontSize: 13,
                                                color: AppTheme.text7Color
                                                    .withOpacity(0.5)),
                                      ),
                                      Flexible(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            Flexible(
                                              flex: 3,
                                              child: SelectableText(
                                                after ?? '',
                                                style: AppTheme
                                                    .bodyMediumTextStyle
                                                    .copyWith(
                                                        fontSize: 13,
                                                        color: AppTheme
                                                            .text4Color),
                                                maxLines: null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      Flexible(
                                        child: Text(
                                          "$mappedField",
                                          style: AppTheme.bodySmallTextStyle
                                              .copyWith(
                                                  color: AppTheme.itemListColor
                                                      .withOpacity(0.5),
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  decorationColor:
                                                      AppTheme.itemListColor),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        "$action",
                                        style: AppTheme.bodySmallTextStyle
                                            .copyWith(
                                                fontSize: 13,
                                                color: AppTheme.itemListColor
                                                    .withOpacity(0.5)),
                                      ),
                                      Flexible(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            Flexible(
                                              flex: 3,
                                              child: SelectableText(
                                                before ?? '',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppTheme.itemListColor,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  decorationColor:
                                                      AppTheme.itemListColor,
                                                ),
                                                maxLines: null,
                                              ),
                                            ),
                                          ],
                                        ),
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
