import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Importa SharedPreferences

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
    final user = prefs.getString('username') ??
        'Anonimo'; // Cambia 'username' si usas otra clave
    setState(() {
      _userName = user;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final url = Uri.parse('http://192.168.100.147:8081/api/request');

    final response = await http.post(
      url,
      body: {
        'name': _userName, // Aquí enviamos el usuario guardado
        'title': _titleController.text,
        'artist': _artistController.text,
      },
    );

    setState(() => _isSubmitting = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Petición enviada')));
      _formKey.currentState!.reset();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al enviar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Petición de Canción"),
          backgroundColor: Colors.green.shade900),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // El campo de nombre se eliminó
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
