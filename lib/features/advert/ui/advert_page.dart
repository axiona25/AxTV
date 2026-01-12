import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../model/ad_config.dart';
import '../state/ad_config_provider.dart';
import '../state/ad_statistics_provider.dart';
import '../data/ad_statistics_storage.dart';
import '../../channels/data/live_repositories_storage.dart';
import '../../channels/model/repository_config.dart';

/// Pagina per la gestione e configurazione delle pubblicità
class AdvertPage extends ConsumerStatefulWidget {
  const AdvertPage({super.key});

  @override
  ConsumerState<AdvertPage> createState() => _AdvertPageState();
}

class _AdvertPageState extends ConsumerState<AdvertPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bannerAdUnitIdController = TextEditingController();
  final TextEditingController _interstitialAdUnitIdController = TextEditingController();
  final TextEditingController _rewardedAdUnitIdController = TextEditingController();
  
  List<Map<String, dynamic>> _countries = [];
  List<String> _selectedCountries = [];
  List<String> _selectedLanguages = [];
  List<String> _selectedRepositories = [];
  List<String> _selectedCategories = ['Intrattenimento', 'News', 'Sport'];
  
  final List<String> _availableLanguages = [
    'it', 'en', 'fr', 'de', 'es', 'pt', 'nl', 'ru', 'zh', 'ja', 'ko', 'ar'
  ];
  
  final List<String> _availableCategories = [
    'Intrattenimento', 'News', 'Sport', 'Cinema', 'Musica', 'Documentari'
  ];

  bool _testMode = true;
  bool _enabled = false;
  int _maxPerDay = 10;
  int _minVideoDurationSeconds = 30;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _loadConfig();
    _loadRepositories();
  }

  Future<void> _loadCountries() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/countries.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      setState(() {
        _countries = jsonList.map((e) => e as Map<String, dynamic>).toList();
      });
    } catch (e) {
      // Ignora errori
    }
  }

  Future<void> _loadConfig() async {
    final configAsync = ref.read(adConfigProvider);
    configAsync.whenData((config) {
      setState(() {
        _enabled = config.enabled;
        _selectedCountries = List<String>.from(config.countries);
        _selectedLanguages = List<String>.from(config.languages);
        _selectedRepositories = List<String>.from(config.enabledRepositories);
        _selectedCategories = List<String>.from(config.categories);
        _maxPerDay = config.maxPerDay;
        _minVideoDurationSeconds = config.minVideoDurationSeconds;
        _testMode = config.testMode;
        _bannerAdUnitIdController.text = config.bannerAdUnitId ?? '';
        _interstitialAdUnitIdController.text = config.interstitialAdUnitId ?? '';
        _rewardedAdUnitIdController.text = config.rewardedAdUnitId ?? '';
      });
    });
  }

  Future<void> _loadRepositories() async {
    // I repository vengono caricati dinamicamente
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final config = AdConfig(
        enabled: _enabled,
        countries: _selectedCountries,
        languages: _selectedLanguages,
        maxPerDay: _maxPerDay,
        minVideoDurationSeconds: _minVideoDurationSeconds,
        enabledRepositories: _selectedRepositories,
        disabledRepositories: [],
        categories: _selectedCategories,
        bannerAdUnitId: _bannerAdUnitIdController.text.isEmpty 
            ? null 
            : _bannerAdUnitIdController.text,
        interstitialAdUnitId: _interstitialAdUnitIdController.text.isEmpty
            ? null
            : _interstitialAdUnitIdController.text,
        rewardedAdUnitId: _rewardedAdUnitIdController.text.isEmpty
            ? null
            : _rewardedAdUnitIdController.text,
        testMode: _testMode,
      );

                    await AdConfigNotifier.saveConfig(ref, config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurazione pubblicità salvata con successo'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel salvataggio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerAdUnitIdController.dispose();
    _interstitialAdUnitIdController.dispose();
    _rewardedAdUnitIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(adConfigProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        title: const Text(
          'Gestione Pubblicità',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: AppTheme.textPrimary),
            onPressed: _loading ? null : _saveConfig,
            tooltip: 'Salva configurazione',
          ),
        ],
      ),
      body: configAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Errore nel caricamento: $error',
                style: const TextStyle(color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(adConfigProvider),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
        data: (config) => _buildContentWithStats(),
      ),
    );
  }

  Widget _buildContentWithStats() {
    final statsAsync = ref.watch(adStatisticsProvider);
    
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistiche in tempo reale
            _buildStatisticsSection(statsAsync),
            const SizedBox(height: 24),
            
            // Switch principale per abilitare/disabilitare
            _buildEnableSwitch(),
            const SizedBox(height: 24),
            
            // Test Mode
            _buildTestModeSwitch(),
            const SizedBox(height: 24),
            
            // Ad Unit IDs
            _buildAdUnitIdsSection(),
            const SizedBox(height: 24),
            
            // Configurazione Paesi
            _buildCountriesSection(),
            const SizedBox(height: 24),
            
            // Configurazione Lingue
            _buildLanguagesSection(),
            const SizedBox(height: 24),
            
            // Configurazione Frequenza
            _buildFrequencySection(),
            const SizedBox(height: 24),
            
            // Configurazione Durata Video
            _buildVideoDurationSection(),
            const SizedBox(height: 24),
            
            // Configurazione Repository
            _buildRepositoriesSection(),
            const SizedBox(height: 24),
            
            // Configurazione Categorie Tematiche
            _buildCategoriesSection(),
            const SizedBox(height: 32),
            
            // Pulsante Salva
            _buildSaveButton(),
            const SizedBox(height: 16),
            
            // Pulsante Reset
            _buildResetButton(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.ads_click, color: AppTheme.primaryBlue, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Abilita Pubblicità',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Attiva o disattiva la visualizzazione delle pubblicità nell\'app',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _enabled,
            onChanged: (value) {
              setState(() {
                _enabled = value;
              });
            },
            activeColor: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildTestModeSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report, color: AppTheme.primaryBlue, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Modalità Test',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Usa Ad Unit ID di test per lo sviluppo (ATTIVO = test ads)',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _testMode,
            onChanged: (value) {
              setState(() {
                _testMode = value;
              });
            },
            activeColor: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildAdUnitIdsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ad Unit IDs',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _bannerAdUnitIdController,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Banner Ad Unit ID',
            hintText: _testMode 
                ? 'ca-app-pub-3940256099942544/6300978111'
                : 'Inserisci il Banner Ad Unit ID',
            labelStyle: const TextStyle(color: AppTheme.textSecondary),
            hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.cardBackground,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _interstitialAdUnitIdController,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Interstitial Ad Unit ID',
            hintText: _testMode
                ? 'ca-app-pub-3940256099942544/1033173712'
                : 'Inserisci l\'Interstitial Ad Unit ID',
            labelStyle: const TextStyle(color: AppTheme.textSecondary),
            hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.cardBackground,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _rewardedAdUnitIdController,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Rewarded Video Ad Unit ID',
            hintText: _testMode
                ? 'ca-app-pub-3940256099942544/5224354917'
                : 'Inserisci il Rewarded Video Ad Unit ID',
            labelStyle: const TextStyle(color: AppTheme.textSecondary),
            hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.cardBackground,
          ),
        ),
      ],
    );
  }

  Widget _buildCountriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Paesi',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCountries.clear();
                });
              },
              child: const Text('Deseleziona tutti'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _countries.length,
            itemBuilder: (context, index) {
              final country = _countries[index];
              final code = country['code'] as String;
              final name = country['name'] as String;
              final flag = country['flag'] as String? ?? '';
              final isSelected = _selectedCountries.contains(code);
              
              return CheckboxListTile(
                title: Text('$flag $name'),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedCountries.add(code);
                    } else {
                      _selectedCountries.remove(code);
                    }
                  });
                },
                activeColor: AppTheme.primaryBlue,
                checkColor: Colors.white,
                tileColor: AppTheme.cardBackground,
                selectedTileColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Lingue',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedLanguages.clear();
                });
              },
              child: const Text('Deseleziona tutti'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableLanguages.map((lang) {
            final isSelected = _selectedLanguages.contains(lang);
            return FilterChip(
              label: Text(lang.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedLanguages.add(lang);
                  } else {
                    _selectedLanguages.remove(lang);
                  }
                });
              },
              selectedColor: AppTheme.primaryBlue,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequenza Pubblicità',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Numero massimo di volte al giorno: $_maxPerDay',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
        Slider(
          value: _maxPerDay.toDouble(),
          min: 1,
          max: 50,
          divisions: 49,
          label: _maxPerDay.toString(),
          onChanged: (value) {
            setState(() {
              _maxPerDay = value.toInt();
            });
          },
          activeColor: AppTheme.primaryBlue,
        ),
      ],
    );
  }

  Widget _buildVideoDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Durata Video Minima',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Durata minima del video (in secondi) prima di mostrare pubblicità: $_minVideoDurationSeconds',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
        Slider(
          value: _minVideoDurationSeconds.toDouble(),
          min: 10,
          max: 300,
          divisions: 29,
          label: '$_minVideoDurationSeconds secondi',
          onChanged: (value) {
            setState(() {
              _minVideoDurationSeconds = value.toInt();
            });
          },
          activeColor: AppTheme.primaryBlue,
        ),
      ],
    );
  }

  Widget _buildRepositoriesSection() {
    return FutureBuilder<List<RepositoryConfig>>(
      future: LiveRepositoriesStorage.loadRepositoriesState(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('Errore nel caricamento dei repository');
        }
        
        final repositories = snapshot.data!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Repository',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedRepositories.clear();
                    });
                  },
                  child: const Text('Deseleziona tutti'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: repositories.length,
                itemBuilder: (context, index) {
                  final repo = repositories[index];
                  final isSelected = _selectedRepositories.contains(repo.id);
                  
                  return CheckboxListTile(
                    title: Text(repo.name),
                    subtitle: Text(
                      repo.description ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedRepositories.add(repo.id);
                        } else {
                          _selectedRepositories.remove(repo.id);
                        }
                      });
                    },
                    activeColor: AppTheme.primaryBlue,
                    checkColor: Colors.white,
                    tileColor: AppTheme.cardBackground,
                    selectedTileColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nota: Se nessun repository è selezionato, le pubblicità saranno mostrate su tutti i repository.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Categorie Tematiche',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategories.clear();
                });
              },
              child: const Text('Deseleziona tutti'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableCategories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
              },
              selectedColor: AppTheme.primaryBlue,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _saveConfig,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Salva Configurazione',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _loading
            ? null
            : () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.cardBackground,
                    title: const Text(
                      'Conferma Reset',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                    content: const Text(
                      'Vuoi ripristinare la configurazione ai valori di default?',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annulla'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Ripristina'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await AdConfigNotifier.resetToDefaults(ref);
                    await _loadConfig();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Configurazione ripristinata ai valori di default'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Errore nel ripristino: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryBlue,
          side: const BorderSide(color: AppTheme.primaryBlue),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Ripristina Valori di Default',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(AsyncValue statsAsync) {
    return statsAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              'Errore nel caricamento statistiche',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      data: (stats) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: AppTheme.blueGlow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: AppTheme.primaryBlue, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Statistiche in Tempo Reale',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue, size: 20),
                  onPressed: () => ref.invalidate(adStatisticsProvider),
                  tooltip: 'Aggiorna statistiche',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Statistiche principali
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Impressioni Oggi',
                    stats.todayImpressions.toString(),
                    Icons.remove_red_eye,
                    AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Revenue Oggi',
                    '\$${stats.todayRevenue.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Totale Impressioni',
                    stats.totalImpressions.toString(),
                    Icons.trending_up,
                    AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Totale Revenue',
                    '\$${stats.estimatedRevenue.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Fill Rate',
                    '${stats.fillRate.toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'CTR',
                    '${stats.ctr.toStringAsFixed(2)}%',
                    Icons.touch_app,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Statistiche per formato
            const Text(
              'Per Formato',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            
            if (stats.formatStats.isNotEmpty) ...[
              ...stats.formatStats.entries.map((entry) {
                final format = entry.key;
                final formatStats = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            format.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${formatStats.impressions} imp',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$${formatStats.estimatedRevenue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'eCPM: \$${formatStats.eCPM.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppTheme.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ] else
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Nessuna statistica disponibile',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Top Paesi
            if (stats.countryImpressions.isNotEmpty) ...[
              const Text(
                'Top Paesi',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...stats.countryImpressions.entries
                .toList()
                ..sort((a, b) => b.value.compareTo(a.value))
                ..take(3)
                .map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
            
            const SizedBox(height: 8),
            
            // Pulsante reset statistiche
            OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.cardBackground,
                    title: const Text(
                      'Reset Statistiche',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                    content: const Text(
                      'Vuoi resettare tutte le statistiche? Questa azione non può essere annullata.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annulla'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await AdStatisticsStorage.resetStatistics();
                    ref.invalidate(adStatisticsProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Statistiche resettate'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Errore nel reset: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text(
                'Reset Statistiche',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
