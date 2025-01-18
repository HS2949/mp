import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/providers/profile/profile_provider.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileProvider>().state.user;

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text('Profile'),
          centerTitle: true,
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0), // 상단 여백 추가
            child: Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.profileImage.isNotEmpty)
                    Column(
                      children: [
                        FadeInImage.assetNetwork(
                          placeholder: 'assets/images/loading.gif',
                          image: user.profileImage,
                          width: 350,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(height: 10.0),
                      ],
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(50.0),
                      child: Text(
                        'No profile image available',
                        style:
                            AppTheme.subtitleTextStyle.copyWith(color: Colors.grey),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('- id: ${user.id}', style: AppTheme.subtitleTextStyle),
                        SizedBox(height: 10.0),
                        Text('- name: ${user.name}',
                            style: AppTheme.subtitleTextStyle),
                        SizedBox(height: 10.0),
                        Text('- position: ${user.position}',
                            style: AppTheme.subtitleTextStyle),
                        SizedBox(height: 10.0),
                        Text('- email: ${user.email}',
                            style: AppTheme.subtitleTextStyle),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
