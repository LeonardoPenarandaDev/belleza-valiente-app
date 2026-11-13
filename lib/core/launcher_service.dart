import 'package:url_launcher/url_launcher.dart';

class LauncherService {
  /// Abre un chat directo de WhatsApp con mensaje predeterminado
  static Future<void> abrirWhatsApp({
    required String telefono,
    String mensaje = '',
  }) async {
    final numeroLimpio = telefono.replaceAll(RegExp(r'\D'), '');
    final telefonoFinal = numeroLimpio.startsWith('57') 
        ? numeroLimpio 
        : '57$numeroLimpio';

    final uri = Uri.parse(
      'https://wa.me/$telefonoFinal?text=${Uri.encodeComponent(mensaje)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo abrir WhatsApp para el número: $telefonoFinal';
    }
  }

  /// Abre cualquier URL externa (navegador web)
  static Future<void> abrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo abrir la URL: $url';
    }
  }
}