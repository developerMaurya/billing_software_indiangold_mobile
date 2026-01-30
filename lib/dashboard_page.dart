import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'screens/customers/customer_list_screen.dart';
import 'screens/products/product_list_screen.dart';

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

  int _selectedIndex = 0;

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
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

    final List<Widget> _pages = [
      _buildHomeView(),
      const CustomerListScreen(),
      const ProductListScreen(),
      const Placeholder(child: Center(child: Text("Profile Coming Soon"))),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      // Only show the inner AppBar (from Sliver or CustomerList)
      // Checks for index to determine if we need a safe area wrapping or not
      body: _pages[_selectedIndex],
      drawer: _buildDrawer(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.white,
          indicatorColor: Colors.green.shade100,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outlined),
              selectedIcon: Icon(Icons.people),
              label: 'Customers',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Products',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade800, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              companyData?['name'] ?? 'Admin',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(
              companyData?['email'] ?? 'admin@indiangold.com',
              style: const TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: companyData?['logo'] != null
                  ? NetworkImage(companyData!['logo'])
                  : null,
              child: companyData?['logo'] == null
                  ? Icon(Icons.store, size: 40, color: Colors.green.shade800)
                  : null,
            ),
          ),
          _drawerItem(Icons.dashboard, 'Dashboard', 0),
          _drawerItem(Icons.people, 'Customers', 1),
          _drawerItem(Icons.inventory_2, 'Products', 2),
          const Divider(),
          _drawerItem(
            Icons.sell,
            'Sell / Purchase',
            2,
          ), // Maps to Products for now as placeholder
          _drawerItem(Icons.history, 'History', 0), // Placeholder
          _drawerItem(Icons.category, 'Inventory', 0), // Placeholder
          const Divider(),
          _drawerItem(Icons.settings, 'Settings', 3), // Maps to Profile for now
          _drawerItem(Icons.person, 'Profile', 3),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  ListTile _drawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(
        icon,
        color: _selectedIndex == index
            ? Colors.green.shade700
            : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index
              ? Colors.green.shade700
              : Colors.black87,
          fontWeight: _selectedIndex == index
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.green.shade50,
      onTap: () {
        Navigator.pop(context); // Close drawer
        _onItemTapped(index);
      },
    );
  }

  Widget _buildHomeView() {
    return CustomScrollView(
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
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {}, // Notification placeholder
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
            border: Border.all(color: Colors.green.shade100),
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
            if (label == 'Patients') {
              // Reusing Patients as Customers for this context if needed
              _onItemTapped(1); // Switch to Customer tab
              return;
            }
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
