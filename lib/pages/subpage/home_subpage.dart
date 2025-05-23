import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/utils/customWebview.dart';

class HomeSubpage extends StatefulWidget {
  const HomeSubpage({super.key});

  @override
  State<HomeSubpage> createState() => _HomeSubpageState();
}

class _HomeSubpageState extends State<HomeSubpage> {
  @override
  Widget build(BuildContext context) {
    // Map<int, List<String>>: [지역, 장소]
    final Map<int, List<String>> cctvMap = {
      54: ['제주시', '고기장'],
      56: ['협재(금능)', '쉼표'],
      77: ['새별오름', '카페새빌'],
      53: ['함덕', '델문도'],
      55: ['애월', '애월빵공장'],
      61: ['성산', '프릳츠 제주성산점'],
      50: ['서귀포', 'UDA'],
      60: ['중문', '누바비치'],
      71: ['우도', '블랑로쉐'],
      74: ['엉또폭포', '엉또폭포'],
      48: ['신창', '클랭블루'],
      52: ['산방산', '원앤온리'],
      64: ['중산간', '미스틱3도'],
      67: ['교래', '카페말로'],
      69: ['김녕', '김녕요트투어'],
      75: ['월정리', '로바타마에하마'],
      65: ['세화', '갈매기팸'],
      73: ['중산간', '제주돈아'],
      42: ['표선', '레몬일레븐'],
      66: ['송당', '안도르, ANDOR'],
      63: ['모슬포', '인스밀'],
      70: ['동백꽃', '동백포레스트'],
    };

    // cctvMap의 키 리스트를 2개씩 그룹으로 묶음
    final List<int> selectedCctvSnList = cctvMap.keys.toList();
    final List<List<int>> groupedCctvSnList = [];
    for (var i = 0; i < selectedCctvSnList.length; i += 2) {
      groupedCctvSnList.add(selectedCctvSnList.sublist(
          i,
          i + 2 > selectedCctvSnList.length
              ? selectedCctvSnList.length
              : i + 2));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('제주국제공항 도착 정보'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 각 그룹을 ExpansionTile로 감싸기
              ...groupedCctvSnList.map((group) {
                return ExpansionTile(
                  title: _buildGroupTitle(group, cctvMap),
                  children: [
                    Wrap(
                      spacing: 5,
                      runSpacing: 10,
                      children: group.map((sn) {
                        return CustomWebViewWidget(
                          url:
                              'http://www.todayjeju.kr/weather/cctvInfo.do?cctvSn=$sn',
                          width: 400,
                          height: 500,
                          isFit: false,
                          cropRect: Rect.fromLTWH(0, 260, 600, 730),
                          disableScroll: true,
                        );
                      }).toList(),
                    ),
                  ],
                );
              }).toList(),
              SizedBox(height: 20),
              Text(
                '앱 초기 페이지입니다. 공항/항공 출도착 정보를 나타낼 예정입니다. \n\n[업데이트 예정]',
                style: AppTheme.fieldLabelTextStyle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 500),
              flightDisruptionCard("항공편 지연 및 결항 (어제)", "12 (6%)", "0 (0%)"),
              flightLiveStatusCard("현재 혼잡도", "5 min", "0.4"),
              flightDisruptionCard("항공편 지연 및 결항 (오늘)", "4 (2%)", "0 (0%)"),
              flightDisruptionCard("항공편 결항 (내일)", "0 (0%)", "-"),
            ],
          ),
        ),
      ),
    );
  }

  // 지역명과 장소명을 다른 색상으로 표시하는 함수
  Widget _buildGroupTitle(List<int> group, Map<int, List<String>> cctvMap) {
    // 원하는 스타일 설정
    TextStyle regionStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppTheme.primaryColor, // 지역명 색상
    );
    TextStyle locationStyle = TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppTheme.textHintColor);

    List<TextSpan> spans = [];
    spans.add(TextSpan(
        text: 'CCTV : ',
        style: locationStyle.copyWith(color: AppTheme.text2Color)));
    for (int i = 0; i < group.length; i++) {
      final sn = group[i];
      final region = cctvMap[sn]?[0] ?? '';
      final location = cctvMap[sn]?[1] ?? '';
      spans.add(TextSpan(text: region, style: regionStyle));
      spans.add(TextSpan(text: "($location)", style: locationStyle));
      if (i < group.length - 1) {
        spans.add(TextSpan(text: "  /  ", style: regionStyle));
      }
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget flightDisruptionCard(String title, String delayed, String canceled) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                disruptionInfo("항공편 지연", delayed),
                disruptionInfo("항공편 결항", canceled),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget flightLiveStatusCard(
      String title, String avgDelay, String disruptionIndex) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      color: Colors.orange[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'LIVE',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                disruptionInfo("Average Delay", avgDelay),
                disruptionInfo("Disruption Index", disruptionIndex),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget disruptionInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green[700]),
        ),
      ],
    );
  }
}
