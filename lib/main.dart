import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nledger/features/invoices/controllers/invoice_provider.dart';
import 'package:nledger/features/renewals/controllers/renewal_provider.dart';
import 'package:nledger/features/settings/controllers/business_profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/controllers/auth_provider.dart';
import 'features/auth/views/splash_screen.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';

import 'features/clients/controllers/client_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const PenNetworkApp());
}

class PenNetworkApp extends StatelessWidget {
  const PenNetworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => BusinessProfileProvider()),
        ChangeNotifierProvider(create: (_) => RenewalProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'PEN Network Billing',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
