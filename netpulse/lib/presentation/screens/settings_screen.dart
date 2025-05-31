import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sim_card_info/sim_info.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/location_service.dart';
import '../../data/services/phone_service.dart';
import 'package:geolocator/geolocator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _backgroundDataEnabled = true;
  bool _locationTrackingEnabled = false;
  bool _phoneAccessEnabled = false;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'System';
  Position? _currentPosition;
  SimInfo? _simInfo;

  final List<String> _languages = ['English', 'French'];
  final List<String> _themes = ['System', 'Light', 'Dark'];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final locationService = context.read<LocationService>();

    // Check current location permission state
    final isLocationPermissionGranted = await locationService.isLocationPermissionGranted();

    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _backgroundDataEnabled = prefs.getBool('backgroundDataEnabled') ?? true;
      _locationTrackingEnabled = isLocationPermissionGranted; // Sync with actual permission state
      _phoneAccessEnabled = prefs.getBool('phoneAccessEnabled') ?? false;
      _selectedLanguage = prefs.getString('language') ?? 'English';
      _selectedTheme = prefs.getString('theme') ?? 'System';
      print('Loaded theme: $_selectedTheme');
    });

    if (_locationTrackingEnabled) {
      _currentPosition = await locationService.getLastKnownLocation();
      setState(() {});
    }
    if (_phoneAccessEnabled) {
      final phoneService = context.read<PhoneService>();
      _simInfo = await phoneService.getLastKnownSimInfo();
      setState(() {});
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('backgroundDataEnabled', _backgroundDataEnabled);
    await prefs.setBool('locationTrackingEnabled', _locationTrackingEnabled);
    await prefs.setBool('phoneAccessEnabled', _phoneAccessEnabled);
    await prefs.setString('language', _selectedLanguage);
    await prefs.setString('theme', _selectedTheme);

    final newThemeMode = _selectedTheme == 'System'
        ? ThemeMode.system
        : _selectedTheme == 'Light'
            ? ThemeMode.light
            : ThemeMode.dark;
    Get.changeThemeMode(newThemeMode);
    print('Theme mode changed to: $newThemeMode');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!')),
    );
  }

  Future<void> _updateLocationTracking(bool enabled) async {
    final locationService = context.read<LocationService>();

    if (enabled) {
      // Request location permission
      final hasPermission = await locationService.requestLocationPermission();
      if (!hasPermission) {
        final shouldRetry = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Location Permission Required', style: GoogleFonts.poppins()),
            content: Text(
              'Location tracking requires permission. Please enable it in settings.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6))),
              ),
              TextButton(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                  Navigator.pop(context, true);
                },
                child: Text('Open Settings', style: GoogleFonts.poppins(color: Colors.teal)),
              ),
            ],
          ),
        );

        if (shouldRetry ?? false) {
          final isGranted = await locationService.isLocationPermissionGranted();
          if (!isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission still denied. Please enable it in settings.')),
            );
            setState(() {
              _locationTrackingEnabled = false;
            });
            return;
          }
        } else {
          setState(() {
            _locationTrackingEnabled = false;
          });
          return;
        }
      }

      // Permission granted, fetch location
      final serviceEnabled = await locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location service is disabled. Please enable it.')),
        );
        setState(() {
          _locationTrackingEnabled = false;
        });
        return;
      }

      _currentPosition = await locationService.getCurrentLocation();
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get location. Please try again.')),
        );
        setState(() {
          _locationTrackingEnabled = false;
        });
      } else {
        setState(() {
          _locationTrackingEnabled = true;
        });
      }
    } else {
      // Prompt user to disable location permission
      final shouldDisable = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Disable Location Access', style: GoogleFonts.poppins()),
          content: Text(
            'To disable location tracking, please revoke location permission in app settings.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6))),
            ),
            TextButton(
              onPressed: () async {
                await Geolocator.openAppSettings();
                Navigator.pop(context, true);
              },
              child: Text('Open Settings', style: GoogleFonts.poppins(color: Colors.teal)),
            ),
          ],
        ),
      );

      if (shouldDisable ?? false) {
        // Check permission state after user returns from settings
        final isGranted = await locationService.isLocationPermissionGranted();
        setState(() {
          _locationTrackingEnabled = isGranted;
          if (!isGranted) {
            _currentPosition = null; // Clear location data if permission is revoked
          }
        });

        if (isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is still enabled. Toggle remains on.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission disabled successfully.')),
          );
        }
      } else {
        // User canceled, revert toggle to true
        setState(() {
          _locationTrackingEnabled = true;
        });
      }
    }
  }

  Future<void> _updatePhoneAccess(bool enabled) async {
    final phoneService = context.read<PhoneService>();
    if (enabled) {
      final hasPermission = await phoneService.requestPhonePermission();
      if (!hasPermission) {
        final shouldRetry = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Phone Access Required', style: GoogleFonts.poppins()),
            content: Text(
              'Phone access is needed to detect your network provider. Please enable it in settings.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6))),
              ),
              TextButton(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                  Navigator.pop(context, true);
                },
                child: Text('Open Settings', style: GoogleFonts.poppins(color: Colors.teal)),
              ),
            ],
          ),
        );

        if (shouldRetry ?? false) {
          final newPermission = await Permission.phone.status;
          if (!newPermission.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Phone permission still denied. Please enable it in settings.')),
            );
            setState(() {
              _phoneAccessEnabled = false;
            });
            return;
          }
        } else {
          setState(() {
            _phoneAccessEnabled = false;
          });
          return;
        }
      }

      _simInfo = await phoneService.getSimInfo();
      if (_simInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get SIM info. Please ensure a SIM card is inserted.')),
        );
        setState(() {
          _phoneAccessEnabled = false;
        });
      } else {
        setState(() {
          _phoneAccessEnabled = true;
        });
      }
    } else {
      _simInfo = null;
      setState(() {
        _phoneAccessEnabled = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  'Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Notifications Section
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black54
                          : Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: Text(
                        'Enable Notifications',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.secondary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Data Usage Section
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black54
                          : Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Usage',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: Text(
                        'Background Data',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      value: _backgroundDataEnabled,
                      onChanged: (value) {
                        setState(() {
                          _backgroundDataEnabled = value;
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.secondary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Privacy Section
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black54
                          : Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: Text(
                        'Location Tracking',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      value: _locationTrackingEnabled,
                      onChanged: (value) async {
                        await _updateLocationTracking(value);
                      },
                      activeColor: Theme.of(context).colorScheme.secondary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    ),
                    // if (_locationTrackingEnabled && _currentPosition != null) ...[
                    //   const SizedBox(height: 10),
                    //   Text(
                    //     'Latitude: ${_currentPosition!.latitude.toStringAsFixed(4)}',
                    //     style: GoogleFonts.poppins(
                    //       fontSize: 14,
                    //       color: Theme.of(context).colorScheme.onBackground,
                    //     ),
                    //   ),
                    //   Text(
                    //     'Longitude: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                    //     style: GoogleFonts.poppins(
                    //       fontSize: 14,
                    //       color: Theme.of(context).colorScheme.onBackground,
                    //     ),
                    //   ),
                    // ],
                    if (_locationTrackingEnabled && _currentPosition == null)
                      Text(
                        'Location not available',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                        ),
                      ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: Text(
                        'Phone Access',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      value: _phoneAccessEnabled,
                      onChanged: (value) async {
                        await _updatePhoneAccess(value);
                      },
                      activeColor: Theme.of(context).colorScheme.secondary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    ),
                    if (_phoneAccessEnabled && _simInfo != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Network Provider: ${_simInfo!.carrierName}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    ],
                    if (_phoneAccessEnabled && _simInfo == null)
                      Text(
                        'Network provider not available',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Preferences Section
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black54
                          : Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferences',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: Text(
                        'Language',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      trailing: DropdownButton<String>(
                        value: _selectedLanguage,
                        items: _languages.map((String language) {
                          return DropdownMenuItem<String>(
                            value: language,
                            child: Text(
                              language,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedLanguage = newValue;
                            });
                          }
                        },
                        underline: const SizedBox(),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    ),
                    ListTile(
                      title: Text(
                        'Theme',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      trailing: DropdownButton<String>(
                        value: _selectedTheme,
                        items: _themes.map((String theme) {
                          return DropdownMenuItem<String>(
                            value: theme,
                            child: Text(
                              theme,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedTheme = newValue;
                            });
                          }
                        },
                        underline: const SizedBox(),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Footer Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _savePreferences,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              'Logout',
                              style: GoogleFonts.poppins(),
                            ),
                            content: Text(
                              'Are you sure you want to logout?',
                              style: GoogleFonts.poppins(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'Logout',
                                  style: GoogleFonts.poppins(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _logout();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Log Out',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}