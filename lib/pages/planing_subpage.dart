import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'planing_subpage.g.dart'; // build_runner로 생성되는 어댑터 파일

@HiveType(typeId: 0)
class ScheduleEntry extends HiveObject {
  @HiveField(0)
  String time;
  
  @HiveField(1)
  String message;
  
  @HiveField(2)
  String place;
  
  @HiveField(3)
  String note;

  ScheduleEntry({
    required this.time,
    required this.message,
    required this.place,
    required this.note,
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ScheduleEntryAdapter());
  // 'scheduleBox'는 모든 일정 데이터를 저장하는 박스입니다.
  await Hive.openBox('scheduleBox');
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '일정 작성',
      home: PlaningSubpage(),
    );
  }
}

class PlaningSubpage extends StatefulWidget {
  const PlaningSubpage({Key? key}) : super(key: key);

  @override
  State<PlaningSubpage> createState() => _PlaningSubpageState();
}

class _PlaningSubpageState extends State<PlaningSubpage> {
  final Box scheduleBox = Hive.box('scheduleBox');

  final TextEditingController timeController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final TextEditingController placeController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  @override
  void dispose() {
    timeController.dispose();
    messageController.dispose();
    placeController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void _addScheduleEntry() {
    if (timeController.text.isEmpty &&
        messageController.text.isEmpty &&
        placeController.text.isEmpty &&
        noteController.text.isEmpty) {
      return;
    }
    final entry = ScheduleEntry(
      time: timeController.text,
      message: messageController.text,
      place: placeController.text,
      note: noteController.text,
    );
    // 기존에 저장된 리스트를 가져오거나, 없으면 빈 리스트 생성
    List<ScheduleEntry> entries = scheduleBox.get('entries', defaultValue: <ScheduleEntry>[])!.cast<ScheduleEntry>();
    entries.add(entry);
    scheduleBox.put('entries', entries);

    // 입력필드 초기화
    timeController.clear();
    messageController.clear();
    placeController.clear();
    noteController.clear();
    setState(() {});
  }

  void _deleteEntry(int index, List<ScheduleEntry> entries) {
    entries.removeAt(index);
    scheduleBox.put('entries', entries);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('일정 작성', style: AppTheme.fieldLabelTextStyle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 일정 입력 폼
            TextField(
              controller: timeController,
              decoration: InputDecoration(labelText: '시간'),
            ),
            TextField(
              controller: messageController,
              decoration: InputDecoration(labelText: '안내문구'),
            ),
            TextField(
              controller: placeController,
              decoration: InputDecoration(labelText: '장소'),
            ),
            TextField(
              controller: noteController,
              decoration: InputDecoration(labelText: '비고'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _addScheduleEntry,
              child: const Text('일정 추가'),
            ),
            const SizedBox(height: 24),
            // 일정 리스트 표시
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: scheduleBox.listenable(keys: ['entries']),
                builder: (context, Box box, _) {
                  List<ScheduleEntry> entries = box.get('entries', defaultValue: <ScheduleEntry>[])!.cast<ScheduleEntry>();
                  if (entries.isEmpty) {
                    return Center(child: Text('추가된 일정이 없습니다.', style: AppTheme.fieldLabelTextStyle));
                  }
                  return ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text('${entry.time} - ${entry.message}', style: AppTheme.fieldLabelTextStyle),
                          subtitle: Text('장소: ${entry.place}\n비고: ${entry.note}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteEntry(index, entries),
                          ),
                        ),
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
}
