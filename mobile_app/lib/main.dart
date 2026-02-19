import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart'; 
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart'; // From your branch
import 'firebase_options.dart'; // From your branch
import 'package:flutter_dotenv/flutter_dotenv.dart'; // From your branch

// State Management Imports
import 'state/auth_store.dart';
import 'services/order_store.dart';
import 'services/print_store.dart';

// UI & Theme
import 'ui/uniserve_ui.dart';

// Screen Imports
import 'screens/login_screen.dart'; // From your branch
import 'screens/register_screen.dart'; // From your branch
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
import 'screens/privacy_policy_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/marketplace_screen.dart' as market;

// 2. DEFINE THE NAVIGATOR KEY GLOBALLY
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

List<CameraDescription> cameras = [];

void main() async {
  // CRITICAL: Required for Firebase, Camera, and Deep Links
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Your Contribution)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize DotEnv (Your Contribution)
  await dotenv.load(fileName: ".env");

  // Initialize Cameras (Main Branch Contribution)
  try {
    cameras = await availableCameras();
  } catch (e) {
    print("Camera Error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
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
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        openDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("Deep Link Error: $e");
    }
    _appLinks.uriLinkStream.listen((uri) {
      openDeepLink(uri);
    });
  }

  void openDeepLink(Uri uri) {
    if (navigatorKey.currentState != null) {
      if (uri.path == '/verify-identity') {
        navigatorKey.currentState!.pushNamed('/verify-identity');
      } else if (uri.path == '/wallet') {
        navigatorKey.currentState!.pushNamed('/wallet');
      }
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
      
      // Use your LoginScreen as the entry point
      home: const LoginScreen(), 

      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => RegisterScreen(),
        '/home': (_) => HomeScreen(onToggleTheme: toggleTheme),
        '/runner': (_) => const RunnerScreen(),
        '/assignment': (_) => const AssignmentScreen(),
        '/barber': (_) => const BarberScreen(),
        '/transport': (_) => const TransportScreen(),
        '/parcel': (_) => const ParcelScreen(),
        '/print': (_) => const PrintServiceScreen(),
        '/photo': (_) => const PhotoScreen(),
        '/express': (_) => const ExpressScreen(),
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
        '/privacy-policy': (_) => const PrivacyPolicyScreen(),
        '/edit-profile': (_) => const EditProfileScreen(),
        '/pc-repair': (_) => const market.MarketplaceScreen(),
        '/rental': (_) => const market.MarketplaceScreen(),
        '/scan': (_) => ScannerScreen(cameras: cameras)
      },
    );
  }
}
