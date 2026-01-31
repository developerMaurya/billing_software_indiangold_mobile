import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'main.dart';
import 'screens/customers/customer_list_screen.dart';
import 'screens/products/product_list_screen.dart';
import 'screens/sales/sales_screen.dart';
import 'screens/profile_page.dart';
import 'screens/sales/sales_history_page.dart';
import 'screens/inventory_page.dart';
import 'screens/reports_page.dart';
import 'package:provider/provider.dart';
import 'utils/app_theme_provider.dart';

class DashboardPage extends StatefulWidget {
  final String? uid;
  const DashboardPage({super.key, this.uid});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  User? user = FirebaseAuth.instance.currentUser;
  String? get currentUid => widget.uid ?? user?.uid;
  late Stream<DocumentSnapshot> _shopStream;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Stats
  double totalSales = 0;
  double totalInvestment = 0;
  int totalProducts = 0;
  int totalCustomers = 0;
  int lowStockCount = 0;
  int outOfStockCount = 0;
  String topSellingProduct = 'None';

  // Chart Data
  List<FlSpot> salesTrend = [];
  Map<String, double> categoryStock = {};

  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  final List<String> _bannerImages = [
    'assets/images/banner1.jpg',
    'assets/images/banner2.jpg',
    'assets/images/banner3.jpg',
  ];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _shopStream = FirebaseFirestore.instance
        .collection('shops')
        .doc(currentUid)
        .snapshots();

    _fetchStats();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    if (mounted) _controller.forward();

    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentBannerIndex < _bannerImages.length - 1) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  // _fetchCompanyData is removed as we use StreamBuilder now

  Future<void> _fetchStats() async {
    // Stats fetching logic remains same...
    // Only visual components need theme updates
    String? targetUid = currentUid;
    if (targetUid == null) return;
    try {
      QuerySnapshot productsDocs = await FirebaseFirestore.instance
          .collection('products')
          .get();
      int pCount = productsDocs.size;
      int lStock = 0;
      int oStock = 0;
      double investment = 0;
      Map<String, double> catStock = {};

      for (var doc in productsDocs.docs) {
        var data = doc.data() as Map<String, dynamic>;
        int qty = (data['quantity'] ?? 0) as int;
        double buyRate = (data['buyRate'] ?? 0.0).toDouble();
        investment += (qty * buyRate);
        if (qty == 0)
          oStock++;
        else if (qty < 10)
          lStock++;
        String cat = data['category'] ?? 'Other';
        catStock[cat] = (catStock[cat] ?? 0) + 1;
      }

      final customersDocs = await FirebaseFirestore.instance
          .collection('customers')
          .get();
      int cCount = customersDocs.size;

      final salesDocs = await FirebaseFirestore.instance
          .collection('sales')
          .orderBy('saleDate')
          .get();
      double tSales = 0;
      List<FlSpot> trend = [];
      Map<String, int> productSalesCount = {};
      Map<int, double> dailySales = {};

      for (var doc in salesDocs.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double amount = (data['totalAmount'] ?? 0.0).toDouble();
        tSales += amount;

        if (data['items'] != null) {
          List items = data['items'];
          for (var item in items) {
            String pName = item['productName'] ?? 'Unknown';
            int q = (item['quantity'] ?? 0) as int;
            productSalesCount[pName] = (productSalesCount[pName] ?? 0) + q;
          }
        }
        DateTime date = DateTime.fromMillisecondsSinceEpoch(data['saleDate']);
        int dayKey = date
            .difference(DateTime.now().subtract(const Duration(days: 30)))
            .inDays;
        if (dayKey >= 0)
          dailySales[dayKey] = (dailySales[dayKey] ?? 0) + amount;
      }

      String topProduct = 'None';
      int maxSold = 0;
      productSalesCount.forEach((key, value) {
        if (value > maxSold) {
          maxSold = value;
          topProduct = key;
        }
      });

      dailySales.forEach(
        (key, value) => trend.add(FlSpot(key.toDouble(), value)),
      );
      trend.sort((a, b) => a.x.compareTo(b.x));

      if (mounted) {
        setState(() {
          totalProducts = pCount;
          lowStockCount = lStock;
          outOfStockCount = oStock;
          totalInvestment = investment;
          categoryStock = catStock;
          totalCustomers = cCount;
          totalSales = tSales;
          salesTrend = trend.length < 2
              ? List.generate(
                  7,
                  (i) => FlSpot(
                    i.toDouble(),
                    (i % 2 == 0 ? 3000 : 5000) + (i * 500).toDouble(),
                  ),
                )
              : trend;
          topSellingProduct = topProduct;
        });
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
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
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Theme Provider Access
    final appTheme = Provider.of<AppTheme>(context);

    // 2. StreamBuilder for Real-Time Data
    return StreamBuilder<DocumentSnapshot>(
      stream: _shopStream,
      builder: (context, snapshot) {
        // Handle Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: appTheme.colors.primary),
            ),
          );
        }

        // Handle Data
        Map<String, dynamic>? companyData;
        if (snapshot.hasData && snapshot.data!.exists) {
          companyData = snapshot.data!.data() as Map<String, dynamic>;
        }

        final List<Widget> _pages = [
          _buildHomeView(companyData, appTheme),
          const CustomerListScreen(),
          const ProductListScreen(),
          SalesScreen(uid: currentUid, companyData: companyData),
        ];

        return Scaffold(
          backgroundColor: appTheme.colors.background,

          body: _pages[_selectedIndex],

          // Drawer with real-time data & theme
          drawer: _buildDrawer(companyData, appTheme),

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
              backgroundColor: appTheme.colors.cardColor,
              indicatorColor: appTheme.colors.primary.withOpacity(0.2),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(
                    Icons.dashboard,
                    color: appTheme.colors.primary,
                  ),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.people_outlined),
                  selectedIcon: Icon(
                    Icons.people,
                    color: appTheme.colors.primary,
                  ),
                  label: 'Customers',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(
                    Icons.inventory_2,
                    color: appTheme.colors.primary,
                  ),
                  label: 'Products',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.sell_outlined),
                  selectedIcon: Icon(
                    Icons.sell,
                    color: appTheme.colors.primary,
                  ),
                  label: 'Sales',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(Map<String, dynamic>? companyData, AppTheme appTheme) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [appTheme.colors.secondary, appTheme.colors.primary],
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
              backgroundImage:
                  companyData?['logo'] != null &&
                      companyData!['logo'].toString().isNotEmpty
                  ? NetworkImage(companyData!['logo'])
                  : null,
              child:
                  (companyData?['logo'] == null ||
                      companyData!['logo'].toString().isEmpty)
                  ? Icon(Icons.store, size: 40, color: appTheme.colors.primary)
                  : null,
            ),
          ),
          _drawerItem(
            Icons.dashboard,
            'Dashboard',
            () => _onItemTapped(0),
            appTheme,
          ),
          _drawerItem(
            Icons.people,
            'Customers',
            () => _onItemTapped(1),
            appTheme,
          ),
          _drawerItem(
            Icons.inventory_2,
            'Products',
            () => _onItemTapped(2),
            appTheme,
          ),
          _drawerItem(Icons.sell, 'Sales', () => _onItemTapped(3), appTheme),
          const Divider(),
          _drawerItem(
            Icons.history,
            'History',
            () => _navigateToPage(const SalesHistoryPage()),
            appTheme,
          ),
          _drawerItem(
            Icons.category,
            'Inventory',
            () => _navigateToPage(const InventoryPage()),
            appTheme,
          ),
          const Divider(),
          _drawerItem(
            Icons.settings,
            'Settings',
            () => _showSettings(appTheme),
            appTheme,
          ),
          _drawerItem(Icons.person, 'Profile', () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(uid: currentUid),
              ),
            );
            // No need to manually fetch, Stream handles it
          }, appTheme),
          _drawerItem(
            Icons.analytics,
            'Reports',
            () => _navigateToPage(const ReportsPage()),
            appTheme,
          ),
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

  ListTile _drawerItem(
    IconData icon,
    String title,
    VoidCallback onTap,
    AppTheme appTheme,
  ) {
    return ListTile(
      leading: Icon(icon, color: appTheme.colors.textColor.withOpacity(0.7)),
      title: Text(
        title,
        style: TextStyle(
          color: appTheme.colors.textColor,
          fontWeight: FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        onTap();
      },
    );
  }

  void _navigateToPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _showSettings(AppTheme appTheme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customize Appearance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: appTheme.colors.headingColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Select a color theme to personalize your dashboard.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 25),

              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.start,
                children: appTheme.availableThemes.map((themeName) {
                  bool isSelected = appTheme.currentTheme == themeName;
                  Color themeColor = _getThemeColorPreview(themeName);

                  return GestureDetector(
                    onTap: () {
                      appTheme.setTheme(themeName);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: themeColor,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: appTheme.colors.headingColor,
                                    width: 3,
                                  )
                                : Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                            boxShadow: [
                              BoxShadow(
                                color: themeColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          themeName,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? themeColor
                                : Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Color _getThemeColorPreview(String name) {
    switch (name) {
      case 'Green':
        return Colors.green;
      case 'Blue':
        return Colors.blue;
      case 'Sky':
        return Colors.lightBlue;
      case 'Warm':
        return Colors.orange;
      case 'Brown':
        return Colors.brown;
      case 'Black':
        return Colors.black87;
      case 'White':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHomeView(Map<String, dynamic>? companyData, AppTheme appTheme) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(companyData, appTheme),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (companyData != null) ...[
                    _buildWelcomeSection(companyData, appTheme),
                    const SizedBox(height: 20),
                    _buildBannerSection(appTheme),
                    const SizedBox(height: 25),
                    _buildStatsCards(appTheme),
                    const SizedBox(height: 25),
                    _buildChartsSection(appTheme),
                  ] else
                    const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 60,
                            color: Colors.orange,
                          ),
                          SizedBox(height: 10),
                          Text(
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

  SliverAppBar _buildSliverAppBar(
    Map<String, dynamic>? companyData,
    AppTheme appTheme,
  ) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: true,
      pinned: true,
      backgroundColor: appTheme.colors.primary,
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
              colors: [appTheme.colors.secondary, appTheme.colors.primary],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(
    Map<String, dynamic> companyData,
    AppTheme appTheme,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: appTheme.colors.primary.withOpacity(0.1),
          backgroundImage:
              companyData['logo'] != null &&
                  companyData['logo'].toString().isNotEmpty
              ? (companyData['logo'].startsWith('http')
                    ? NetworkImage(companyData['logo'])
                    : FileImage(File(companyData['logo'])) as ImageProvider)
              : null,
          child:
              (companyData['logo'] == null ||
                  companyData['logo'].toString().isEmpty)
              ? Icon(Icons.store, size: 30, color: appTheme.colors.primary)
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
              companyData['name'] ?? 'Admin',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: appTheme.colors.headingColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards(AppTheme appTheme) {
    return Column(
      children: [
        // Primary Stats
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Revenue',
                '₹${NumberFormat.compact().format(totalSales)}',
                Icons.currency_rupee,
                appTheme.colors.primary, // Theme color
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'Profit',
                '₹${NumberFormat.compact().format(totalSales * 0.2)}',
                Icons.trending_up,
                Colors.blue, // Keep distinct or mix
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Investment',
                '₹${NumberFormat.compact().format(totalInvestment)}',
                Icons.account_balance_wallet,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'Customers',
                '$totalCustomers',
                Icons.people,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Inventory Health
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _miniStatCard('Total Items', '$totalProducts', Colors.blueGrey),
              const SizedBox(width: 10),
              _miniStatCard('Low Stock', '$lowStockCount', Colors.orangeAccent),
              const SizedBox(width: 10),
              _miniStatCard(
                'Out of Stock',
                '$outOfStockCount',
                Colors.redAccent,
              ),
              const SizedBox(width: 10),
              _miniStatCard('Top Product', topSellingProduct, Colors.teal),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniStatCard(String title, String value, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(AppTheme appTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Analytics",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),

        // Horizontal Scroll for Charts
        SizedBox(
          height: 320,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              // Chart 1: Sales Trend (Line Chart)
              _chartContainer(
                title: 'Live Sales Analytics',
                child: salesTrend.isEmpty
                    ? const Center(child: Text("No Data"))
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 1000,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withOpacity(0.1),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    NumberFormat.compact().format(value),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  // Show label every few days to avoid crowding
                                  if (value.toInt() % 5 == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Day ${value.toInt() + 1}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (touchedSpot) =>
                                  Colors.blueGrey.shade900,
                              tooltipPadding: const EdgeInsets.all(8),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    'Day ${spot.x.toInt() + 1}\n₹${spot.y.toStringAsFixed(0)}',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: salesTrend,
                              isCurved: true,
                              color: appTheme.colors.primary, // Dynamic Color
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: appTheme.colors.primary.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(width: 15),

              // Chart 2: Customer Gauge (Speedometer)
              _chartContainer(
                title: 'Total Customers',
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        startDegreeOffset: 180,
                        pieTouchData: PieTouchData(enabled: false),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 0,
                        centerSpaceRadius: 60,
                        sections: [
                          // Active Customers
                          PieChartSectionData(
                            color: Colors.green, // Fixed semantic color
                            value: totalCustomers.toDouble(),
                            title: '',
                            radius: 20,
                          ),
                          // Remaining
                          PieChartSectionData(
                            color: Colors.grey.shade200,
                            value:
                                (totalCustomers < 100
                                    ? 100
                                    : (totalCustomers < 1000 ? 1000 : 5000)) -
                                totalCustomers.toDouble(),
                            title: '',
                            radius: 20,
                          ),
                          // Invisible section
                          PieChartSectionData(
                            color: Colors.transparent,
                            value:
                                (totalCustomers < 100
                                        ? 100
                                        : (totalCustomers < 1000 ? 1000 : 5000))
                                    .toDouble(),
                            title: '',
                            radius: 20,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.speed, size: 30, color: Colors.green),
                        const SizedBox(height: 5),
                        Text(
                          '$totalCustomers',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Text(
                          "Registered",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),

              // Chart 3: Product Categories
              _chartContainer(
                title: 'Product Categories',
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            int index = val.toInt();
                            List<String> keys = categoryStock.keys.toList();
                            while (keys.length < 5) {
                              keys.add("Slot ${keys.length + 1}");
                            }
                            if (index < 5) {
                              String label = keys[index];
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  label.length > 4
                                      ? label.substring(0, 4)
                                      : label,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(5, (index) {
                      List<String> keys = categoryStock.keys.toList();
                      double value = 0;
                      if (index < keys.length) {
                        value = categoryStock[keys[index]] ?? 0;
                      }

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: value,
                            color: value > 0
                                ? appTheme.colors.primary.withOpacity(0.8)
                                : Colors.grey.shade200, // Dynamic Color
                            width: 16,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 10,
                              color: Colors.grey.shade50,
                            ),
                          ),
                        ],
                        showingTooltipIndicators: value > 0 ? [0] : [],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chartContainer({required String title, required Widget child}) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16, // Slightly smaller
        fontWeight: FontWeight.bold,
        color: Colors.green.shade900,
      ),
    );
  }

  Widget _buildBannerSection(AppTheme appTheme) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _bannerImages.length,
            onPageChanged: (index) {
              setState(() => _currentBannerIndex = index);
            },
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        _bannerImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          index == 0
                              ? 'Grow Your Business'
                              : index == 1
                              ? 'Track Sales Live'
                              : 'Manage Your Team',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _bannerImages.asMap().entries.map((entry) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentBannerIndex == entry.key ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _currentBannerIndex == entry.key
                    ? appTheme
                          .colors
                          .primary // Dynamic Theme Color
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
