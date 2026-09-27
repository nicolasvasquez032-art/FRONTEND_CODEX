import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/colombia_data.dart';

Future<String?> showColombiaLocationPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _LocationPickerSheet(),
  );
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet();

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedDepartment;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine what list to show
    List<String> items = [];
    if (_selectedDepartment == null) {
      items = colombiaLocations.keys.toList();
    } else {
      items = colombiaLocations[_selectedDepartment] ?? [];
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      items = items
          .where((i) => i.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title & Back button if department is selected
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                if (_selectedDepartment != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: kNavy),
                    onPressed: () {
                      setState(() {
                        _selectedDepartment = null;
                        _searchCtrl.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                else
                  const SizedBox(width: 48), // Spacer to balance title
                  
                Expanded(
                  child: Text(
                    _selectedDepartment == null ? 'Selecciona tu Departamento' : 'Ciudad en $_selectedDepartment',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy),
                  ),
                ),
                
                const SizedBox(width: 48), // Spacer to balance title
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search, color: kMuted),
                filled: true,
                fillColor: kBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // List of items
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: kLine),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  title: Text(item, style: const TextStyle(fontSize: 16, color: kText)),
                  trailing: Icon(
                    _selectedDepartment == null ? Icons.chevron_right : Icons.check_circle_outline,
                    color: kBlue,
                    size: 20,
                  ),
                  onTap: () {
                    if (_selectedDepartment == null) {
                      setState(() {
                        _selectedDepartment = item;
                        _searchCtrl.clear();
                        _searchQuery = '';
                      });
                    } else {
                      // Final selection
                      Navigator.pop(context, '$item, $_selectedDepartment');
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
