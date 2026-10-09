import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';
import 'theme/detective_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = DetectiveSettings();
  await settings.load();
  final audio = DetectiveAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(LogicGridApp(settings: settings, audio: audio));
}

class LogicGridApp extends StatefulWidget {
  final DetectiveSettings settings;
  final DetectiveAudio audio;
  const LogicGridApp({super.key, required this.settings, required this.audio});

  @override
  State<LogicGridApp> createState() => _LogicGridAppState();
}

class _LogicGridAppState extends State<LogicGridApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their engines.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Logic Grid',
        debugShowCheckedModeBanner: false,
        theme: Desk.material(widget.settings.theme),
        home: SplashScreen(audio: widget.audio, settings: widget.settings),
      ),
    );
  }
}
