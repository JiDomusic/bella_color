/// Formato de precio argentino: 25.000, 100.000, 1.327
String formatPrecio(double valor) {
  final entero = valor.truncate();
  final decimal = valor - entero;
  final str = entero.toString();
  final buf = StringBuffer();
  final len = str.length;
  for (int i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write('.');
    buf.write(str[i]);
  }
  if (decimal > 0.005) {
    final dec = (decimal * 100).round().toString().padLeft(2, '0');
    buf.write(',$dec');
  }
  return buf.toString();
}

/// Formato con signo $
String formatPrecioConSigno(double valor) => '\$${formatPrecio(valor)}';
