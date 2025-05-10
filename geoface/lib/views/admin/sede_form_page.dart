// views/admin/sede_form_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/sede_controller.dart';
import '../../models/sede.dart';
import '../../utils/validators.dart';

class SedeFormPage extends StatefulWidget {
  final Sede? sede;

  const SedeFormPage({Key? key, this.sede}) : super(key: key);

  @override
  State<SedeFormPage> createState() => _SedeFormPageState();
}

class _SedeFormPageState extends State<SedeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _latitudController = TextEditingController();
  final _longitudController = TextEditingController();
  final _radioPermitidoController = TextEditingController();
  bool _activa = true;

  bool get _isEditing => widget.sede != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nombreController.text = widget.sede!.nombre;
      _direccionController.text = widget.sede!.direccion;
      _latitudController.text = widget.sede!.latitud.toString();
      _longitudController.text = widget.sede!.longitud.toString();
      _radioPermitidoController.text = widget.sede!.radioPermitido.toString();
      _activa = widget.sede!.activa;
    } else {
      _radioPermitidoController.text = '100'; // Valor por defecto
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    _radioPermitidoController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final sedeController = Provider.of<SedeController>(context, listen: false);
      
      bool success;
      
      if (_isEditing) {
        success = await sedeController.updateSede(
          id: widget.sede!.id,
          nombre: _nombreController.text.trim(),
          direccion: _direccionController.text.trim(),
          latitud: double.parse(_latitudController.text.trim()),
          longitud: double.parse(_longitudController.text.trim()),
          radioPermitido: int.parse(_radioPermitidoController.text.trim()),
          activa: _activa,
        );
      } else {
        success = await sedeController.addSede(
          nombre: _nombreController.text.trim(),
          direccion: _direccionController.text.trim(),
          latitud: double.parse(_latitudController.text.trim()),
          longitud: double.parse(_longitudController.text.trim()),
          radioPermitido: int.parse(_radioPermitidoController.text.trim()),
        );
      }
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Sede actualizada correctamente.' 
                : 'Sede agregada correctamente.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Sede' : 'Nueva Sede'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Validators.validateRequired(value, 'Nombre'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Validators.validateRequired(value, 'Dirección'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudController,
                      decoration: const InputDecoration(
                        labelText: 'Latitud',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => Validators.validateRequired(value, 'Latitud'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudController,
                      decoration: const InputDecoration(
                        labelText: 'Longitud',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => Validators.validateRequired(value, 'Longitud'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _radioPermitidoController,
                decoration: const InputDecoration(
                  labelText: 'Radio permitido (metros)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => Validators.validateRequired(value, 'Radio permitido'),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Sede activa'),
                  value: _activa,
                  onChanged: (value) {
                    setState(() {
                      _activa = value;
                    });
                  },
                ),
              ],
              const SizedBox(height: 24),
              Consumer<SedeController>(
                builder: (context, controller, _) {
                  return ElevatedButton(
                    onPressed: controller.loading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: controller.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(_isEditing ? 'Actualizar Sede' : 'Agregar Sede'),
                  );
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}