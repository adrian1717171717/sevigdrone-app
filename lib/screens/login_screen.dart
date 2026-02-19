import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

// --- CONSTANTS & STYLES (pueden moverse a un archivo de tema) ---
const Color kGoldColor = Color(0xFFD4AF37);
const Color kBackgroundColor = Color(0xFF121212);
const Color kInputFillColor = Color(0xFF1E1E1E);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  String? _selectedGender;
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isLoading = true);
    
    // Usamos el AuthService a través de Provider
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      if (_isLogin) {
        await authService.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          gender: _selectedGender!,
        );
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Cuenta creada exitosamente. Iniciando..."), backgroundColor: Colors.green)
           );
        }
      }
      // La navegación se gestiona automáticamente por el `authStateChanges` listener en AuthService (via AuthWrapper)
    } catch (e) {
      _showError(e.toString()); // Mostramos el error que nos devuelve el servicio
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _toggleFormType() {
    _formKey.currentState?.reset();
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _LogoAndTitle(),
                const SizedBox(height: 40),
                
                if (!_isLogin)
                  _RegistrationFields(
                    nameController: _nameController,
                    selectedGender: _selectedGender,
                    onGenderChanged: (val) => setState(() => _selectedGender = val),
                  ),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Correo Electrónico",
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.email_outlined, color: kGoldColor),
                    filled: true,
                    fillColor: kInputFillColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent), borderRadius: BorderRadius.all(Radius.circular(10))),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kGoldColor), borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Por favor ingrese un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isPasswordObscured,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.lock_outline, color: kGoldColor),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                    ),
                    filled: true,
                    fillColor: kInputFillColor,
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent), borderRadius: BorderRadius.all(Radius.circular(10))),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: kGoldColor), borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGoldColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(
                            _isLogin ? "INICIAR SESIÓN" : "REGISTRARSE",
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _toggleFormType,
                  child: Text(
                    _isLogin ? "¿No tienes cuenta? Regístrate" : "¿Ya tienes cuenta? Inicia sesión",
                    style: const TextStyle(color: kGoldColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoAndTitle extends StatelessWidget {
  const _LogoAndTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Placeholder para logo si no existe el asset
        Image.asset(
          'assets/images/logo.png',
          height: 120,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.flight_takeoff, size: 100, color: kGoldColor),
        ),
        const SizedBox(height: 20),
        const Text(
          "SEVIGDRONE",
          style: TextStyle(
            color: kGoldColor,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "ESCUELA DE PILOTOS DE DRONES",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            letterSpacing: 5,
          ),
        ),
      ],
    );
  }
}

class _RegistrationFields extends StatelessWidget {
  final TextEditingController nameController;
  final String? selectedGender;
  final ValueChanged<String?> onGenderChanged;

  const _RegistrationFields({
    required this.nameController,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: "Nombre Completo",
            labelStyle: TextStyle(color: Colors.grey),
            prefixIcon: Icon(Icons.person_outline, color: kGoldColor),
            filled: true,
            fillColor: kInputFillColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent), borderRadius: BorderRadius.all(Radius.circular(10))),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kGoldColor), borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese su nombre';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: selectedGender,
          dropdownColor: kInputFillColor,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Género",
            labelStyle: TextStyle(color: Colors.grey),
            prefixIcon: Icon(Icons.wc, color: kGoldColor),
            filled: true,
            fillColor: kInputFillColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent), borderRadius: BorderRadius.all(Radius.circular(10))),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kGoldColor), borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
          items: const [
            DropdownMenuItem(value: 'Masculino', child: Text("Masculino")),
            DropdownMenuItem(value: 'Femenino', child: Text("Femenino")),
            DropdownMenuItem(value: 'Otro', child: Text("Otro")),
          ],
          onChanged: onGenderChanged,
          validator: (value) => value == null ? 'Seleccione un género' : null,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
