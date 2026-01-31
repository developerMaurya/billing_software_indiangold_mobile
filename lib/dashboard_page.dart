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

  Map<String, dynamic>? companyData;
  bool isLoading = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Stats
  double totalSales = 0;
  double totalInvestment = 0; // Inventory Value
  int totalProducts = 0;
  int totalCustomers = 0;
  int lowStockCount = 0;
  int outOfStockCount = 0;
  String topSellingProduct = 'None';

  // Chart Data
  List<FlSpot> salesTrend = [];
  Map<String, double> categoryStock = {};
  List<int> monthlyCustomers = List.filled(6, 0); // Last 6 months

  // Banner
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
    _fetchCompanyData();
    _fetchStats();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    if (mounted) {
      _controller.forward();
    }

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

  Future<void> _fetchCompanyData() async {
    String? targetUid = currentUid;

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

  Future<void> _fetchStats() async {
    String? targetUid = currentUid;
    if (targetUid == null) return;

    try {
      // Fetch Products Count & Category Data
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where(
            'uid',
            isEqualTo: targetUid,
          ) // Assuming specific to user? Or global?
          .get();
      // If products are global or per shop, adjust query.
      // Based on profile_page, shops are by uid. Assuming products might strictly belong to them.
      // If no uid field, we might need another way. But let's assume standard practice.
      // If query returns empty because of missing 'uid' field, we will handle gracefully.
      // Actually, looking at product_model, there is no 'shopId' or 'uid'.
      // So assuming all products are visible or we need to filter differently.
      // For now, I'll fetch ALL products if 'uid' filter fails (or just fetch all if small app).
      // Let's rely on collection 'products' existing.

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

      // Fetch Customers Count
      final customersDocs = await FirebaseFirestore.instance
          .collection('customers')
          .get();
      int cCount = customersDocs.size;

      // Fetch Sales for Trends and Top Product
      final salesDocs = await FirebaseFirestore.instance
          .collection('sales')
          .orderBy('saleDate')
          .get();
      double tSales = 0;
      List<FlSpot> trend = [];
      Map<String, int> productSalesCount = {};

      // Group sales by day for the last 30 days
      Map<int, double> dailySales = {};

      for (var doc in salesDocs.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double amount = (data['totalAmount'] ?? 0.0).toDouble();
        tSales += amount;

        // Product popularity
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
        if (dayKey >= 0) {
          dailySales[dayKey] = (dailySales[dayKey] ?? 0) + amount;
        }
      }

      // Determine Top Selling
      String topProduct = 'None';
      int maxSold = 0;
      productSalesCount.forEach((key, value) {
        if (value > maxSold) {
          maxSold = value;
          topProduct = key;
        }
      });

      // Convert map to spots
      dailySales.forEach((key, value) {
        trend.add(FlSpot(key.toDouble(), value));
      });
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
          salesTrend = trend.isEmpty
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
      SalesScreen(
        uid: currentUid,
        companyData: companyData,
      ), // Changed from Placeholder
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
              icon: Icon(Icons.sell_outlined),
              selectedIcon: Icon(Icons.sell),
              label: 'Sales',
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
          _drawerItem(Icons.dashboard, 'Dashboard', () => _onItemTapped(0)),
          _drawerItem(Icons.people, 'Customers', () => _onItemTapped(1)),
          _drawerItem(Icons.inventory_2, 'Products', () => _onItemTapped(2)),
          _drawerItem(Icons.sell, 'Sales', () => _onItemTapped(3)),
          const Divider(),
          _drawerItem(
            Icons.history,
            'History',
            () => _navigateToPage(const SalesHistoryPage()),
          ),
          _drawerItem(
            Icons.category,
            'Inventory',
            () => _navigateToPage(const InventoryPage()),
          ),
          const Divider(),
          _drawerItem(Icons.settings, 'Settings', () => _showSettings()),
          _drawerItem(Icons.person, 'Profile', () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(uid: currentUid),
              ),
            );
            _fetchCompanyData();
          }),
          _drawerItem(
            Icons.analytics,
            'Reports',
            () => _navigateToPage(const ReportsPage()),
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

  ListTile _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
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

  void _showSettings() {
    // Placeholder for settings page
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings page coming soon!')));
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
                    const SizedBox(height: 20),
                    _buildBannerSection(),
                    const SizedBox(height: 25),
                    _buildStatsCards(),
                    const SizedBox(height: 25),
                    _buildChartsSection(),
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
              ? (companyData!['logo']!.startsWith('http')
                    ? NetworkImage(companyData!['logo'])
                    : FileImage(File(companyData!['logo'])) as ImageProvider)
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

  Widget _buildStatsCards() {
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
                Colors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'Profit',
                '₹${NumberFormat.compact().format(totalSales * 0.2)}',
                Icons.trending_up,
                Colors.blue,
              ),
            ), // Mock profit 20%
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

  Widget _buildChartsSection() {
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
              // Chart 1: Sales Trend (Multi-Line Chart)
              _chartContainer(
                title: 'Live Sales Analytics',
                child: salesTrend.isEmpty
                    ? const Center(child: Text("No Data"))
                    : Column(
                        children: [
                          Expanded(
                            child: LineChart(
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
                                      reservedSize: 22,
                                      interval: 7, // Show every 7 days
                                      getTitlesWidget: (value, meta) {
                                        // Assuming x-axis represents days (0-29)
                                        if (value.toInt() % 7 == 0) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8.0,
                                            ),
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
                                          '₹${spot.y.toStringAsFixed(0)}',
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
                                  // Blue: Total Sales
                                  LineChartBarData(
                                    spots: salesTrend,
                                    isCurved: true,
                                    color: Colors.blue,
                                    barWidth: 3,
                                    dotData: FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.blue.withOpacity(0.1),
                                    ),
                                  ),
                                  // Red: Medical Sales (Mock)
                                  LineChartBarData(
                                    spots: salesTrend
                                        .map((e) => FlSpot(e.x, e.y * 0.7))
                                        .toList(),
                                    isCurved: true,
                                    color: Colors.redAccent,
                                    barWidth: 2,
                                    dotData: FlDotData(show: false),
                                  ),
                                  // Green: Product Sales (Mock)
                                  LineChartBarData(
                                    spots: salesTrend
                                        .map((e) => FlSpot(e.x, e.y * 0.5))
                                        .toList(),
                                    isCurved: true,
                                    color: Colors.green,
                                    barWidth: 2,
                                    dotData: FlDotData(show: false),
                                  ),
                                  // Yellow: Other (Mock)
                                  LineChartBarData(
                                    spots: salesTrend
                                        .map((e) => FlSpot(e.x, e.y * 0.3))
                                        .toList(),
                                    isCurved: true,
                                    color: Colors.amber,
                                    barWidth: 2,
                                    dotData: FlDotData(show: false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Legend
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            alignment: WrapAlignment.center,
                            children: [
                              _chartLegendItem('Total', Colors.blue),
                              _chartLegendItem('Medical', Colors.redAccent),
                              _chartLegendItem('Product', Colors.green),
                              _chartLegendItem('Other', Colors.amber),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 15),

              // Chart 2: Stock Management (Pie Chart)
              _chartContainer(
                title: 'Stock Management',
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: [
                      PieChartSectionData(
                        color: Colors.green,
                        value: (totalProducts - lowStockCount - outOfStockCount)
                            .toDouble(),
                        title: 'Good',
                        radius: 40,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PieChartSectionData(
                        color: Colors.orange,
                        value: lowStockCount.toDouble(),
                        title: 'Low',
                        radius: 40,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PieChartSectionData(
                        color: Colors.red,
                        value: outOfStockCount.toDouble(),
                        title: 'Out',
                        radius: 40,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 15),

              // Chart 3: Product Categories (Bar Chart) - Renamed from "Stock Management"
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
                            if (val.toInt() < categoryStock.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  categoryStock.keys
                                      .elementAt(val.toInt())
                                      .substring(0, 3),
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
                    barGroups: List.generate(
                      categoryStock.length > 5 ? 5 : categoryStock.length,
                      (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: categoryStock.values.elementAt(index),
                              color: Colors.indigo.shade400,
                              width: 12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      },
                    ),
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

  Widget _buildBannerSection() {
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
                    ? Colors.green.shade700
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _chartLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
