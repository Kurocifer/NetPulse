import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netpulse/presentation/blocs/auth_bloc.dart';
import 'package:netpulse/presentation/blocs/auth_event.dart';
import 'package:netpulse/presentation/blocs/auth_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sim_card_info/sim_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/location_service.dart';
import '../../data/services/phone_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:netpulse/main.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  bool _backgroundDataEnabled = false;
  bool _locationTrackingEnabled = false;
  bool _phoneAccessEnabled = true;
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

    final isLocationPermissionGranted = await locationService.isLocationPermissionGranted();

    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
      _backgroundDataEnabled = prefs.getBool('backgroundDataEnabled') ?? false;
      _locationTrackingEnabled = isLocationPermissionGranted;
      _phoneAccessEnabled = prefs.getBool('phoneAccessEnabled') ?? true;
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
  }

  Future<void> _updateLocationTracking(bool enabled) async {
    final locationService = context.read<LocationService>();
    final colorScheme = Theme.of(context).colorScheme;

    if (enabled) {
      final hasPermission = await locationService.requestLocationPermission();
      if (!hasPermission) {
        final shouldRetry = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Location Permission Required', style: GoogleFonts.poppins(color: colorScheme.onSurface)),
            content: Text(
              'Location tracking requires permission. Please enable it in settings.',
              style: GoogleFonts.poppins(color: colorScheme.onSurface),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.poppins(color: colorScheme.onSurface.withOpacity(0.6))),
              ),
              TextButton(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                  Navigator.pop(context, true);
                },
                child: Text('Open Settings', style: GoogleFonts.poppins(color: secondaryColor)), 
              ),
            ],
          ),
        );

        if (shouldRetry ?? false) {
          final isGranted = await locationService.isLocationPermissionGranted();
          if (!isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location permission still denied. Please enable it in settings.', style: GoogleFonts.poppins(color: Colors.white)),
                backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
              ),
            );
            setState(() { _locationTrackingEnabled = false; });
            return;
          }
        } else {
          setState(() { _locationTrackingEnabled = false; });
          return;
        }
      }

      final serviceEnabled = await locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location service is disabled. Please enable it.', style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
          ),
        );
        setState(() { _locationTrackingEnabled = false; });
        return;
      }

      _currentPosition = await locationService.getCurrentLocation();
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location. Please try again.', style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
          ),
        );
        setState(() { _locationTrackingEnabled = false; });
      } else {
        setState(() { _locationTrackingEnabled = true; });
      }
    } else {
      final shouldDisable = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Disable Location Access', style: GoogleFonts.poppins(color: colorScheme.onSurface)),
          content: Text(
            'To disable location tracking, please revoke location permission in app settings.',
            style: GoogleFonts.poppins(color: colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.poppins(color: colorScheme.onSurface.withOpacity(0.6))),
            ),
            TextButton(
              onPressed: () async {
                await Geolocator.openAppSettings();
                Navigator.pop(context, true);
              },
              child: Text('Open Settings', style: GoogleFonts.poppins(color: secondaryColor)),
            ),
          ],
        ),
      );

      if (shouldDisable ?? false) {
        final isGranted = await locationService.isLocationPermissionGranted();
        setState(() {
          _locationTrackingEnabled = isGranted;
          if (!isGranted) { _currentPosition = null; }
        });

        if (isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location permission is still enabled. Toggle remains on.', style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: Colors.orangeAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location permission disabled successfully.', style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: secondaryColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        setState(() { _locationTrackingEnabled = true; });
      }
    }
  }

  Future<void> _updatePhoneAccess(bool enabled) async {
    final phoneService = context.read<PhoneService>();
    final colorScheme = Theme.of(context).colorScheme;

    if (enabled) {
      final hasPermission = await phoneService.requestPhonePermission();
      if (!hasPermission) {
        final shouldRetry = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Phone Access Required', style: GoogleFonts.poppins(color: colorScheme.onSurface)),
            content: Text(
              'Phone access is needed to detect your network provider. Please enable it in settings.',
              style: GoogleFonts.poppins(color: colorScheme.onSurface),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.poppins(color: colorScheme.onSurface.withOpacity(0.6))),
              ),
              TextButton(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                  Navigator.pop(context, true);
                },
                child: Text('Open Settings', style: GoogleFonts.poppins(color: secondaryColor)),
              ),
            ],
          ),
        );

        if (shouldRetry ?? false) {
          final newPermission = await Permission.phone.status;
          if (!newPermission.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Phone permission still denied. Please enable it in settings.', style: GoogleFonts.poppins(color: Colors.white)),
                backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
              ),
            );
            setState(() { _phoneAccessEnabled = false; });
            return;
          }
        } else {
          setState(() { _phoneAccessEnabled = false; });
          return;
        }
      }

      _simInfo = await phoneService.getSimInfo();
      if (_simInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get SIM info. Please ensure a SIM card is inserted.', style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
          ),
        );
        setState(() { _phoneAccessEnabled = false; });
      } else {
        setState(() { _phoneAccessEnabled = true; });
      }
    } else {
      _simInfo = null;
      setState(() { _phoneAccessEnabled = false; });
    }
  }

  Future<void> _logout() async {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
    
    final authState = await context.read<AuthBloc>().stream.firstWhere(
          (state) => state is NetpulseAuthInitial || state is NetpulseAuthFailure,
        );

    if (authState is NetpulseAuthFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: ${authState.message}', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    LinearGradient? buttonGradient,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: buttonGradient, 
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [colorScheme.background, primaryColor.withOpacity(0.7)]
                : [colorScheme.background, secondaryColor.withOpacity(0.3)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Align(
                //   alignment: Alignment.centerLeft,
                //   child: Padding(
                //     padding: const EdgeInsets.only(bottom: 24.0),
                //     child: Text(
                //       'Settings',
                //       style: GoogleFonts.poppins(
                //         fontSize: 32,
                //         fontWeight: FontWeight.bold,
                //         color: colorScheme.onBackground,
                //       ),
                //     ),
                //   ),
                // ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: colorScheme.onSurface.withOpacity(0.1)),
                SwitchListTile(
                  title: Text(
                    'Enable Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    _savePreferences();
                  },
                  activeColor: secondaryColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                ),
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Data Usage',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: colorScheme.onSurface.withOpacity(0.1)),
                SwitchListTile(
                  title: Text(
                    'Background Data',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  value: _backgroundDataEnabled,
                  onChanged: (value) {
                    setState(() {
                      _backgroundDataEnabled = value;
                    });
                    _savePreferences();
                  },
                  activeColor: secondaryColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                ),
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Privacy',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: colorScheme.onSurface.withOpacity(0.1)),
                SwitchListTile(
                  title: Text(
                    'Location Tracking',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  value: _locationTrackingEnabled,
                  onChanged: (value) async {
                    await _updateLocationTracking(value);
                    _savePreferences();
                  },
                  activeColor: secondaryColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                ),
                // if (_locationTrackingEnabled)
                //   Padding(
                //     padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                //     child: _currentPosition != null
                //         ? Column(
                //             crossAxisAlignment: CrossAxisAlignment.start,
                //             children: [
                //               Text(
                //                 'Latitude: ${_currentPosition!.latitude.toStringAsFixed(4)}',
                //                 style: GoogleFonts.poppins(
                //                   fontSize: 14,
                //                   color: colorScheme.onSurface.withOpacity(0.7),
                //                 ),
                //               ),
                //               Text(
                //                 'Longitude: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                //                 style: GoogleFonts.poppins(
                //                   fontSize: 14,
                //                   color: colorScheme.onSurface.withOpacity(0.7),
                //                 ),
                //               ),
                //             ],
                //           )
                //         : Text(
                //             'Location not available',
                //             style: GoogleFonts.poppins(
                //               fontSize: 14,
                //               color: colorScheme.error,
                //             ),
                //           ),
                //   ),
                SwitchListTile(
                  title: Text(
                    'Phone Access',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  value: _phoneAccessEnabled,
                  onChanged: (value) async {
                    await _updatePhoneAccess(value);
                    _savePreferences();
                  },
                  activeColor: secondaryColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                ),
                // if (_phoneAccessEnabled)
                //   Padding(
                //     padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                //     child: _simInfo != null
                //         ? Text(
                //             'Network Provider: ${_simInfo!.carrierName ?? 'N/A'}',
                //             style: GoogleFonts.poppins(
                //               fontSize: 14,
                //               color: colorScheme.onSurface.withOpacity(0.7),
                //             ),
                //           )
                //         : Text(
                //             'Network provider not available',
                //             style: GoogleFonts.poppins(
                //               fontSize: 14,
                //               color: colorScheme.error, // Use error color for "not available"
                //             ),
                //           ),
                //   ),
                const SizedBox(height: 20),

                // Preferences Section Title
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Preferences',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      //color: colorScheme.primary,
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: colorScheme.onSurface.withOpacity(0.1)),
                ListTile(
                  title: Text(
                    'Language',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  trailing: DropdownButtonHideUnderline( 
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      icon: Icon(Icons.arrow_drop_down_rounded, color: secondaryColor),
                      dropdownColor: colorScheme.surface,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                      items: _languages.map((String language) {
                        return DropdownMenuItem<String>(
                          value: language,
                          child: Text(language),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedLanguage = newValue;
                          });
                          _savePreferences(); 
                        }
                      },
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                ),
                ListTile(
                  title: Text(
                    'Theme',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTheme,
                      icon: Icon(Icons.brightness_medium_rounded, color: secondaryColor),
                      dropdownColor: colorScheme.surface,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                      items: _themes.map((String theme) {
                        return DropdownMenuItem<String>(
                          value: theme,
                          child: Text(theme),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTheme = newValue;
                          });
                          _savePreferences();
                        }
                      },
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                ),
                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0), 
                  child: SizedBox(
                    width: double.infinity,
                    child: _buildActionButton(
                      context: context,
                      label: 'Log Out',
                      icon: Icons.logout_rounded,
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: colorScheme.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text(
                              'Logout',
                              style: GoogleFonts.poppins(color: colorScheme.onSurface),
                            ),
                            content: Text(
                              'Are you sure you want to logout?',
                              style: GoogleFonts.poppins(color: colorScheme.onSurface),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    color: colorScheme.onSurface.withOpacity(0.6),
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
                            actionsAlignment: MainAxisAlignment.center,
                          ),
                        );
                        if (confirm == true) {
                          await _logout();
                        }
                      },
                      buttonGradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      textColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}