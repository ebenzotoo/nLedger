import 'package:flutter/material.dart';
import 'package:nledger/features/dashboard/views/main_dashboard.dart';
import 'package:nledger/features/invoices/controllers/invoice_provider.dart';
import 'package:nledger/features/settings/controllers/business_profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';

import 'features/clients/controllers/client_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      ],
      child: MaterialApp(
        title: 'PEN Network Billing',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: MainDashboard(),
      ),
    );
  }
}
