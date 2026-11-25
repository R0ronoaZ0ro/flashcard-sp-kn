import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/tts_service.dart';
import 'providers/flashcard_provider.dart';
import 'screens/group_menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const FlashcardApp(),
  );
}

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return ChangeNotifierProvider(
      create: (_) =>
          FlashcardProvider(),
      child: const FlashcardRoot(),
    );
  }
}

class FlashcardRoot
    extends StatefulWidget {
  const FlashcardRoot({
    super.key,
  });

  @override
  State<FlashcardRoot> createState() =>
      _FlashcardRootState();
}

class _FlashcardRootState
    extends State<FlashcardRoot> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback(
          (_) async {
        final provider =
        context.read<FlashcardProvider>();

        await provider.initialize();

        // Inicializa TTS una sola vez
        // para evitar latencia en la
        // primera reproducción.
        await TtsService.instance.initialize();
      },
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return MaterialApp(
      debugShowCheckedModeBanner:
      false,

      title: 'FlashCard SP-KN',

      theme:
      _buildLightTheme(),

      darkTheme:
      _buildDarkTheme(),

      themeMode:
      ThemeMode.system,

      home:
      const GroupMenuScreen(),
    );
  }

  // ============================================================
  // TEMA CLARO
  // ============================================================

  ThemeData _buildLightTheme() {
    const primaryColor =
    Color(0xFF6C63FF);

    const backgroundColor =
    Color(0xFFF5F7FB);

    return ThemeData(
      useMaterial3: true,

      brightness:
      Brightness.light,

      colorScheme:
      ColorScheme.fromSeed(
        seedColor:
        primaryColor,
        brightness:
        Brightness.light,
      ),

      scaffoldBackgroundColor:
      backgroundColor,

      fontFamily:
      'Roboto',

      appBarTheme:
      const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation:
        0,
        backgroundColor:
        backgroundColor,
        foregroundColor:
        Color(0xFF171927),
      ),

      cardTheme:
      CardThemeData(
        elevation: 0,
        color:
        Colors.white,
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            20,
          ),
        ),
      ),

      inputDecorationTheme:
      InputDecorationTheme(
        filled: true,
        fillColor:
        Colors.white,
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          borderSide:
          BorderSide.none,
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          borderSide:
          BorderSide.none,
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          borderSide:
          const BorderSide(
            color:
            primaryColor,
            width: 2,
          ),
        ),
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),

      filledButtonTheme:
      FilledButtonThemeData(
        style:
        FilledButton.styleFrom(
          minimumSize:
          const Size(
            0,
            52,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              16,
            ),
          ),
        ),
      ),

      textButtonTheme:
      TextButtonThemeData(
        style:
        TextButton.styleFrom(
          minimumSize:
          const Size(
            0,
            48,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              14,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TEMA OSCURO
  // ============================================================

  ThemeData _buildDarkTheme() {
    const primaryColor =
    Color(0xFF8B83FF);

    const backgroundColor =
    Color(0xFF0D0F17);

    const surfaceColor =
    Color(0xFF171A25);

    return ThemeData(
      useMaterial3: true,

      brightness:
      Brightness.dark,

      colorScheme:
      ColorScheme.fromSeed(
        seedColor:
        primaryColor,
        brightness:
        Brightness.dark,
      ),

      scaffoldBackgroundColor:
      backgroundColor,

      fontFamily:
      'Roboto',

      appBarTheme:
      const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation:
        0,
        backgroundColor:
        backgroundColor,
        foregroundColor:
        Colors.white,
      ),

      cardTheme:
      CardThemeData(
        elevation: 0,
        color:
        surfaceColor,
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            20,
          ),
        ),
      ),

      inputDecorationTheme:
      InputDecorationTheme(
        filled: true,
        fillColor:
        surfaceColor,
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          borderSide:
          BorderSide.none,
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          borderSide:
          BorderSide.none,
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          borderSide:
          const BorderSide(
            color:
            primaryColor,
            width: 2,
          ),
        ),
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),

      filledButtonTheme:
      FilledButtonThemeData(
        style:
        FilledButton.styleFrom(
          minimumSize:
          const Size(
            0,
            52,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              16,
            ),
          ),
        ),
      ),

      textButtonTheme:
      TextButtonThemeData(
        style:
        TextButton.styleFrom(
          minimumSize:
          const Size(
            0,
            48,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              14,
            ),
          ),
        ),
      ),
    );
  }
}