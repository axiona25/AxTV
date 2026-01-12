import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/profile_storage.dart';
import '../model/user_profile.dart';
import '../../channels/state/channels_controller.dart';
import '../../channels/model/channel.dart';
import '../../../widgets/zappr_app_header.dart';
import '../../../widgets/zappr_bottom_nav_with_logo.dart';
import '../../../theme/zappr_tokens.dart';
import '../../../theme/zappr_theme.dart';

/// Pagina Profilo - gestione dati utente
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  int _currentBottomNavIndex = 3; // Profilo è l'index 3

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  List<String> _selectedLanguages = [];
  String? _selectedCountry;
  
  List<Map<String, dynamic>> _allCountries = [];
  List<Map<String, dynamic>> _availableCountries = [];
  List<Map<String, String>> _availableLanguages = [];

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  /// Filtra i canali per mostrare solo quelli radio
  List<Channel> _filterRadioChannels(List<Channel> channels) {
    final radioKeywords = ['radio', 'Radio', 'RADIO'];
    return channels.where((channel) {
      final name = channel.name.toLowerCase();
      return radioKeywords.any((keyword) => name.contains(keyword.toLowerCase()));
    }).toList();
  }

  /// Carica i canali radio e estrae lingue e paesi disponibili
  void _updateAvailableLanguagesAndCountries(List<Channel> channels) {
    if (_allCountries.isEmpty) return; // Aspetta che i paesi siano caricati

    // Filtra solo i canali radio
    final radioChannels = _filterRadioChannels(channels);

    // Estrai regioni uniche dai canali radio
    final regions = radioChannels
        .where((c) => c.region != null && c.region!.isNotEmpty)
        .map((c) => c.region!.toLowerCase().trim())
        .toSet()
        .toList();

    // Mappa regioni ai paesi in countries.json
    final availableCountryCodes = <String>{};
    for (final region in regions) {
      // Cerca paese corrispondente (per codice o nome parziale)
      for (final country in _allCountries) {
        final code = (country['code'] as String).toLowerCase();
        final name = (country['name'] as String).toLowerCase();
        if (code == region || name.contains(region) || region.contains(code)) {
          availableCountryCodes.add(country['code'] as String);
          break;
        }
      }
    }

    // Se non troviamo corrispondenze, usiamo tutte le regioni come codici paese
    if (availableCountryCodes.isEmpty) {
      for (final region in regions) {
        // Cerca se il codice regione corrisponde a un paese
        final matchingCountry = _allCountries.firstWhere(
          (country) => (country['code'] as String).toLowerCase() == region,
          orElse: () => {},
        );
        if (matchingCountry.isNotEmpty) {
          availableCountryCodes.add(matchingCountry['code'] as String);
        }
      }
    }

    // Filtra paesi disponibili
    setState(() {
      _availableCountries = _allCountries
          .where((country) => availableCountryCodes.contains(country['code']))
          .toList()
        ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      // Estrai lingue dai paesi disponibili
      // Mappa codici paesi a lingue principali
      final languageMap = {
        'it': 'Italiano',
        'en': 'English',
        'fr': 'Français',
        'de': 'Deutsch',
        'es': 'Español',
        'pt': 'Português',
        'nl': 'Nederlands',
        'ru': 'Русский',
        'zh': '中文',
        'ja': '日本語',
        'ko': '한국어',
        'ar': 'العربية',
        'uk': 'Українська',
        'pl': 'Polski',
        'tr': 'Türkçe',
        'el': 'Ελληνικά',
        'cs': 'Čeština',
        'sv': 'Svenska',
        'no': 'Norsk',
        'da': 'Dansk',
        'fi': 'Suomi',
        'ro': 'Română',
        'hu': 'Magyar',
        'bg': 'Български',
        'hr': 'Hrvatski',
        'sk': 'Slovenčina',
        'sl': 'Slovenščina',
      };

      _availableLanguages = availableCountryCodes
          .map((code) {
            final langName = languageMap[code.toLowerCase()];
            if (langName != null) {
              return {'code': code.toLowerCase(), 'name': langName};
            }
            return null;
          })
          .whereType<Map<String, String>>()
          .toList()
        ..sort((a, b) => a['name']!.compareTo(b['name']!));
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/countries.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      setState(() {
        _allCountries = jsonList.map((e) => e as Map<String, dynamic>).toList();
      });
    } catch (e) {
      // Ignora errori
    }
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileStorage.loadProfile();
    if (profile != null && mounted) {
      setState(() {
        _firstNameController.text = profile.firstName ?? '';
        _lastNameController.text = profile.lastName ?? '';
        _emailController.text = profile.email ?? '';
        _selectedLanguages = List<String>.from(profile.languages);
        _selectedCountry = profile.country;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validazione password se inserita
    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text != _confirmPasswordController.text) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le password non corrispondono'),
              backgroundColor: ZapprTokens.danger,
            ),
          );
        }
        return;
      }
      if (_passwordController.text.length < 6) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La password deve contenere almeno 6 caratteri'),
              backgroundColor: ZapprTokens.danger,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _loading = true;
    });

    try {
      final profile = UserProfile(
        firstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        languages: _selectedLanguages,
        country: _selectedCountry,
      );

      await ProfileStorage.saveProfile(profile);

      // Salva password se inserita
      if (_passwordController.text.isNotEmpty) {
        // In produzione, qui dovresti fare hash della password (es. bcrypt)
        // Per ora salviamo un hash semplice (NON SICURO per produzione!)
        final passwordHash = _passwordController.text.hashCode.toString();
        await ProfileStorage.savePasswordHash(passwordHash);
        _passwordController.clear();
        _confirmPasswordController.clear();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profilo salvato con successo'),
            backgroundColor: ZapprTokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel salvataggio: $e'),
            backgroundColor: ZapprTokens.danger,
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
  Widget build(BuildContext context) {
    final scaler = context.scaler;
    final channelsAsync = ref.watch(channelsStreamProvider);

    // Aggiorna lingue e paesi disponibili quando i canali vengono caricati
    channelsAsync.whenData((channels) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateAvailableLanguagesAndCountries(channels);
        }
      });
    });

    return Scaffold(
      backgroundColor: ZapprTokens.bg0,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/background_07.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: ZapprTokens.bg0);
              },
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                ZapprAppHeader(
                  onSettingsTap: () {
                    context.push('/settings');
                  },
                  isSearchActive: false,
                ),
                SizedBox(height: scaler.spacing(20)),
                
                // Title
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: scaler.spacing(ZapprTokens.horizontalPadding),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Profilo',
                      style: TextStyle(
                        fontSize: scaler.fontSize(ZapprTokens.fontSizeSectionTitle),
                        fontWeight: FontWeight.bold,
                        color: ZapprTokens.textPrimary,
                        fontFamily: ZapprTokens.fontFamily,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: scaler.spacing(20)),
                
                // Form content
                Expanded(
                  child: _buildForm(scaler),
                ),
              ],
            ),
          ),
          // Bottom navigation with logo
          ZapprBottomNavWithLogo(
            currentIndex: _currentBottomNavIndex,
            onTap: (index) {
              setState(() {
                _currentBottomNavIndex = index;
              });
              
              // Navigazione tra pagine
              switch (index) {
                case 0:
                  context.go('/');
                  break;
                case 1:
                  context.go('/radio');
                  break;
                case 2:
                  context.go('/favorites');
                  break;
                case 3:
                  context.go('/profile');
                  break;
              }
            },
            logoAssetPath: 'assets/icona.png',
          ),
        ],
      ),
    );
  }

  Widget _buildForm(LayoutScaler scaler) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: scaler.spacing(ZapprTokens.horizontalPadding),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nome
            _buildTextField(
              scaler,
              controller: _firstNameController,
              label: 'Nome',
              hint: 'Inserisci il tuo nome',
              icon: Icons.person,
            ),
            SizedBox(height: scaler.spacing(16)),
            
            // Cognome
            _buildTextField(
              scaler,
              controller: _lastNameController,
              label: 'Cognome',
              hint: 'Inserisci il tuo cognome',
              icon: Icons.person_outline,
            ),
            SizedBox(height: scaler.spacing(16)),
            
            // Email
            _buildTextField(
              scaler,
              controller: _emailController,
              label: 'Email',
              hint: 'Inserisci la tua email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Inserisci un\'email valida';
                  }
                }
                return null;
              },
            ),
            SizedBox(height: scaler.spacing(16)),
            
            // Password
            _buildTextField(
              scaler,
              controller: _passwordController,
              label: 'Nuova Password',
              hint: 'Lascia vuoto per non modificare',
              icon: Icons.lock,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: ZapprTokens.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            SizedBox(height: scaler.spacing(16)),
            
            // Conferma Password
            _buildTextField(
              scaler,
              controller: _confirmPasswordController,
              label: 'Conferma Password',
              hint: 'Conferma la nuova password',
              icon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  color: ZapprTokens.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            SizedBox(height: scaler.spacing(16)),
            
            // Lingue parlate (selezione multipla)
            _buildLanguagesSection(scaler),
            SizedBox(height: scaler.spacing(16)),
            
            // Paese di origine
            _buildCountryDropdown(scaler),
            SizedBox(height: scaler.spacing(32)),
            
            // Pulsante Salva
            _buildSaveButton(scaler),
            SizedBox(height: scaler.spacing(80)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    LayoutScaler scaler, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(scaler.r(ZapprTokens.r16)),
        color: const Color(0xFF08213C).withOpacity(0.65),
        border: Border.all(
          width: 1.0,
          color: ZapprTokens.neonBlue.withOpacity(0.6),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(
          color: ZapprTokens.textPrimary,
          fontSize: scaler.fontSize(ZapprTokens.fontSizeBody),
          fontFamily: ZapprTokens.fontFamily,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: ZapprTokens.neonCyan.withOpacity(0.9)),
          suffixIcon: suffixIcon,
          labelStyle: TextStyle(
            color: ZapprTokens.textSecondary,
            fontSize: scaler.fontSize(ZapprTokens.fontSizeBody),
            fontFamily: ZapprTokens.fontFamily,
          ),
          hintStyle: TextStyle(
            color: ZapprTokens.textSecondary.withOpacity(0.6),
            fontSize: scaler.fontSize(ZapprTokens.fontSizeBody),
            fontFamily: ZapprTokens.fontFamily,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: scaler.spacing(16),
            vertical: scaler.spacing(16),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildLanguagesSection(LayoutScaler scaler) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.language, color: ZapprTokens.neonCyan.withOpacity(0.9), size: scaler.s(20)),
            SizedBox(width: scaler.spacing(8)),
            Text(
              'Lingue parlate',
              style: TextStyle(
                fontSize: scaler.fontSize(ZapprTokens.fontSizeBody),
                fontWeight: FontWeight.bold,
                color: ZapprTokens.textPrimary,
                fontFamily: ZapprTokens.fontFamily,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedLanguages.clear();
                });
              },
              child: Text(
                'Deseleziona tutti',
                style: TextStyle(
                  fontSize: scaler.fontSize(ZapprTokens.fontSizeSecondary),
                  color: ZapprTokens.neonCyan.withOpacity(0.9),
                  fontFamily: ZapprTokens.fontFamily,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: scaler.spacing(12)),
        if (_availableLanguages.isEmpty)
          Padding(
            padding: EdgeInsets.all(scaler.spacing(16)),
            child: Text(
              'Caricamento lingue disponibili...',
              style: TextStyle(
                fontSize: scaler.fontSize(ZapprTokens.fontSizeSecondary),
                color: ZapprTokens.textSecondary,
                fontFamily: ZapprTokens.fontFamily,
              ),
            ),
          )
        else
          Wrap(
            spacing: scaler.spacing(8),
            runSpacing: scaler.spacing(8),
            children: _availableLanguages.map((lang) {
              final langCode = lang['code']!;
              final langName = lang['name']!;
              final isSelected = _selectedLanguages.contains(langCode);
              return FilterChip(
                label: Text(langName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedLanguages.add(langCode);
                    } else {
                      _selectedLanguages.remove(langCode);
                    }
                  });
                },
                selectedColor: ZapprTokens.neonBlue,
                checkmarkColor: Colors.white,
                backgroundColor: const Color(0xFF08213C).withOpacity(0.65),
                side: BorderSide(
                  color: isSelected
                      ? ZapprTokens.neonBlue
                      : ZapprTokens.neonBlue.withOpacity(0.6),
                  width: 1.0,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : ZapprTokens.textPrimary,
                  fontSize: scaler.fontSize(ZapprTokens.fontSizeSecondary),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontFamily: ZapprTokens.fontFamily,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCountryDropdown(LayoutScaler scaler) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(scaler.r(ZapprTokens.r16)),
        color: const Color(0xFF08213C).withOpacity(0.65),
        border: Border.all(
          width: 1.0,
          color: ZapprTokens.neonBlue.withOpacity(0.6),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: scaler.spacing(16),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCountry,
        decoration: InputDecoration(
          labelText: 'Paese di origine',
          prefixIcon: Icon(Icons.flag, color: ZapprTokens.neonCyan.withOpacity(0.9)),
          labelStyle: TextStyle(
            color: ZapprTokens.textSecondary,
            fontSize: scaler.fontSize(ZapprTokens.fontSizeBody),
            fontFamily: ZapprTokens.fontFamily,
          ),
          border: InputBorder.none,
        ),
        style: TextStyle(
          color: ZapprTokens.textPrimary,
          fontSize: scaler.fontSize(ZapprTokens.fontSizeBody),
          fontFamily: ZapprTokens.fontFamily,
        ),
        dropdownColor: const Color(0xFF08213C),
        icon: Icon(Icons.arrow_drop_down, color: ZapprTokens.neonCyan.withOpacity(0.9)),
        items: _availableCountries.map((country) {
          final code = country['code'] as String;
          final name = country['name'] as String;
          final flag = country['flag'] as String? ?? '';
          return DropdownMenuItem<String>(
            value: code,
            child: Text('$flag $name'),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCountry = value;
          });
        },
      ),
    );
  }

  Widget _buildSaveButton(LayoutScaler scaler) {
    return ElevatedButton(
      onPressed: _loading ? null : _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: ZapprTokens.neonBlue,
        padding: EdgeInsets.symmetric(
          vertical: scaler.spacing(16),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(scaler.r(ZapprTokens.r16)),
        ),
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
          : Text(
              'Salva Profilo',
              style: TextStyle(
                fontSize: scaler.fontSize(ZapprTokens.fontSizeBody),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: ZapprTokens.fontFamily,
              ),
            ),
    );
  }
}
