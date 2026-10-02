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

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VacantesProvider>();
    final vacantesConUbicacion = vp.filtered
        .where((v) => v.latitud != null && v.longitud != null)
        .toList();

    // Centro por defecto (puedes ajustar a la ciudad por defecto del backend)
    var center = const LatLng(4.6097, -74.0817); // Bogotá, Colombia por defecto
    if (widget.focusedVacante != null &&
        widget.focusedVacante!.latitud != null &&
        widget.focusedVacante!.longitud != null) {
      center = LatLng(
        widget.focusedVacante!.latitud!,
        widget.focusedVacante!.longitud!,
      );
    } else if (vacantesConUbicacion.isNotEmpty) {
      center = LatLng(
        vacantesConUbicacion.first.latitud!,
        vacantesConUbicacion.first.longitud!,
      );
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
          initialZoom: 12.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'co.talentmatch.talentmatch',
          ),
          MarkerLayer(
            markers: vacantesConUbicacion.map((vacante) {
              return Marker(
                point: LatLng(vacante.latitud!, vacante.longitud!),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    _showJobPreview(context, vacante);
                  },
                  child: const Icon(
                    Icons.location_on,
                    color: kBlue,
                    size: 40,
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
