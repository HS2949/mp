import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';

class HomeSubpage extends StatefulWidget {
  const HomeSubpage({super.key});

  @override
  State<HomeSubpage> createState() => _HomeSubpageState();
}

class _HomeSubpageState extends State<HomeSubpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('제주국제공항 도착 정보'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 100),
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
