import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart'; // 1. IMPORT THIS

import 'screens/home_screen.dart';
import 'screens/transport_screen.dart';
import 'screens/runner_screen.dart';
import 'screens/assignment_screen.dart';
import 'screens/barber_screen.dart';
import 'screens/parcel_screen.dart';
import 'screens/print_screen.dart';
import 'screens/photo_screen.dart';
import 'screens/express_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/driver_register_screen.dart';
import 'screens/marketplace_screen.dart';

// 2. CREATE A GLOBAL KEY (This lets us navigate without a context)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UniserveApp());
}

class UniserveApp extends StatefulWidget {
  const UniserveApp({super.key});

  @override
  State<UniserveApp> createState() => _UniserveAppState();
}

class _UniserveAppState extends State<UniserveApp> {
  ThemeMode mode = ThemeMode.dark;
  late AppLinks _appLinks; // 3. DECLARE APP LINKS

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  // 4. THE DEEP LINK LOGIC
  void _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle links when app is in background or opened completely
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        print("Deep link found: ${uri.path}");
        
        // This acts as a "Router". If the link is "uniserve://runner", 
        // the path is "/runner", which matches your route names!
        navigatorKey.currentState?.pushNamed(uri.path); 
      }
    }, onError: (err) {
      print("Deep link error: $err");
    });
  }

  void toggleTheme() {
    setState(() {
      mode = (mode == ThemeMode.dark)
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      
      // 5. ATTACH THE NAVIGATOR KEY HERE
      navigatorKey: navigatorKey, 

      themeMode: mode,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),

      home: HomeScreen(onToggleTheme: toggleTheme),

      routes: {
        '/runner': (_) => const RunnerScreen(),
        '/assignment': (_) => const AssignmentScreen(),
        '/barber': (_) => const BarberScreen(),
        '/transport': (_) => const TransportScreen(),
        '/parcel': (_) => const ParcelScreen(),
        '/print': (_) => const PrintScreen(),
        '/photo': (_) => const PhotoScreen(),
        '/express': (_) => const ExpressScreen(),
        '/marketplace': (_) => const MarketplaceScreen(),

        '/ai': (_) => const AiScreen(),
        '/wallet': (_) => const WalletScreen(),
        '/settings': (_) => SettingsScreen(onToggleTheme: toggleTheme),
        '/profile': (_) => const ProfileScreen(),
        '/explore': (_) => const ExploreScreen(),
        '/driver-register': (_) => const DriverRegisterScreen(),
      },
    );
  }
}