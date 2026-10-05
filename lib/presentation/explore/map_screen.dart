import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/vacante.dart';
import '../job_detail/job_detail_screen.dart';
import '../shared/providers/vacantes_provider.dart';

class MapScreen extends StatefulWidget {
  final Vacante? focusedVacante;
  const MapScreen({super.key, this.focusedVacante});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Si viene una vacante enfocada, mostramos su popup después de un pequeño delay
    if (widget.focusedVacante != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _showJobPreview(context, widget.focusedVacante!);
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Helper para resolver ubicación si vienen en null
  LatLng _getCoordinates(Vacante vacante) {
    if (vacante.latitud != null && vacante.longitud != null) {
      return LatLng(vacante.latitud!, vacante.longitud!);
    }
    final loc = vacante.ubicacion.toLowerCase();
    if (loc.contains('fusagasugá') || loc.contains('fusagasuga')) return const LatLng(4.33646, -74.36378);
    if (loc.contains('bogotá') || loc.contains('bogota')) return const LatLng(4.60971, -74.08175);
    if (loc.contains('medellín') || loc.contains('medellin')) return const LatLng(6.2442, -75.5812);
    if (loc.contains('cali')) return const LatLng(3.4516, -76.5320);
    if (loc.contains('barranquilla')) return const LatLng(10.9639, -74.7964);
    if (loc.contains('bucaramanga')) return const LatLng(7.1254, -73.1198);
    
    return const LatLng(4.6097, -74.0817); // Bogotá por defecto
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VacantesProvider>();
    
    // Filtrar remoto y resolver coordenadas para todas las demás
    final vacantesEnMapa = vp.filtered
        .where((v) => v.ubicacion.toLowerCase() != 'remoto')
        .toList();

    var center = const LatLng(4.6097, -74.0817); 
    
    if (widget.focusedVacante != null && widget.focusedVacante!.ubicacion.toLowerCase() != 'remoto') {
      center = _getCoordinates(widget.focusedVacante!);
    } else if (vacantesEnMapa.isNotEmpty) {
      center = _getCoordinates(vacantesEnMapa.first);
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kNavy),
        title: const Text('Mapa de Vacantes',
            style: TextStyle(color: kNavy, fontWeight: FontWeight.w800)),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'co.talentmatch.talentmatch',
          ),
          MarkerLayer(
            markers: vacantesEnMapa.map((vacante) {
              final pos = _getCoordinates(vacante);
              final isFocused = widget.focusedVacante?.id == vacante.id;
              return Marker(
                point: pos,
                width: isFocused ? 50 : 40,
                height: isFocused ? 50 : 40,
                child: GestureDetector(
                  onTap: () {
                    _showJobPreview(context, vacante);
                  },
                  child: Icon(
                    Icons.location_on,
                    color: isFocused ? Colors.red : kBlue,
                    size: isFocused ? 50 : 40,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showJobPreview(BuildContext context, Vacante vacante) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vacante.titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                vacante.ubicacion,
                style: const TextStyle(color: kMuted, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                vacante.salarioDisplay,
                style: const TextStyle(
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobDetailScreen(vacante: vacante),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: kBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Ver Detalles'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
