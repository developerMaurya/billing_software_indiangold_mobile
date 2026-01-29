import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  final String? uid;
  const DashboardPage({super.key, this.uid});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? companyData;
  bool isLoading = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchCompanyData();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchCompanyData() async {
    String? targetUid = widget.uid ?? user?.uid;

    if (targetUid != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('shops')
            .doc(targetUid)
            .get();

        if (doc.exists) {
          setState(() {
            companyData = doc.data() as Map<String, dynamic>;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } catch (e) {
        debugPrint("Error fetching data: $e");
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // main.dart StreamBuilder handles the rest
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade50, Colors.white],
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (companyData != null) ...[
                      _buildWelcomeSection(),
                      const SizedBox(height: 25),
                      _buildBanners(),
                      const SizedBox(height: 25),
                      _buildCompanyInfoCard(),
                      const SizedBox(height: 25),
                      const Text(
                        "Quick Actions",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildActionGrid(),
                    ] else
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 60,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "No Shop details found. Please register properly.",
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: true,
      pinned: true,
      backgroundColor: Colors.green.shade700,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          companyData?['name'] ?? 'Dashboard',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green.shade800, Colors.green.shade600],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          onPressed: _logout,
          tooltip: 'Logout',
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.green.shade100,
          backgroundImage: companyData!['logo'] != null
              ? NetworkImage(companyData!['logo'])
              : null,
          child: companyData!['logo'] == null
              ? Icon(Icons.store, size: 30, color: Colors.green.shade800)
              : null,
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome back,",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              companyData!['name'] ?? 'Admin',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBanners() {
    if (companyData!['banners'] == null ||
        (companyData!['banners'] as List).isEmpty) {
      return const SizedBox.shrink();
    }

    final List banners = companyData!['banners'];

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: banners.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 15),
            width: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              image: DecorationImage(
                image: NetworkImage(banners[index]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompanyInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(
            Icons.location_on_outlined,
            companyData?['address'] ?? 'No Address',
          ),
          const Divider(height: 30),
          _infoRow(Icons.phone_outlined, companyData?['mobile'] ?? 'No Mobile'),
          const Divider(height: 30),
          _infoRow(Icons.email_outlined, companyData?['email'] ?? 'No Email'),
          const Divider(height: 30),
          _infoRow(
            Icons.confirmation_number_outlined,
            "GST: ${companyData?['gst'] ?? 'N/A'}",
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.green.shade700, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid() {
    final actions = [
      {'icon': Icons.point_of_sale, 'label': 'Billing', 'color': Colors.blue},
      {
        'icon': Icons.inventory_2_outlined,
        'label': 'Inventory',
        'color': Colors.orange,
      },
      {
        'icon': Icons.people_outline,
        'label': 'Patients',
        'color': Colors.purple,
      },
      {
        'icon': Icons.assessment_outlined,
        'label': 'Reports',
        'color': Colors.red,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        return _buildActionCard(
          actions[index]['icon'] as IconData,
          actions[index]['label'] as String,
          actions[index]['color'] as Color,
        );
      },
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Placeholder for action
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$label Feature Coming Soon!")),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
