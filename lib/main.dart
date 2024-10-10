import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'sign_up_page.dart'; // Import cho trang đăng ký
import 'realtimedatabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      //Theo dõi trạng thái đăng nhập của người dùng
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final User? user = snapshot.data;
            // Nếu người dùng chưa đăng nhập, hiển thị trang đăng nhập
            if (user == null) {
              return LoginPage();
            }
            return const RealtimeDatabase();
          }
          // Hiển thị vòng tròn tải khi đang kiểm tra trạng thái đăng nhập
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
