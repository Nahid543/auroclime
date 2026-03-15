import 'package:flutter/material.dart';
import 'dart:async';
import '../../domain/search_service.dart';
import '../../domain/saved_locations_service.dart';
import '../../data/geocoding_api.dart';

class SearchScreen extends StatefulWidget {
  final Function(SavedLocation)? onLocationSelected;

  const SearchScreen({super.key, this.onLocationSelected});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchService = SearchService();
  final _savedLocationsService = SavedLocationsService();
  final _searchController = TextEditingController();
  
  List<LocationResult> _results = [];
  List<SavedLocation> _savedLocs = [];
  bool _isSearching = false;
  String? _error;

  Timer? _debounce;
  
  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
  }

  Future<void> _loadSavedLocations() async {
    final locs = await _savedLocationsService.getSavedLocations();
    if (mounted) {
      setState(() {
        _savedLocs = locs;
      });
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.trim().isEmpty) {
      if (mounted) setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() {
        _isSearching = true;
        _error = null;
      });
      
      try {
        final results = await _searchService.searchLocations(query);
        if (mounted) {
          setState(() {
            _results = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isSearching = false;
          });
        }
      }
    });
  }

  Future<void> _addLocation(LocationResult location) async {
    Navigator.of(context).focusNode.unfocus();
    try {
      await _savedLocationsService.saveLocation(
        SavedLocation(
          latitude: location.latitude,
          longitude: location.longitude,
          name: location.name,
        )
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${location.name} added to locations'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _results = [];
      });
      _loadSavedLocations();
      
      // Notify parent to switch tabs and select location
      widget.onLocationSelected?.call(SavedLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        name: location.name,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to add location'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removeSavedLocation(SavedLocation location) async {
    try {
      await _savedLocationsService.deleteLocation(location);
      _loadSavedLocations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${location.name} removed'),
            backgroundColor: Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove location')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Manage Locations',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search for a city...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isSearching)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else if (_searchController.text.isNotEmpty && _results.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No locations found for "${_searchController.text}"',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                  ),
                )
              else if (_results.isNotEmpty)
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: _results.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.white.withOpacity(0.1),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return ListTile(
                        title: Text(
                          result.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          [result.admin1, result.country]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(', '),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF38BDF8)),
                          onPressed: () => _addLocation(result),
                        ),
                        onTap: () => _addLocation(result),
                      );
                    },
                  ),
                )
              else if (_savedLocs.isNotEmpty)
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: _savedLocs.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.white.withOpacity(0.05),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final loc = _savedLocs[index];
                      return ListTile(
                        leading: Icon(
                          loc.isCurrent ? Icons.my_location : Icons.location_on_outlined,
                          color: loc.isCurrent ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                        ),
                        title: Text(
                          loc.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: loc.isCurrent 
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.white38),
                                onPressed: () => _removeSavedLocation(loc),
                              ),
                        onTap: () {
                          widget.onLocationSelected?.call(loc);
                        },
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 64,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Search to add new saved locations',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(height: 80), // offset for nav bar
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
