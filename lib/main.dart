// Flutter의 Cupertino 스타일 위젯 라이브러리 임포트
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mp_db/constants/styles.dart';

import 'package:mp_db/pages/home.dart';
import 'package:mp_db/pages/planing_subpage.dart';

import 'package:mp_db/providers/Item_detail/Item_detail_provider.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:mp_db/providers/auth/auth_provider.dart';
import 'package:mp_db/providers/profile/profile_provider.dart';
import 'package:mp_db/providers/signin/signin_provider.dart';
import 'package:mp_db/providers/signup/signup_provider.dart';
import 'package:mp_db/providers/user_provider.dart';
import 'package:mp_db/repositories/Item_detail_repository.dart';
import 'package:mp_db/repositories/auth_repository.dart';
import 'package:mp_db/repositories/profile_repository.dart';

import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;

// Firebase 초기화를 위한 라이브러리 임포트
import 'package:firebase_core/firebase_core.dart';
import 'package:mp_db/pages/signin_page.dart';
import 'package:mp_db/pages/signup_page.dart';
import 'package:mp_db/pages/splash_page.dart';

// 홈 화면의 위젯이 정의된 파일 임포트

// Firebase 초기화 옵션이 정의된 파일 임포트
import 'firebase_options.dart';

// main 함수는 Flutter 앱의 진입점입니다.
void main() async {
  // Flutter의 위젯 바인딩을 초기화합니다. 비동기 작업 전에 반드시 호출해야 합니다.
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('kr', null);
  // Firebase를 초기화합니다. Firebase를 사용하려면 앱 실행 전에 반드시 초기화해야 합니다.
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform, // 플랫폼에 따라 설정된 Firebase 옵션 사용
  );
  // await FirebaseFirestore.instance.clearPersistence();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  await Hive.initFlutter();

  Hive.registerAdapter(ScheduleEntryAdapter()); // 어댑터 등록
  await Hive.openBox('scheduleBox'); // 이게 없으면 오류 발생
  
  // 앱을 실행합니다. MyApp 위젯이 루트 위젯이 됩니다.
  runApp(const MyApp());
}

// MyApp 클래스는 StatelessWidget을 상속받아 애플리케이션의 전체 구조를 정의합니다.
class MyApp extends StatelessWidget {
  // const 생성자를 사용해 MyApp 객체를 생성합니다. 불변 객체로 메모리 최적화에 유리합니다.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cupertino 스타일을 사용하는 Flutter 앱의 루트 위젯을 정의합니다.
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (context) => AuthRepository(
            firebaseFirestore: FirebaseFirestore.instance,
            firebaseAuth: fbAuth.FirebaseAuth.instance,
          ),
        ),
        StreamProvider<fbAuth.User?>(
          create: (context) => context.read<AuthRepository>().user,
          initialData: null,
        ),
        ChangeNotifierProvider(
          create: (_) => ItemProvider()..loadSnapshot(),
        ),
        Provider<ProfileRepository>(
          create: (context) => ProfileRepository(
            firebaseFirestore: FirebaseFirestore.instance,
          ),
        ),
        ChangeNotifierProvider<SigninProvider>(
          create: (context) => SigninProvider(
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<SignupProvider>(
          create: (context) => SignupProvider(
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (context) => ProfileProvider(
            profileRepository: context.read<ProfileRepository>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProxyProvider2<fbAuth.User?, ProfileProvider,
            AuthProvider>(
          create: (context) => AuthProvider(
            authRepository: context.read<AuthRepository>(),
          ),
          update: (
            BuildContext context,
            fbAuth.User? userStream,
            ProfileProvider profileProvider,
            AuthProvider? authProvider,
          ) {
            if (authProvider != null) {
              authProvider.update(userStream, profileProvider);
            }
            return authProvider!;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => ItemDetailProvider(
            itemDetailRepository: ItemDetailRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        // 앱의 제목을 정의합니다. iOS에서는 표시되지 않을 수 있습니다.

        title: '마이스플랜 MICE PLAN',
        scrollBehavior:
            CustomScrollBehavior(), // ✅ Apply global scroll behavior here
        // 앱의 테마를 설정합니다.
        theme: AppTheme.mpTheme,
        debugShowCheckedModeBanner: false,
        // 앱의 초기 화면을 설정합니다. HomeScreen 위젯이 시작 화면으로 사용됩니다.
        home: SplashPage(),
        routes: {
          SignupPage.routeName: (context) => SignupPage(),
          SigninPage.routeName: (context) => SigninPage(),
          Home.routeName: (context) => Home(),
        },
      ),
    );
  }
}
