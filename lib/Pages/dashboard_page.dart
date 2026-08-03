import 'package:app/Components/Cards/academic_card.dart';
import 'package:app/Components/InputFields/search_input.dart';
import 'package:app/Components/Shimmers/academic_shimmer.dart';
import 'package:app/Components/Shimmers/e_learning.dart';
import 'package:app/Providers/academic_tile_provider.dart';
import 'package:app/Providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<UserProvider>().fetchUserDetails();
      context.read<AcademicTileProvider>().loadAcademicTiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final academicProvider = context.watch<AcademicTileProvider>();
    final tiles = academicProvider.academicTiles;
    final isLoading = academicProvider.isLoading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final now = DateTime.now();

        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        // Exit the app
        SystemNavigator.pop();
      },
      child: Scaffold(
        // backgroundColor: const Color.fromARGB(255, 247, 247, 247),
        // appBar: AppBar(title: const Text("Dashboard"), centerTitle: true),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hello"),
                        Text(
                          user?.fullName ?? 'User',
                          style: TextStyle(
                            fontSize: 24,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 47, 49, 61),
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.notifications_outlined,
                      weight: 100,
                      size: 30,
                      color: const Color.fromARGB(255, 47, 49, 61),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SearchInput(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        "Academics",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          letterSpacing: 1.5,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 47, 49, 61),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    // height: 300,
                    child: isLoading
                        ? academicShimmer()
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: tiles.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemBuilder: (context, index) {
                              return AcademicCard(tile: tiles[index]);
                            },
                          ),
                  ),

                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Text(
                        "E-Learning",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          letterSpacing: 1.5,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 47, 49, 61),
                        ),
                      ),
                    ],
                  ),
                  eLearningShimmer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
