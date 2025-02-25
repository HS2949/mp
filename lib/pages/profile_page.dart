import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
                        // FadeInImage.assetNetwork(
                        //   placeholder: 'assets/images/loading.gif',
                        //   placeholderScale: 2,
                        //   placeholderFit: BoxFit.none, // 플레이스홀더의 크기 맞춤 방식 설정
                        //   image: user.profileImage,
                        //   width: 350,
                        //   fit: BoxFit.cover,
                        // ),
                        CachedNetworkImage(
                          imageUrl: user.profileImage,
                          width: 350,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Image.asset(
                            'assets/images/loading.gif',
                            width: 50, // 너비를 100으로 고정
                            fit: BoxFit.contain, // placeholderFit 대응
                          ),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        ),
                        SizedBox(height: 10.0),
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
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('- id: ${user.id}'),
                        SizedBox(height: 10.0),
                        Text('- name: ${user.name}'),
                        SizedBox(height: 10.0),
                        Text('- position: ${user.position}'),
                        SizedBox(height: 10.0),
                        Text('- email: ${user.email}'),
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
