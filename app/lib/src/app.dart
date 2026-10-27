import 'package:flutter/material.dart';

/// The app's title, shown in the app bar and the Android task switcher.
const appTitle = 'yft android utils';

/// The root widget.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

/// The first screen.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appTitle)),
      body: Center(
        child: Text(
          'Hello, world!',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
