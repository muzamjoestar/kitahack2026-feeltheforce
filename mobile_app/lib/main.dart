// Di bahagian atas file main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/auth_store.dart';
import 'services/order_store.dart';
import 'services/print_store.dart';

import 'ui/uniserve_ui.dart';
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
import 'screens/express_driver_screen.dart';
// FIX: Tambah 'as market' di sini
import 'screens/marketplace_screen.dart' as market; 
import 'screens/marketplace_post_screen.dart';
import 'screens/verify_identity_screen.dart';

void main() {
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


class UniserveApp extends StatefulWidget {
  const UniserveApp({super.key});

  @override
  State<UniserveApp> createState() => _UniserveAppState();
}

class _UniserveAppState extends State<UniserveApp> {
  ThemeMode mode = ThemeMode.light;
  
  void toggleTheme() {
    setState(() {
      mode = (mode == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      
      // 5. ATTACH THE NAVIGATOR KEY HERE
      navigatorKey: navigatorKey, 

      themeMode: mode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),

      home: HomeScreen(onToggleTheme: toggleTheme),

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
        // Tambah laluan sementara untuk elak error jika tekan butang "More"
        '/pc-repair': (_) => const market.MarketplaceScreen(),
        '/rental': (_) => const market.MarketplaceScreen(),
      },
    );
  }
}