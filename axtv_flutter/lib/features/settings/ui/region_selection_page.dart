import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class RegionSelectionPage extends StatefulWidget {
  const RegionSelectionPage({super.key});

  @override
  State<RegionSelectionPage> createState() => _RegionSelectionPageState();
}

class _RegionSelectionPageState extends State<RegionSelectionPage> {
  String? _selectedRegion = 'Italia';
  final TextEditingController _searchController = TextEditingController();
  int _currentBottomNavIndex = 3; // Settings selected

  final List<Map<String, dynamic>> _regions = [
    {
      'name': 'Italia',
      'icon': Icons.grid_view,
      'selected': true,
      'subRegions': [
        'Nord Ovest',
        'Nord Est',
        'Centro',
        'Sud',
        'Isole',
      ],
    },
    {'name': 'Francia', 'icon': Icons.flag, 'flag': '🇫🇷'},
    {'name': 'Germania', 'icon': Icons.flag, 'flag': '🇩🇪'},
    {'name': 'Spagna', 'icon': Icons.flag, 'flag': '🇪🇸'},
    {'name': 'Regno Unito', 'icon': Icons.flag, 'flag': '🇬🇧'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Seleziona Regione',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildRegionsList(),
          ),
          _buildRestoreButton(),
          _buildRepositoriesButton(),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: AppTheme.blueGlow,
      ),
      child: BottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          setState(() {
            _currentBottomNavIndex = index;
          });
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              // TODO: Implementare pagina favorites
              break;
            case 2:
              // TODO: Implementare pagina list
              break;
            case 3:
              // Già su settings
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.textSecondary,
        selectedIconTheme: const IconThemeData(
          color: AppTheme.primaryBlue,
          size: 24,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppTheme.textSecondary,
          size: 24,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Preferiti',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_outlined),
            activeIcon: Icon(Icons.list),
            label: 'Lista',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Impostazioni',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Cerca regione',
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              color: AppTheme.textSecondary.withValues(alpha: 0.6),
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppTheme.textSecondary,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Europa',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _regions.length,
            itemBuilder: (context, index) {
              final region = _regions[index];
              final isSelected = _selectedRegion == region['name'];
              final hasSubRegions = region['subRegions'] != null;

              return Column(
                children: [
                  _buildRegionTile(region, isSelected),
                  if (hasSubRegions && isSelected)
                    ...region['subRegions'].map<Widget>((subRegion) {
                      return _buildSubRegionTile(subRegion);
                    }).toList(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRegionTile(Map<String, dynamic> region, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryBlue
              : AppTheme.primaryBlue.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? AppTheme.blueGlow : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: region['flag'] != null
            ? Text(
                region['flag'],
                style: const TextStyle(fontSize: 24),
              )
            : Icon(
                region['icon'] as IconData,
                color: isSelected
                    ? AppTheme.primaryBlue
                    : AppTheme.textSecondary,
              ),
        title: Text(
          region['name'],
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? AppTheme.primaryBlue
                : AppTheme.textPrimary,
          ),
        ),
        trailing: isSelected
            ? const Icon(
                Icons.check_circle,
                color: AppTheme.primaryBlue,
              )
            : null,
        onTap: () {
          setState(() {
            _selectedRegion = region['name'];
          });
        },
      ),
    );
  }

  Widget _buildSubRegionTile(String subRegion) {
    return Container(
      margin: const EdgeInsets.only(left: 32, bottom: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(
          Icons.star_border,
          color: AppTheme.textSecondary,
          size: 20,
        ),
        title: Text(
          subRegion,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        onTap: () {
          // Gestione selezione sotto-regione
        },
      ),
    );
  }

  Widget _buildRestoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              _selectedRegion = 'Italia';
            });
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: AppTheme.primaryBlue.withValues(alpha: 0.5),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Ripristina regione',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRepositoriesButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            context.push('/repositories-settings');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.movie, color: AppTheme.textPrimary),
              SizedBox(width: 8),
              Text(
                'Repository On-Demand',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

