import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_upload/bloc/upload_bloc/upload_bloc.dart';
import 'package:video_upload/bloc/video_list_bloc/video_list_bloc.dart';
import 'package:video_upload/repositories/video_repository.dart';
import 'package:video_upload/screen/home_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UploadBloc>(
          create: (context) => UploadBloc(videoRepository: VideoRepository()),
        ),
        BlocProvider<VideoListBloc>(
          create: (context) => VideoListBloc(videoRepository: VideoRepository()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false, 
        home: const HomeScreen(),
        navigatorObservers: [routeObserver],
      ),
    );
  }
}