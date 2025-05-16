class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }
    
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Ingrese un email válido';
    }
    
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    
    return null;
  }
  
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    
    return null;
  }
  
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }
    
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    
    return null;
  }
  
  static String? validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'El código es requerido';
    }
    
    final codeRegExp = RegExp(r'^[A-Za-z0-9]{3,10}$');
    if (!codeRegExp.hasMatch(value)) {
      return 'El código debe tener entre 3 y 10 caracteres alfanuméricos';
    }
    
    return null;
  }
  
  static String? validateNote(String? value) {
    if (value == null || value.isEmpty) {
      return null; // La nota no es obligatoria
    }
    
    final double? note = double.tryParse(value);
    if (note == null) {
      return 'Ingrese un valor numérico';
    }
    
    if (note < 0 || note > 100) {
      return 'La nota debe estar entre 0 y 100';
    }
    
    return null;
  }
  
  static String? validateObservation(String? value) {
    if (value == null || value.isEmpty) {
      return null; // La observación no es obligatoria
    }
    
    if (value.length > 200) {
      return 'La observación no debe exceder los 200 caracteres';
    }
    
    return null;
  }
}