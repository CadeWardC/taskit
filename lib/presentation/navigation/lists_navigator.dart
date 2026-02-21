import 'package:flutter/material.dart';
import '../screens/lists_screen.dart';

class ListsNavigator extends StatelessWidget {
  const ListsNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (BuildContext context) {
            // Basic route handling
            // Since we push ListDetailScreen manually from ListsScreen, 
            // we only need to define the root here.
            return const ListsScreen();
          },
        );
      },
    );
  }
}
