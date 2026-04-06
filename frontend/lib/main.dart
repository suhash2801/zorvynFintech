import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/transactions/presentation/transaction_list_screen.dart';
// Import your notification service
import 'core/notification_service.dart'; 

// This keeps track of whether we are in light or dark mode
final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

void main() async {
  // --- 1. ASYNC INITIALIZATION ---
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create a ProviderContainer to access providers before runApp
  final container = ProviderContainer();

  try {
    // Initialize Notification Service
    await container.read(notificationServiceProvider).initNotification();
    debugPrint("Notification Service Initialized Successfully");
  } catch (e) {
    debugPrint("Notification Initialization Failed: $e");
  }

  runApp(
    // Use UncontrolledProviderScope to pass our pre-initialized container
    UncontrolledProviderScope(
      container: container,
      child: const FinanceApp(),
    ),
  );
}

class FinanceApp extends ConsumerWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'FEM Finance Tracker',
      debugShowCheckedModeBanner: false,
      
      // LINK THE THEME MODE
      themeMode: themeMode,

      // --- ADD RUPEE & INDIAN LOCALE SUPPORT ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'IN'), // English (India)
      ],
      locale: const Locale('en', 'IN'), 

      // LIGHT THEME DEFINITION
      theme: ThemeData(
        useMaterial3: true, 
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // DARK THEME DEFINITION
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Pages for BottomNavigationBar
  final List<Widget> _pages = [
    const DashboardScreen(),       
    const TransactionListScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Transactions',
          ),
        ],
      ),
    );
  }
}