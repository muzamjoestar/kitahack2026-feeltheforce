import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart'; // 1. IMPORT THIS
import 'package:camera/camera.dart';

// State Management Imports
import 'state/auth_store.dart';
import 'services/order_store.dart';
import 'services/print_store.dart';

// UI & Theme
import 'ui/uniserve_ui.dart';

// Screen Imports
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
import 'screens/express_driver_screen.dart';
import 'screens/marketplace_post_screen.dart';
import 'screens/verify_identity_screen.dart';
import 'screens/scanner_screen.dart';

// FIX: Tambah 'as market' di sini untuk mengelakkan konflik nama
import 'screens/marketplace_screen.dart' as market; 

// 2. DEFINE THE NAVIGATOR KEY GLOBALLY
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

List<CameraDescription> cameras = [];

void main() async { // 3. Make main async
  // CRITICAL: Required for Deep Links and async code in main
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Initialize Cameras BEFORE the app starts
  try {
    cameras = await availableCameras();
  } catch (e) {
    print("Camera Error: $e"); // Helpful for debugging on emulator
  }

  runApp(
    MultiProvider(
      providers: [
        // Ensure 'auth' is defined as a global variable in auth_store.dart
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: OrderStore.I),
        ChangeNotifierProvider.value(value: PrintStore.I),
      ],
      child: const UniserveApp(),
    ),
  );
}

class UniserveApp extends StatefulWidget {
  const UniserveApp({super.key});

  @override
  State<UniserveApp> createState() => _UniserveAppState();
}

class _UniserveAppState extends State<UniserveApp> {
  ThemeMode mode = ThemeMode.light;
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    // 1. Cold Start: Handle link if app was closed
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        openDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("Deep Link Error: $e");
    }

    // 2. Warm Start: Listen to links while app is running/background
    _appLinks.uriLinkStream.listen((uri) {
      openDeepLink(uri);
    });
  }

  void openDeepLink(Uri uri) {
    debugPrint("Navigating to: ${uri.path}");
    
    // Check if navigator is mounted
    if (navigatorKey.currentState != null) {
      if (uri.path == '/verify-identity') {
        navigatorKey.currentState!.pushNamed('/verify-identity');
      } else if (uri.path == '/wallet') {
        navigatorKey.currentState!.pushNamed('/wallet');
      }
      // Add other deep links here
    }
  }
  
  void toggleTheme() {
    setState(() {
      mode = (mode == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, 
      themeMode: mode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),

      // 2. REPLACE 'home: HomeScreen(...)' WITH THIS:
      home: Consumer<AuthStore>(
        builder: (context, auth, child) {
          // If logged in, go to Home. If not, force Profile (Login) screen.
          if (auth.isLoggedIn) {
            return HomeScreen(onToggleTheme: toggleTheme);
          } else {
            return const ProfileScreen();
          }
        },
      ),

      routes: {
        '/runner': (_) => const RunnerScreen(),
        '/assignment': (_) => const AssignmentScreen(),
        '/barber': (_) => const BarberScreen(),
        '/transport': (_) => const TransportScreen(),
        '/parcel': (_) => const ParcelScreen(),
        '/print': (_) => const PrintServiceScreen(),
        '/photo': (_) => const PhotoScreen(),
        '/express': (_) => const ExpressScreen(),
        
        // FIX: Panggil guna nama alias 'market'
        '/marketplace': (_) => const market.MarketplaceScreen(),
        
        '/marketplace-post': (_) => const MarketplacePostScreen(),

        '/ai': (_) => const AiScreen(),
        '/wallet': (_) => const WalletScreen(),
        '/settings': (_) => SettingsScreen(onToggleTheme: toggleTheme),
        '/profile': (_) => const ProfileScreen(),
        '/explore': (_) => const ExploreScreen(),
        '/driver-register': (_) => const DriverRegisterScreen(),
        '/verify-identity': (_) => const VerifyIdentityScreen(),
        '/express-driver': (_) => const ExpressDriverScreen(),   
        
        // Placeholder routes
        '/pc-repair': (_) => const market.MarketplaceScreen(),
        '/rental': (_) => const market.MarketplaceScreen(),

        '/scan': (_) => ScannerScreen(cameras: cameras)
      },
    );
  }
}