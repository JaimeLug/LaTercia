import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/products_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/print_service.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/admin_panel.dart';
import 'backups_screen.dart';
import 'botonera_screen.dart';
import 'delivery_zones_screen.dart';
import 'kiosk_screen.dart';
import 'monitores_screen.dart';

/// Metadatos de cada categoría de Configuración, para la vista de tarjetas de
/// entrada — reemplaza la única página larga de scroll infinito por un menú
/// tipo Ajustes de Windows/macOS: entras, ves temas, tocas uno, ves solo eso.
///
/// Reestructuración de navegación 2026-07-22: de 12 a 17 cards. Las últimas
/// 5 (envio/botonera/quiosco/monitores/backups) vivían como items propios
/// del sidebar — se movieron aquí porque son "ajustar una vez" del equipo/
/// negocio, no trabajo operativo del día a día (a diferencia de Órdenes,
/// Reportes, Facturación, que sí se quedaron en el sidebar). Se renderizan
/// distinto a las primeras 12: en vez del panel de campos + "Guardar
/// cambios" (`_categoryFields`), embeben su pantalla completa de siempre
/// (ver `_screenCategoryKeys` y `_buildScreenCategory`).
typedef _SettingsCategory = ({
  String key,
  IconData icon,
  String title,
  String subtitle,
});

const _settingsCategories = <_SettingsCategory>[
  (
    key: 'negocio',
    icon: Icons.storefront_outlined,
    title: 'Negocio',
    subtitle: 'Nombre, slogan y logo'
  ),
  (
    key: 'apariencia',
    icon: Icons.palette_outlined,
    title: 'Apariencia',
    subtitle: 'Colores de la marca'
  ),
  (
    key: 'pos',
    icon: Icons.point_of_sale_outlined,
    title: 'POS',
    subtitle: 'Tipo de orden, cliente, mesas'
  ),
  (
    key: 'cocina',
    icon: Icons.soup_kitchen_outlined,
    title: 'Cocina (KDS)',
    subtitle: 'Sonido y alertas de tiempo'
  ),
  (
    key: 'caja',
    icon: Icons.lock_outline,
    title: 'Caja y seguridad',
    subtitle: 'Turnos, auto-bloqueo'
  ),
  (
    key: 'impresion',
    icon: Icons.print_outlined,
    title: 'Impresión y gaveta',
    subtitle: 'Tickets, impresora, gaveta'
  ),
  (
    key: 'impuestos',
    icon: Icons.receipt_long_outlined,
    title: 'Impuestos',
    subtitle: 'IVA y su despliegue'
  ),
  (
    key: 'ventas',
    icon: Icons.payments_outlined,
    title: 'Ventas',
    subtitle: 'Propinas'
  ),
  (
    key: 'moneda',
    icon: Icons.attach_money,
    title: 'Moneda',
    subtitle: 'Símbolo y decimales'
  ),
  (
    key: 'ticket',
    icon: Icons.receipt_outlined,
    title: 'Ticket / Recibo',
    subtitle: 'Pie de página y detalles'
  ),
  (
    key: 'facturacion',
    icon: Icons.request_quote_outlined,
    title: 'Facturación (emisor)',
    subtitle: 'Datos fiscales del negocio'
  ),
  (
    key: 'fidelizacion',
    icon: Icons.card_giftcard_outlined,
    title: 'Fidelización',
    subtitle: 'Sellos o puntos por cliente'
  ),
  (
    key: 'envio',
    icon: Icons.delivery_dining_outlined,
    title: 'Envío',
    subtitle: 'Zonas y cargo de entrega'
  ),
  (
    key: 'botonera',
    icon: Icons.gamepad_outlined,
    title: 'Botonera',
    subtitle: 'Botonera física de Cocina (ESP32)'
  ),
  (
    key: 'quiosco',
    icon: Icons.dvr_outlined,
    title: 'Quiosco',
    subtitle: 'Equipo, actualizaciones y energía'
  ),
  (
    key: 'monitores',
    icon: Icons.desktop_windows_outlined,
    title: 'Monitores',
    subtitle: 'Nombres de las pantallas'
  ),
  (
    key: 'backups',
    icon: Icons.backup_outlined,
    title: 'Backups',
    subtitle: 'Respaldo, restauración y export'
  ),
];

/// Categorías que embeben una pantalla completa propia en vez del panel de
/// campos + "Guardar cambios" — ver `_buildScreenCategory`.
const _screenCategoryKeys = {'envio', 'botonera', 'quiosco', 'monitores', 'backups'};

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Negocio
  late TextEditingController _businessName;
  late TextEditingController _slogan;
  String? _logoPath;

  // Apariencia
  Color _primaryColor = const Color(0xFF6F4E37);
  Color _secondaryColor = const Color(0xFFD4A574);

  // POS
  String _defaultOrderType = 'mesa';
  bool _showCustomerField = true;
  bool _enableTables = true;

  // KDS
  bool _kdsSound = true;
  late TextEditingController _kdsWarnYellow;
  late TextEditingController _kdsWarnRed;

  // Impuestos
  late TextEditingController _taxRate;
  bool _showTaxReceipt = false;
  // Default global de IVA incluido en el precio (4.5).
  bool _taxIncluded = true;

  // Ventas avanzadas (Fase 4)
  bool _propinasActivas = false;

  // Fidelización (docs/fidelizacion.md): sellos y puntos son mecánicas
  // INDEPENDIENTES — ambas pueden estar activas a la vez (feedback de sitio
  // 2026-07-22: antes era "elige UNA", corregido).
  bool _loyaltySellosActivo = false;
  bool _loyaltyPuntosActivo = false;
  late TextEditingController _loyaltyStampsRequired;
  late TextEditingController _loyaltyPointsRequired;
  String? _loyaltyStampsRewardProduct;
  String? _loyaltyPointsRewardProduct;
  // Puntos por producto (Products.loyaltyPointsValue) — un controller por
  // producto, creado perezosamente en `_categoryFields('fidelizacion')`.
  final Map<int, TextEditingController> _loyaltyPointsControllers = {};

  // Moneda
  late TextEditingController _currencySymbol;
  String _currencyDecimals = '2';

  // Recibo
  late TextEditingController _receiptFooter;
  bool _showDiscountOnReceipt = true;
  bool _showEmployeeOnReceipt = true;

  // Facturación — emisor. docs/facturacion.md.
  late TextEditingController _rfcEmisor;
  late TextEditingController _razonEmisor;
  late TextEditingController _regimenEmisor;
  late TextEditingController _cpExpedicion;

  // Caja y seguridad (Fase 2)
  bool _cajaRequiereTurno = true;
  late TextEditingController _autoLockMin;
  bool _lockTrasVenta = false;

  // Impresión y gaveta (Fase 3)
  bool _impresionActiva = false;
  // 'termica' (ESC/POS) | 'grafica' (PDF a cualquier impresora de Windows).
  String _printerMode = 'termica';
  String _printerTransport = 'red';
  late TextEditingController _printerAddress;
  String _printerWidth = '80';
  bool _gavetaActiva = false;
  bool _gavetaAutoEfectivo = true;
  // Impresoras de Windows detectadas, para el desplegable de dirección (USB).
  List<String> _availablePrinters = const [];
  // 2026-07-20 (feedback en vivo): "Buscar impresoras" respondía tan rápido
  // (EnumPrinters es síncrono) que no se notaba que hizo algo — si no
  // encontraba nada, se sentía como que el mensaje de abajo ("No se
  // detectaron impresoras") ya estaba ahí de antes, no como resultado de la
  // búsqueda que se acababa de pedir. Este flag da una confirmación visual.
  bool _searchingPrinters = false;

  bool _loaded = false;

  // null = vista de tarjetas (landing); con valor = detalle de esa categoría.
  String? _activeCategory;

  @override
  void initState() {
    super.initState();
    _businessName = TextEditingController();
    _slogan = TextEditingController();
    _kdsWarnYellow = TextEditingController();
    _kdsWarnRed = TextEditingController();
    _taxRate = TextEditingController();
    _currencySymbol = TextEditingController();
    _receiptFooter = TextEditingController();
    _autoLockMin = TextEditingController();
    _printerAddress = TextEditingController();
    _rfcEmisor = TextEditingController();
    _razonEmisor = TextEditingController();
    _regimenEmisor = TextEditingController();
    _cpExpedicion = TextEditingController();
    _loyaltyStampsRequired = TextEditingController();
    _loyaltyPointsRequired = TextEditingController();
    _availablePrinters = listWindowsPrinters();
  }

  Future<void> _refreshPrinters() async {
    setState(() => _searchingPrinters = true);
    final found = listWindowsPrinters();
    // EnumPrinters responde casi al instante — sin esta pausa el "Buscando…"
    // no alcanza a verse ni cuando SÍ encuentra la impresora recién conectada.
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _availablePrinters = found;
      _searchingPrinters = false;
    });
  }

  @override
  void dispose() {
    _businessName.dispose();
    _slogan.dispose();
    _kdsWarnYellow.dispose();
    _kdsWarnRed.dispose();
    _taxRate.dispose();
    _currencySymbol.dispose();
    _receiptFooter.dispose();
    _autoLockMin.dispose();
    _printerAddress.dispose();
    _rfcEmisor.dispose();
    _razonEmisor.dispose();
    _regimenEmisor.dispose();
    _cpExpedicion.dispose();
    _loyaltyStampsRequired.dispose();
    _loyaltyPointsRequired.dispose();
    for (final c in _loyaltyPointsControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadFromSettings(Map<String, String> s) {
    if (_loaded) return;
    _loaded = true;
    _businessName.text = s['business_name'] ?? '';
    _slogan.text = s['slogan'] ?? '';
    _logoPath = s['logo_path']?.isEmpty == true ? null : s['logo_path'];
    _primaryColor = _parseColor(s['primary_color'] ?? '#6F4E37');
    _secondaryColor = _parseColor(s['secondary_color'] ?? '#D4A574');
    _defaultOrderType = s['default_order_type'] ?? 'mesa';
    _showCustomerField = s['show_customer_field'] == 'true';
    _enableTables = s['enable_tables'] == 'true';
    _kdsSound = s['kds_sound'] == 'true';
    _kdsWarnYellow.text = s['kds_warn_yellow'] ?? '5';
    _kdsWarnRed.text = s['kds_warn_red'] ?? '10';
    _taxRate.text = s['tax_rate'] ?? '0';
    _showTaxReceipt = s['show_tax_receipt'] == 'true';
    _taxIncluded = s['tax_included'] != 'false';
    _propinasActivas = s['propinas_activas'] == 'true';
    _currencySymbol.text = s['currency_symbol'] ?? r'$';
    _currencyDecimals = s['currency_decimals'] ?? '2';
    _receiptFooter.text = s['receipt_footer'] ?? '';
    _showDiscountOnReceipt = s['receipt_show_discount'] != 'false';
    _showEmployeeOnReceipt = s['receipt_show_employee'] != 'false';
    _cajaRequiereTurno = s['caja_requiere_turno'] != 'false';
    _autoLockMin.text = s['auto_lock_min'] ?? '5';
    _lockTrasVenta = s['lock_tras_venta'] == 'true';
    _impresionActiva = s['impresion_activa'] == 'true';
    _printerMode = s['printer_mode'] == 'grafica' ? 'grafica' : 'termica';
    _printerTransport = s['printer_transport'] ?? 'red';
    _printerAddress.text = s['printer_address'] ?? '';
    _printerWidth = s['printer_width'] ?? '80';
    _gavetaActiva = s['gaveta_activa'] == 'true';
    _gavetaAutoEfectivo = s['gaveta_auto_efectivo'] != 'false';
    _rfcEmisor.text = s['rfc_emisor'] ?? '';
    _razonEmisor.text = s['razon_social_emisor'] ?? '';
    _regimenEmisor.text = s['regimen_fiscal_emisor'] ?? '';
    _cpExpedicion.text = s['cp_lugar_expedicion'] ?? '';
    _loyaltySellosActivo = s['loyalty_sellos_activo'] == 'true';
    _loyaltyPuntosActivo = s['loyalty_puntos_activo'] == 'true';
    _loyaltyStampsRequired.text = s['loyalty_stamps_required'] ?? '10';
    _loyaltyPointsRequired.text = s['loyalty_points_required'] ?? '100';
    _loyaltyStampsRewardProduct =
        s['loyalty_stamps_reward_product']?.isEmpty == true
            ? null
            : s['loyalty_stamps_reward_product'];
    _loyaltyPointsRewardProduct =
        s['loyalty_points_reward_product']?.isEmpty == true
            ? null
            : s['loyalty_points_reward_product'];
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6F4E37);
    }
  }

  String _colorToHex(Color c) =>
      '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    // skipLoadingOnReload: sin esto, CUALQUIER invalidación del provider
    // (p.ej. la que dispara el propio _save() al guardar) hace que Riverpod
    // pase por `AsyncLoading` y este `.when()` reemplace TODA la pantalla por
    // un spinner un instante, aunque los datos ya estén guardados — se sentía
    // como si "Guardar" borrara/revirtiera todo (auditoría 2026-07-20).
    return settingsAsync.when(
      skipLoadingOnReload: true,
      data: (s) {
        _loadFromSettings(s);
        return _buildBody(context);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildBody(BuildContext context) {
    final active = _activeCategory;
    final isScreenCategory = active != null &&
        _screenCategoryKeys.contains(active);
    return Scaffold(
      backgroundColor: LaTerciaColors.appBg,
      // Las categorías "pantalla completa" (Envío/Botonera/Quiosco/
      // Monitores/Backups) traen su propio AppBar con botón de regreso —
      // mostrar OTRO aquí encima se vería duplicado. Las demás (Negocio,
      // Apariencia, etc.) siguen usando este AppBar compartido.
      appBar: active == null
          ? adminAppBar('Configuración')
          : isScreenCategory
              ? null
              : AppBar(
                  backgroundColor: LaTerciaColors.cream,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: LaTerciaColors.darkBrown),
                    onPressed: () => setState(() => _activeCategory = null),
                  ),
                  title: Text(
                    _settingsCategories.firstWhere((c) => c.key == active).title,
                    style: const TextStyle(
                        fontFamily: 'DM Serif Display',
                        fontSize: 22,
                        color: LaTerciaColors.darkBrown),
                  ),
                ),
      body: active == null
          ? _buildCategoryGrid()
          : isScreenCategory
              ? _buildScreenCategory(active)
              : _buildCategoryDetail(active),
    );
  }

  /// Landing de Configuración: una tarjeta por tema (estilo Ajustes de
  /// Windows/macOS) en vez de una sola página con todo apilado — así se
  /// encuentra cada control sin perderse en un scroll interminable.
  Widget _buildCategoryGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: CategoryCardGrid(
        children: [
          for (final cat in _settingsCategories)
            CategoryCard(
              icon: cat.icon,
              title: cat.title,
              subtitle: cat.subtitle,
              onTap: () => setState(() => _activeCategory = cat.key),
            ),
        ],
      ),
    );
  }

  /// Las 5 categorías que embeben su pantalla completa de siempre (antes
  /// vivían como items propios del sidebar, o —Monitores— como un
  /// `Navigator.push` que tapaba el sidebar y el header de arriba). Un
  /// cambio de estado (`_activeCategory`), no un push, así que el sidebar y
  /// el header del shell general siguen visibles — igual que "Negocio".
  /// `onBack` vuelve a la cuadrícula de Configuración.
  Widget _buildScreenCategory(String key) {
    void onBack() => setState(() => _activeCategory = null);
    switch (key) {
      case 'envio':
        return DeliveryZonesScreen(onBack: onBack);
      case 'botonera':
        return BotoneraScreen(onBack: onBack);
      case 'quiosco':
        return KioskScreen(onBack: onBack);
      case 'monitores':
        return MonitoresScreen(onBack: onBack);
      case 'backups':
        return BackupsScreen(onBack: onBack);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Detalle de una categoría: solo sus controles + Guardar. `_save()` sigue
  /// persistiendo TODOS los settings a la vez (no solo los de esta categoría)
  /// — es seguro porque los controllers/estado viven en este mismo State y no
  /// se pierden al navegar entre categorías.
  Widget _buildCategoryDetail(String key) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPanel(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _categoryFields(key),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: LaTerciaColors.burntOrange),
                onPressed: _save,
                child: const Text('Guardar cambios',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<Widget> _categoryFields(String key) {
    switch (key) {
      case 'negocio':
        return [
          TextField(
            controller: _businessName,
            decoration: const InputDecoration(labelText: 'Nombre del negocio'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _slogan,
            decoration: const InputDecoration(labelText: 'Slogan'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_logoPath != null && File(_logoPath!).existsSync())
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Image.file(File(_logoPath!),
                      height: 60, width: 60, fit: BoxFit.cover),
                ),
              OutlinedButton.icon(
                onPressed: _pickLogo,
                icon: const Icon(Icons.image),
                label: const Text('Cambiar logo'),
              ),
            ],
          ),
        ];
      case 'apariencia':
        return [
          const Text('Color primario:'),
          ColorPicker(
            color: _primaryColor,
            // Bug 2026-07-20: poner `_loaded = false` aquí forzaba a
            // `_loadFromSettings` a repintar todo desde la base en el
            // siguiente build, y como nada se había guardado aún, el color
            // recién elegido se revertía al instante al valor viejo. Solo
            // se actualiza el estado local; se persiste al dar "Guardar".
            onColorChanged: (c) => setState(() => _primaryColor = c),
            width: 36,
            height: 36,
            borderRadius: 22,
            pickersEnabled: const {
              ColorPickerType.wheel: true,
              ColorPickerType.primary: false,
              ColorPickerType.accent: false,
            },
          ),
          const SizedBox(height: 12),
          const Text('Color secundario:'),
          ColorPicker(
            color: _secondaryColor,
            // Mismo bug que el color primario, ver comentario de arriba.
            onColorChanged: (c) => setState(() => _secondaryColor = c),
            width: 36,
            height: 36,
            borderRadius: 22,
            pickersEnabled: const {
              ColorPickerType.wheel: true,
              ColorPickerType.primary: false,
              ColorPickerType.accent: false,
            },
          ),
          const SizedBox(height: 8),
          // Live preview
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _businessName.text.isEmpty
                      ? 'Vista previa'
                      : _businessName.text,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _secondaryColor),
                  child: const Text('Botón'),
                ),
              ],
            ),
          ),
        ];
      case 'pos':
        return [
          DropdownButtonFormField<String>(
            value: _defaultOrderType,
            decoration: const InputDecoration(
                labelText: 'Tipo de orden predeterminado'),
            items: const [
              DropdownMenuItem(value: 'mesa', child: Text('Mesa')),
              DropdownMenuItem(
                  value: 'para_llevar', child: Text('Para llevar')),
              DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
            ],
            onChanged: (v) => setState(() => _defaultOrderType = v!),
          ),
          SwitchListTile(
            title: const Text('Mostrar campo de cliente'),
            value: _showCustomerField,
            onChanged: (v) => setState(() => _showCustomerField = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Habilitar selección de mesas'),
            value: _enableTables,
            onChanged: (v) => setState(() => _enableTables = v),
            contentPadding: EdgeInsets.zero,
          ),
        ];
      case 'cocina':
        return [
          SwitchListTile(
            title: const Text('Alertas de sonido'),
            value: _kdsSound,
            onChanged: (v) => setState(() => _kdsSound = v),
            contentPadding: EdgeInsets.zero,
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _kdsWarnYellow,
                  decoration: const InputDecoration(
                      labelText: 'Alerta amarilla (minutos)'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _kdsWarnRed,
                  decoration:
                      const InputDecoration(labelText: 'Alerta roja (minutos)'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ];
      case 'caja':
        return [
          SwitchListTile(
            title: const Text('Requerir turno abierto para vender'),
            subtitle: const Text(
                'Bloquea el POS hasta abrir turno con fondo inicial.'),
            value: _cajaRequiereTurno,
            onChanged: (v) => setState(() => _cajaRequiereTurno = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _autoLockMin,
            decoration: const InputDecoration(
              labelText: 'Auto-bloqueo por inactividad (minutos)',
              helperText: '0 = desactivado. Vuelve a pedir el PIN.',
            ),
            keyboardType: TextInputType.number,
          ),
          SwitchListTile(
            title: const Text('Bloquear tras cada venta'),
            subtitle:
                const Text('Pide el PIN de nuevo al terminar cada cobro.'),
            value: _lockTrasVenta,
            onChanged: (v) => setState(() => _lockTrasVenta = v),
            contentPadding: EdgeInsets.zero,
          ),
        ];
      case 'impresion':
        return [
          SwitchListTile(
            title: const Text('Activar impresión de tickets'),
            subtitle: const Text(
                'Imprime ticket de venta y comanda de cocina al cobrar.'),
            value: _impresionActiva,
            onChanged: (v) => setState(() => _impresionActiva = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          // Modo de impresión: térmica (ESC/POS) vs. gráfica (PDF a cualquier
          // impresora de Windows, p.ej. una EPSON de inyección).
          DropdownButtonFormField<String>(
            value: _printerMode,
            decoration: const InputDecoration(labelText: 'Modo de impresión'),
            items: const [
              DropdownMenuItem(
                  value: 'termica', child: Text('Térmica (tickets ESC/POS)')),
              DropdownMenuItem(
                  value: 'grafica',
                  child: Text('Normal / cualquier impresora')),
            ],
            onChanged: (v) => setState(() => _printerMode = v!),
          ),
          const SizedBox(height: 8),
          // ── Modo TÉRMICO: conexión red/usb + dirección ──────────────────
          if (_printerMode == 'termica') ...[
            DropdownButtonFormField<String>(
              value: _printerTransport,
              decoration: const InputDecoration(labelText: 'Tipo de conexión'),
              items: const [
                DropdownMenuItem(
                    value: 'red', child: Text('Red (socket 9100)')),
                DropdownMenuItem(
                    value: 'usb', child: Text('USB / impresora local')),
              ],
              onChanged: (v) => setState(() => _printerTransport = v!),
            ),
            const SizedBox(height: 8),
            // Red → campo de IP libre. USB → depende de la plataforma:
            //   · Windows: desplegable de las impresoras del spooler.
            //   · Linux (kiosko): campo de texto para la cola CUPS o la ruta
            //     del dispositivo — el spooler de Windows no existe aquí, y
            //     antes no había forma de configurar la impresora USB en
            //     Linux (auditoría 2026-07-18, instalación en sitio).
            if (_printerTransport == 'red')
              TextField(
                controller: _printerAddress,
                decoration: const InputDecoration(
                  labelText: 'Dirección IP de la impresora',
                  helperText: 'Ej. 192.168.1.50 o 192.168.1.50:9100',
                  prefixIcon: Icon(Icons.lan_outlined),
                ),
              )
            else if (Platform.isLinux)
              TextField(
                controller: _printerAddress,
                decoration: const InputDecoration(
                  labelText: 'Impresora USB / local',
                  helperText: 'Nombre de la cola CUPS (ej. termica) o ruta del '
                      'dispositivo (ej. /dev/usb/lp0)',
                  prefixIcon: Icon(Icons.print_outlined),
                ),
              )
            else
              _buildUsbPrinterPicker(showVirtualWarning: true),
            if (_printerTransport == 'usb' &&
                isVirtualPrinter(_printerAddress.text))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '"${_printerAddress.text}" no es una impresora térmica: '
                        'no imprime tickets ESC/POS. Usa la vista previa para '
                        'validar el diseño.',
                        style: const TextStyle(
                            fontSize: 12.5, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ]
          // ── Modo GRÁFICO: solo un selector de impresora de Windows ───────
          else ...[
            _buildUsbPrinterPicker(showVirtualWarning: false),
            const SizedBox(height: 8),
          ],
          DropdownButtonFormField<String>(
            value: _printerWidth,
            decoration: const InputDecoration(labelText: 'Ancho de papel'),
            items: const [
              DropdownMenuItem(value: '58', child: Text('58 mm')),
              DropdownMenuItem(value: '80', child: Text('80 mm')),
            ],
            onChanged: (v) => setState(() => _printerWidth = v!),
          ),
          const Divider(height: 24),
          SwitchListTile(
            title: const Text('Activar gaveta de dinero'),
            subtitle: Text(_printerMode == 'grafica'
                ? 'La gaveta requiere impresora térmica.'
                : 'Envía el pulso de apertura por la impresora.'),
            value: _printerMode == 'grafica' ? false : _gavetaActiva,
            onChanged: _printerMode == 'grafica'
                ? null
                : (v) => setState(() => _gavetaActiva = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Abrir gaveta al cobrar en efectivo'),
            value: _printerMode == 'grafica' ? false : _gavetaAutoEfectivo,
            onChanged: _printerMode == 'grafica'
                ? null
                : (v) => setState(() => _gavetaAutoEfectivo = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Vista previa'),
                onPressed: _previewTicket,
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Imprimir ticket de prueba'),
                onPressed: _printTestTicket,
              ),
            ],
          ),
        ];
      case 'impuestos':
        return [
          TextField(
            controller: _taxRate,
            decoration: const InputDecoration(
              labelText: 'IVA % (default global)',
              helperText:
                  'Cada producto puede llevar su propia tasa en el catálogo.',
            ),
            keyboardType: TextInputType.number,
          ),
          SwitchListTile(
            title: const Text('IVA incluido en el precio (default)'),
            subtitle: const Text(
                'ON: el precio del catálogo ya trae el IVA. OFF: se añade al cobrar.'),
            value: _taxIncluded,
            onChanged: (v) => setState(() => _taxIncluded = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Mostrar IVA en recibo'),
            value: _showTaxReceipt,
            onChanged: (v) => setState(() => _showTaxReceipt = v),
            contentPadding: EdgeInsets.zero,
          ),
        ];
      case 'ventas':
        return [
          SwitchListTile(
            title: const Text('Propinas'),
            subtitle: const Text(
                'Captura propina al cobrar (10/15/20% o monto libre). No afecta el total de la venta.'),
            value: _propinasActivas,
            onChanged: (v) => setState(() => _propinasActivas = v),
            contentPadding: EdgeInsets.zero,
          ),
        ];
      case 'fidelizacion':
        final products = ref.watch(allProductsProvider).valueOrNull ?? [];
        for (final p in products) {
          _loyaltyPointsControllers.putIfAbsent(
            p.id,
            () => TextEditingController(text: '${p.loyaltyPointsValue}'),
          );
        }
        return [
          const Text(
            'Sellos y puntos son independientes: puedes activar uno, otro, o '
            'los dos a la vez. El cliente se elige al cobrar en el POS.',
            style: TextStyle(fontSize: 12.5, color: LaTerciaColors.tan),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Sellos (tarjeta de visitas)'),
            subtitle: const Text(
                'Cada venta con cliente suma un sello; al juntar el número '
                'elegido, gana la recompensa.'),
            value: _loyaltySellosActivo,
            onChanged: (v) => setState(() => _loyaltySellosActivo = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_loyaltySellosActivo) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _loyaltyStampsRequired,
              decoration: const InputDecoration(
                labelText: 'Sellos para ganar la recompensa',
                helperText: 'Ej. 10 = la 11ª visita trae algo gratis',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: products.any((p) => p.name == _loyaltyStampsRewardProduct)
                  ? _loyaltyStampsRewardProduct
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Producto que se regala (sellos)',
              ),
              items: [
                for (final p in products)
                  DropdownMenuItem(value: p.name, child: Text(p.name)),
              ],
              onChanged: (v) => setState(() => _loyaltyStampsRewardProduct = v),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          SwitchListTile(
            title: const Text('Puntos'),
            subtitle: const Text(
                'Cada producto otorga los puntos que definas abajo; el '
                'cliente los junta y canjea por un producto.'),
            value: _loyaltyPuntosActivo,
            onChanged: (v) => setState(() => _loyaltyPuntosActivo = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_loyaltyPuntosActivo) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _loyaltyPointsRequired,
              decoration: const InputDecoration(
                  labelText: 'Puntos necesarios para canjear'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: products.any((p) => p.name == _loyaltyPointsRewardProduct)
                  ? _loyaltyPointsRewardProduct
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Producto que se regala (puntos)',
              ),
              items: [
                for (final p in products)
                  DropdownMenuItem(value: p.name, child: Text(p.name)),
              ],
              onChanged: (v) => setState(() => _loyaltyPointsRewardProduct = v),
            ),
            const SizedBox(height: 16),
            const Text('Puntos por producto',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              'Cuántos puntos gana el cliente por cada unidad vendida de '
              'cada producto.',
              style: TextStyle(fontSize: 12.5, color: LaTerciaColors.tan),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 320),
              decoration: BoxDecoration(
                border: Border.all(color: LaTerciaColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: products.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No hay productos todavía.'),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final p = products[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              Expanded(child: Text(p.name)),
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: _loyaltyPointsControllers[p.id],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    suffixText: 'pts',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ];
      case 'moneda':
        return [
          TextField(
            controller: _currencySymbol,
            decoration: const InputDecoration(labelText: 'Símbolo de moneda'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _currencyDecimals,
            decoration: const InputDecoration(labelText: 'Decimales'),
            items: const [
              DropdownMenuItem(value: '0', child: Text('0')),
              DropdownMenuItem(value: '2', child: Text('2')),
            ],
            onChanged: (v) => setState(() => _currencyDecimals = v!),
          ),
        ];
      case 'ticket':
        return [
          TextField(
            controller: _receiptFooter,
            decoration:
                const InputDecoration(labelText: 'Texto de pie de página'),
            maxLines: 2,
          ),
          SwitchListTile(
            title: const Text('Mostrar descuento'),
            value: _showDiscountOnReceipt,
            onChanged: (v) => setState(() => _showDiscountOnReceipt = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Mostrar empleado'),
            value: _showEmployeeOnReceipt,
            onChanged: (v) => setState(() => _showEmployeeOnReceipt = v),
            contentPadding: EdgeInsets.zero,
          ),
        ];
      case 'facturacion':
        return [
          const Text(
            'Datos fiscales del negocio (emisor), necesarios para el prellenado '
            'CFDI 4.0. No timbramos: la factura la genera tu facturador/PAC.',
            style: TextStyle(fontSize: 12.5, color: LaTerciaColors.tan),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rfcEmisor,
            decoration: const InputDecoration(labelText: 'RFC del emisor'),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _razonEmisor,
            decoration: const InputDecoration(labelText: 'Razón social'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _regimenEmisor,
            decoration: const InputDecoration(
              labelText: 'Régimen fiscal (clave SAT)',
              helperText: 'Ej. 612, 621, 626 (c_RegimenFiscal)',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cpExpedicion,
            decoration: const InputDecoration(
              labelText: 'CP lugar de expedición',
              helperText: 'Código postal del negocio',
            ),
            keyboardType: TextInputType.number,
          ),
        ];
      default:
        return const [];
    }
  }

  /// Desplegable con las impresoras instaladas en Windows + botón de refrescar.
  /// El valor guardado en [_printerAddress] se mantiene aunque no aparezca en
  /// la lista (p.ej. una impresora que ahora está apagada), añadiéndolo como
  /// opción para no perder la configuración previa.
  Widget _buildUsbPrinterPicker({bool showVirtualWarning = true}) {
    final current = _printerAddress.text.trim();
    final options = <String>[
      ..._availablePrinters,
      if (current.isNotEmpty && !_availablePrinters.contains(current)) current,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _searchingPrinters
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Buscando impresoras…',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : options.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No se detectó ninguna impresora instalada en Windows. '
                        'Conéctala e instálala desde "Dispositivos e impresoras" '
                        'de Windows, luego toca buscar de nuevo.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value: current.isEmpty ? null : current,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Impresora',
                        prefixIcon: Icon(Icons.print_outlined),
                      ),
                      hint: const Text('Selecciona una impresora'),
                      items: options
                          .map((name) => DropdownMenuItem(
                                value: name,
                                child: Text(
                                  showVirtualWarning && isVirtualPrinter(name)
                                      ? '$name  ·  no térmica'
                                      : name,
                                  overflow: TextOverflow.ellipsis,
                                  style: showVirtualWarning &&
                                          isVirtualPrinter(name)
                                      ? const TextStyle(color: Colors.grey)
                                      : null,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _printerAddress.text = v ?? ''),
                    ),
        ),
        IconButton(
          tooltip: 'Buscar impresoras',
          icon: const Icon(Icons.refresh),
          onPressed: _searchingPrinters ? null : _refreshPrinters,
        ),
      ],
    );
  }

  /// Vista previa en pantalla del ticket al ancho elegido (58/80 mm), sin
  /// necesidad de impresora. Usa los valores que el usuario está editando
  /// (aunque no los haya guardado) para reflejar el ancho/negocio actuales.
  void _previewTicket() {
    final preview = <String, String>{
      'business_name': _businessName.text,
      'printer_width': _printerWidth,
      'printer_transport': _printerTransport,
    };
    final lines = testTicketPreviewLines(preview);
    final cols = paperColumns(preview);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Vista previa · $_printerWidth mm'),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFCF9F2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0D8C8)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              lines.join('\n'),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF2A2118),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('Ancho real: $cols columnas',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Genera y envía un ticket de ejemplo por el transporte configurado, para
  /// que el usuario valide con hardware real. Usa los valores YA guardados en
  /// settings (no los editados sin guardar).
  Future<void> _printTestTicket() async {
    final settings = ref.read(settingsProvider).valueOrNull ?? {};
    final printService = ref.read(printServiceProvider);

    if (!printService.printingEnabled(settings)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Activa la impresión y guarda los cambios antes de probar.'),
          ),
        );
      }
      return;
    }
    if ((settings['printer_address'] ?? '').trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Configura la dirección de la impresora y guarda antes de probar.'),
          ),
        );
      }
      return;
    }

    final ok = await printService.printTestTicket(settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Ticket de prueba enviado.'
              : 'La impresora no respondió. Revisa la conexión y la dirección.'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result == null || result.files.single.path == null) return;
    setState(() => _logoPath = result.files.single.path);
  }

  Future<void> _save() async {
    final settings = <String, String>{
      'business_name': _businessName.text,
      'slogan': _slogan.text,
      'logo_path': _logoPath ?? '',
      'primary_color': _colorToHex(_primaryColor),
      'secondary_color': _colorToHex(_secondaryColor),
      'default_order_type': _defaultOrderType,
      'show_customer_field': _showCustomerField.toString(),
      'enable_tables': _enableTables.toString(),
      'kds_sound': _kdsSound.toString(),
      'kds_warn_yellow': _kdsWarnYellow.text,
      'kds_warn_red': _kdsWarnRed.text,
      'tax_rate': _taxRate.text,
      'show_tax_receipt': _showTaxReceipt.toString(),
      'tax_included': _taxIncluded.toString(),
      'propinas_activas': _propinasActivas.toString(),
      'currency_symbol': _currencySymbol.text,
      'currency_decimals': _currencyDecimals,
      'receipt_footer': _receiptFooter.text,
      'receipt_show_discount': _showDiscountOnReceipt.toString(),
      'receipt_show_employee': _showEmployeeOnReceipt.toString(),
      'caja_requiere_turno': _cajaRequiereTurno.toString(),
      'auto_lock_min':
          _autoLockMin.text.trim().isEmpty ? '0' : _autoLockMin.text.trim(),
      'lock_tras_venta': _lockTrasVenta.toString(),
      'impresion_activa': _impresionActiva.toString(),
      'printer_mode': _printerMode,
      'printer_transport': _printerTransport,
      'printer_address': _printerAddress.text.trim(),
      'printer_width': _printerWidth,
      'gaveta_activa': _gavetaActiva.toString(),
      'gaveta_auto_efectivo': _gavetaAutoEfectivo.toString(),
      'rfc_emisor': _rfcEmisor.text.trim().toUpperCase(),
      'razon_social_emisor': _razonEmisor.text.trim(),
      'regimen_fiscal_emisor': _regimenEmisor.text.trim(),
      'cp_lugar_expedicion': _cpExpedicion.text.trim(),
      'loyalty_sellos_activo': _loyaltySellosActivo.toString(),
      'loyalty_puntos_activo': _loyaltyPuntosActivo.toString(),
      'loyalty_stamps_required': _loyaltyStampsRequired.text.trim(),
      'loyalty_points_required': _loyaltyPointsRequired.text.trim(),
      'loyalty_stamps_reward_product': _loyaltyStampsRewardProduct ?? '',
      'loyalty_points_reward_product': _loyaltyPointsRewardProduct ?? '',
    };

    await ref.read(settingsProvider.notifier).setSettings(settings);

    // Puntos por producto (docs/fidelizacion.md) viven en Products, no en
    // Settings — se guardan aparte, en el mismo click de "Guardar cambios".
    final db = ref.read(databaseProvider);
    for (final entry in _loyaltyPointsControllers.entries) {
      final points = int.tryParse(entry.value.text.trim()) ?? 0;
      await db.productsDao.updateLoyaltyPointsValue(entry.key, points);
    }
    // NO se pone `_loaded = false` aquí: el estado local YA es justo lo que
    // se acaba de persistir, así que no hace falta recargarlo desde la base.
    // Antes esto forzaba una vuelta a `_loadFromSettings`, que junto con el
    // flash de `AsyncLoading` de `invalidateSelf()` se sentía como si
    // "Guardar" revirtiera todo (auditoría 2026-07-20; ver skipLoadingOnReload
    // arriba y el fix del ColorPicker).

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada ✓'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
