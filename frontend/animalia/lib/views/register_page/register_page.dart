import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:animalia/models/user/user_crud.dart';
import 'package:animalia/models/user/user_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  DateTime? _dateOfBirth;
  XFile? _imageFile;

  final UserCRUD _userCRUD = UserCRUD();

  Future<void> _register() async {
    final petName = _petNameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;

    final bool emailIsValid =
        RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);

    if (!emailIsValid) {
      _showError("Email inválido");
      return;
    }

    if (password.isEmpty ||
        petName.isEmpty ||
        _dateOfBirth == null ||
        _imageFile == null) {
      _showError(
          "Todos os campos devem estar preenchidos e a imagem selecionada");
      return;
    }

    final Uint8List petPictureBytes =
        await File(_imageFile!.path).readAsBytes();

    final String petPictureBase64 = base64Encode(petPictureBytes);

    final user = UserModel(
      userId: 0,
      petName: petName,
      petPictureBase64: petPictureBase64,
      description: '',
      dateOfBirth: _dateOfBirth!,
      email: email,
      password: password,
    );

    final Map<String, dynamic> result = await _userCRUD.register(user);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registro bem-sucedido!")),
      );
      Navigator.pop(context);
    } else {
      _showError(result['message']);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    setState(() {
      _imageFile = image;
    });
  }

  Future<void> _showImageSourceChoiceDialog(BuildContext context) async {
    await showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galeria'),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Câmera'),
                  onTap: () {
                    _pickImage(ImageSource.camera);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fundo preto
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Criar Conta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 80.0),
                  TextField(
                    controller: _petNameController,
                    decoration: InputDecoration(
                      labelText: "Nome do Pet",
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      fillColor: const Color.fromARGB(
                          255, 32, 32, 32), // Fundo cinza escuro
                      filled: true,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10.0),
                  GestureDetector(
                    onTap: () {
                      _showImageSourceChoiceDialog(context);
                    },
                    child: Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(
                            255, 32, 32, 32), // Fundo cinza escuro
                        border: Border.all(color: Colors.grey),
                        image: _imageFile != null
                            ? DecorationImage(
                                image: FileImage(File(_imageFile!.path)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _imageFile == null
                          ? const Icon(Icons.add_a_photo, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  // Campo Data de Nascimento
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: _dateOfBirth != null
                              ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!)
                              : 'Data de Nascimento',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          fillColor: const Color.fromARGB(
                              255, 32, 32, 32), // Fundo cinza escuro
                          filled: true,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[800]!),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  // Campos Email e Senha (atualizar estilo)
                  // Campos Email e Senha (atualizar estilo)
                  _buildTextField(
                    controller: _emailController,
                    label: "Email",
                  ),
                  const SizedBox(height: 10.0),
                  _buildTextField(
                    controller: _passwordController,
                    label: "Senha",
                    obscureText: true,
                  ),
                  const SizedBox(height: 20.0),
                  const SizedBox(height: 20.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _register(),
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.white),
                        foregroundColor:
                            MaterialStateProperty.all(Colors.black),
                      ),
                      child: const Text(
                        "Registrar",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  bool obscureText = false,
}) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400]),
      fillColor: const Color.fromARGB(255, 32, 32, 32), // Fundo cinza escuro
      filled: true,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[800]!),
      ),
    ),
    style: const TextStyle(color: Colors.white),
    obscureText: obscureText,
  );
}
