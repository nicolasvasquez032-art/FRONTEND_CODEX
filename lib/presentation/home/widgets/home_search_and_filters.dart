import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Barra de búsqueda redondeada con botón azul de filtros idéntica al diseño de Figma.
class HomeSearchBar extends StatelessWidget {
  final VoidCallback onTap;
  final bool isSpanish;

  const HomeSearchBar({
    super.key,
    required this.onTap,
    required this.isSpanish,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.only(left: 16, right: 6),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isSpanish
                    ? 'Cargo, habilidad o empresa...'
                    : 'Job title, skill or company...',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de Chips de filtro rápido horizontalmente desplazables:
/// - Chip "Remoto" (con checkmark dinámico)
/// - Chip selector de "Categoría / Tecnología"
/// - Chip selector de "Ubicación / Colombia"
class HomeFilterChipsRow extends StatelessWidget {
  final bool isSpanish;
  final bool filterRemote;
  final String? selectedCategory;
  final String? selectedLocation;
  final ValueChanged<bool> onRemoteChanged;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<String?> onLocationSelected;

  const HomeFilterChipsRow({
    super.key,
    required this.isSpanish,
    required this.filterRemote,
    required this.selectedCategory,
    required this.selectedLocation,
    required this.onRemoteChanged,
    required this.onCategorySelected,
    required this.onLocationSelected,
  });

  void _openCategorySelector(BuildContext context) {
    HapticFeedback.lightImpact();
    final categories = isSpanish
        ? ['Todas', 'Tecnología', 'Backend', 'Frontend', 'Mobile', 'DevOps', 'Diseño']
        : ['All', 'Technology', 'Backend', 'Frontend', 'Mobile', 'DevOps', 'Design'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isSpanish ? 'Filtrar por Categoría' : 'Filter by Category',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                ...categories.map((cat) {
                  final isAll = cat == 'Todas' || cat == 'All';
                  final isSelected = isAll
                      ? selectedCategory == null
                      : selectedCategory == cat;
                  return ListTile(
                    title: Text(
                      cat,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFF2563EB))
                        : null,
                    onTap: () {
                      onCategorySelected(isAll ? null : cat);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openLocationSelector(BuildContext context) {
    HapticFeedback.lightImpact();
    final locations = isSpanish
        ? ['Todas', 'Colombia', 'Bogotá', 'Medellín', 'Cali', 'Remoto Global']
        : ['All', 'Colombia', 'Bogotá', 'Medellín', 'Cali', 'Global Remote'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isSpanish ? 'Filtrar por Ubicación' : 'Filter by Location',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                ...locations.map((loc) {
                  final isAll = loc == 'Todas' || loc == 'All';
                  final isSelected = isAll
                      ? selectedLocation == null
                      : selectedLocation == loc;
                  return ListTile(
                    title: Text(
                      loc,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFF2563EB))
                        : null,
                    onTap: () {
                      onLocationSelected(isAll ? null : loc);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // 1. Chip Remoto (Activo / Desactivable)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onRemoteChanged(!filterRemote);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: filterRemote ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: filterRemote
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: filterRemote
                        ? const Color(0xFF2563EB).withValues(alpha: 0.25)
                        : const Color(0xFF1E293B).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filterRemote) ...[
                    const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    isSpanish ? 'Remoto' : 'Remote',
                    style: TextStyle(
                      color: filterRemote
                          ? Colors.white
                          : const Color(0xFF475569),
                      fontSize: 13,
                      fontWeight:
                          filterRemote ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 2. Chip Categoría / Tecnología
          DropdownChip(
            label: selectedCategory ??
                (isSpanish ? 'Tecnología' : 'Technology'),
            isSelected: selectedCategory != null,
            onTap: () => _openCategorySelector(context),
          ),
          const SizedBox(width: 10),

          // 3. Chip Ubicación / Colombia
          DropdownChip(
            label: selectedLocation ?? 'Colombia',
            isSelected: selectedLocation != null,
            onTap: () => _openLocationSelector(context),
          ),
        ],
      ),
    );
  }
}

/// Chip desplegable con chevron (Tecnología ⌵, Colombia ⌵)
class DropdownChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const DropdownChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF475569),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF64748B),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
