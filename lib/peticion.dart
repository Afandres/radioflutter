import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Para formatear la hora
import 'package:shared_preferences/shared_preferences.dart';

class PeticionFormScreen extends StatefulWidget {
  @override
  _PeticionFormScreenState createState() => _PeticionFormScreenState();
}

class _PeticionFormScreenState extends State<PeticionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();

  bool _isSubmitting = false;
  String _userName = 'Anonimo'; // Por defecto

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('username') ?? 'Anonimo';
    setState(() {
      _userName = user;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final now = DateTime.now().toLocal(); // Hora local de Colombia
    final horaFormateada = DateFormat.Hms().format(now); // '16:25:30'
    final timestamp = now.millisecondsSinceEpoch ~/ 1000; // En segundos

    final url = Uri.parse('http://vps-fd00e51b.vps.ovh.ca/api/request');

    final response = await http.post(
      url,
      body: {
        'name': _userName,
        'title': _titleController.text,
        'artist': _artistController.text,
        'hora': horaFormateada,
        'timestamp': timestamp.toString(),
      },
    );

    setState(() => _isSubmitting = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Petición enviada')),
      );
      _formKey.currentState!.reset();
      _titleController.clear();
      _artistController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Petición de Canción"),
        backgroundColor: Colors.green.shade900,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Título de la canción"),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _artistController,
                decoration: InputDecoration(labelText: "Artista"),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? CircularProgressIndicator()
                    : Text("Enviar"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
