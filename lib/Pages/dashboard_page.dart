import 'package:flutter/material.dart';
import 'package:app/Services/api_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Future<Map<String, dynamic>>? _userFuture;

  final ApiService api = ApiService();

  void fetchUserDetails() {
    setState(() {
      _userFuture = api.getUserDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: fetchUserDetails,
                child: const Text(
                  "Fetch User Details",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _userFuture,
                builder: (context, snapshot) {

                  if (_userFuture == null) {
                    return const Center(
                      child: Text(
                        "Press the button to load your details",
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error: ${snapshot.error}",
                      ),
                    );
                  }

                  final user = snapshot.data!;

                  return Card(
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          const Icon(
                            Icons.person,
                            size: 60,
                          ),

                          const SizedBox(height: 20),

                          Text(
                            "Name: ${user['id']}",
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "Email: ${user['email']}",
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "ID: ${user['id']}",
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}