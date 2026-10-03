import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../shared/providers/vacantes_provider.dart';
import '../shared/widgets/colombia_location_picker.dart';
import 'package:flutter/services.dart';

class PublicarVacanteScreen extends StatefulWidget {
  const PublicarVacanteScreen({super.key});

  @override
  State<PublicarVacanteScreen> createState() => _PublicarVacanteScreenState();
}

class _PublicarVacanteScreenState extends State<PublicarVacanteScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _requisitosCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _salarioMinCtrl = TextEditingController();
  final _salarioMaxCtrl = TextEditingController();
  
  String _categoriaSeleccionada = 'Tecnología';
  String _monedaSeleccionada = 'COP';
  
  final List<String> _categorias = [
    'Tecnología', 'Diseño', 'Marketing', 'Ventas', 'Recursos Humanos', 'Finanzas', 'Otro'
  ];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _requisitosCtrl.dispose();
    _ubicacionCtrl.dispose();
    _salarioMinCtrl.dispose();
    _salarioMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<VacantesProvider>();
    final descripcionFinal = _monedaSeleccionada == 'COP' 
        ? _descripcionCtrl.text.trim() 
        : '${_descripcionCtrl.text.trim()}\n\n*Salario expresado en $_monedaSeleccionada*';

    // El backend espera una lista de strings para requisitos
    final requisitosList = [_requisitosCtrl.text.trim()];

    final success = await provider.publicarVacante(
      titulo: _tituloCtrl.text.trim(),
      descripcion: descripcionFinal,
      requisitos: requisitosList,
      ubicacion: _ubicacionCtrl.text.trim(),
      categoria: _categoriaSeleccionada,
      salarioMin: double.tryParse(_salarioMinCtrl.text.replaceAll('.', '')),
      salarioMax: double.tryParse(_salarioMaxCtrl.text.replaceAll('.', '')),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Vacante publicada exitosamente!'), backgroundColor: Colors.green),
        );
        // Limpiar el formulario
        _formKey.currentState!.reset();
        _tituloCtrl.clear();
        _descripcionCtrl.clear();
        _requisitosCtrl.clear();
        _ubicacionCtrl.clear();
        _salarioMinCtrl.clear();
        _salarioMaxCtrl.clear();
        setState(() {
          _categoriaSeleccionada = 'Tecnología';
          _monedaSeleccionada = 'COP';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Error al publicar la vacante')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<VacantesProvider>().loadingPub;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Crear nueva vacante', style: TextStyle(color: kNavy, fontWeight: FontWeight.w800, fontSize: 20)),
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Atrae al mejor talento completando este formulario con los detalles de la oferta.', style: TextStyle(color: kMuted, fontSize: 14)),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Información Principal'),
                _buildField(
                  controller: _tituloCtrl,
                  label: 'Título de la vacante',
                  hint: 'Ej. Desarrollador Flutter Senior',
                  icon: Icons.work_outline,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                
                _buildDropdown(),
                const SizedBox(height: 16),
                
                _buildField(
                  controller: _ubicacionCtrl,
                  label: 'Ubicación',
                  hint: 'Selecciona la ciudad',
                  icon: Icons.location_on_outlined,
                  readOnly: true,
                  onTap: () async {
                    final result = await showColombiaLocationPicker(context);
                    if (result != null) {
                      _ubicacionCtrl.text = result;
                    }
                  },
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Descripción del Puesto'),
                _buildField(
                  controller: _descripcionCtrl,
                  label: 'Descripción General',
                  hint: 'Explica las responsabilidades y objetivos del rol...',
                  icon: Icons.description_outlined,
                  maxLines: 4,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                
                _buildField(
                  controller: _requisitosCtrl,
                  label: 'Requisitos técnicos y habilidades',
                  hint: 'Menciona lenguajes, años de experiencia, etc.',
                  icon: Icons.list_alt_outlined,
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Compensación (Opcional)'),
                _buildCurrencyDropdown(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _salarioMinCtrl,
                        label: 'Salario Mínimo ($_monedaSeleccionada)',
                        hint: '0',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        inputFormatters: [_CurrencyInputFormatter()],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildField(
                        controller: _salarioMaxCtrl,
                        label: 'Salario Máximo ($_monedaSeleccionada)',
                        hint: '0',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        inputFormatters: [_CurrencyInputFormatter()],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: loading ? null : kButtonGradient,
                      color: loading ? kLine : null,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: loading ? [] : [BoxShadow(color: kBlue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      ),
                      onPressed: loading ? null : _submit,
                      child: loading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: kBlue, strokeWidth: 2))
                        : const Text('Publicar Vacante', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(color: kNavy, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: maxLines == 1 ? Icon(icon, color: kMuted, size: 20) : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kLine)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kLine)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBlue, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Categoría', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _categoriaSeleccionada,
          icon: const Icon(Icons.keyboard_arrow_down, color: kMuted),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.category_outlined, color: kMuted, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kLine)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kLine)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBlue, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: _categorias.map((String cat) {
            return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(color: kNavy, fontSize: 14)));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _categoriaSeleccionada = val);
          },
        ),
      ],
    );
  }

  Widget _buildCurrencyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Moneda', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _monedaSeleccionada,
          icon: const Icon(Icons.keyboard_arrow_down, color: kMuted),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.monetization_on_outlined, color: kMuted, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kLine)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kLine)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBlue, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: ['COP', 'USD', 'EUR', 'MXN'].map((String currency) {
            return DropdownMenuItem(value: currency, child: Text(currency, style: const TextStyle(color: kNavy, fontSize: 14, fontWeight: FontWeight.w600)));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _monedaSeleccionada = val);
          },
        ),
      ],
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Remueve todo lo que no sea número
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    int? value = int.tryParse(newText);
    
    if (value == null) return oldValue;

    // Agrega un punto cada 3 dígitos
    final formattedValue = value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.'
    );

    return newValue.copyWith(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}
