/// Utilidades para comparar lo que la persona dice con los datos de la foto.
library;

const _acentos = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'ó': 'o', 'ò': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u',
};

/// Minúsculas, sin tildes ni signos, con un solo espacio entre palabras.
String normalizar(String texto) {
  final salida = StringBuffer();
  for (final letra in texto.toLowerCase().split('')) {
    final simple = _acentos[letra] ?? letra;
    salida.write(RegExp(r'[a-zñ0-9]').hasMatch(simple) ? simple : ' ');
  }
  return salida.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

const _vacias = {
  'el', 'la', 'los', 'las', 'de', 'del', 'en', 'un', 'una', 'y', 'a', 'o',
  'mi', 'tu', 'su', 'mis', 'tus', 'con', 'que', 'es', 'fue', 'al', 'lo',
  'por', 'para', 'se', 'era', 'son', 'esta', 'estan', 'creo', 'ser', 'ese',
  'esa', 'eso', 'muy', 'mas', 'como', 'me', 'te', 'le', 'ahi', 'alli',
};

/// Palabras con significado de un texto, ya normalizadas.
List<String> palabrasClave(String texto) => normalizar(texto)
    .split(' ')
    .where((p) => p.length > 1 && !_vacias.contains(p))
    .toList();

/// Distancia de edición entre dos palabras.
int distancia(String a, String b) {
  if (a == b) return 0;
  var previa = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 0; i < a.length; i++) {
    final fila = [i + 1];
    for (var j = 0; j < b.length; j++) {
      final costo = a[i] == b[j] ? 0 : 1;
      fila.add([fila[j] + 1, previa[j + 1] + 1, previa[j] + costo]
          .reduce((x, y) => x < y ? x : y));
    }
    previa = fila;
  }
  return previa.last;
}

/// Dos palabras se parecen si son iguales o difieren en muy pocas letras.
/// Tolera errores pequeños del reconocimiento de voz.
bool seParecen(String a, String b) {
  if (a == b) return true;
  // Los números (años, fechas) deben coincidir exactos.
  if (RegExp(r'[0-9]').hasMatch(a) || RegExp(r'[0-9]').hasMatch(b)) return false;
  final largo = a.length < b.length ? a.length : b.length;
  if (largo < 4) return false;
  return distancia(a, b) <= (largo >= 7 ? 2 : 1);
}

/// Indica si entre las palabras dichas hay alguna parecida a [clave].
bool dijo(List<String> dichas, String clave) => dichas.any((d) => seParecen(d, clave));

/// Separa un texto en frases para leerlas y mostrarlas una por una.
List<String> partirEnFrases(String texto) {
  final frases = <String>[];
  final actual = StringBuffer();
  for (final letra in texto.split('')) {
    actual.write(letra);
    if ('.?!…'.contains(letra)) {
      final frase = actual.toString().trim();
      if (frase.length > 1) frases.add(frase);
      actual.clear();
    }
  }
  final resto = actual.toString().trim();
  if (resto.isNotEmpty) frases.add(resto);
  return frases;
}
