import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:billing_app/l10n/app_localizations.dart';

class EscPos {
  static const List<int> init = [0x1B, 0x40];
  static const List<int> alignCenter = [0x1B, 0x61, 0x01];
  static const List<int> alignLeft = [0x1B, 0x61, 0x00];
  static const List<int> alignRight = [0x1B, 0x61, 0x02];
  static const List<int> boldOn = [0x1B, 0x45, 0x01];
  static const List<int> boldOff = [0x1B, 0x45, 0x00];
  static const List<int> textNormal = [0x1D, 0x21, 0x00];
  static const List<int> textLarge = [0x1D, 0x21, 0x11];
  static const List<int> lineFeed = [0x0A];
}

class PrinterHelper {
  // Singleton
  static final PrinterHelper _instance = PrinterHelper._internal();
  factory PrinterHelper() => _instance;
  PrinterHelper._internal();

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<bool> checkPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<List<BluetoothInfo>> getBondedDevices() async {
    try {
      final List<BluetoothInfo> list =
          await PrintBluetoothThermal.pairedBluetooths;
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<bool> connect(String macAddress) async {
    try {
      final bool result =
          await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      _isConnected = result;
      return result;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      final bool result = await PrintBluetoothThermal.disconnect;
      _isConnected = !result;
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<void> printReceipt({
    required String shopName,
    required String address1,
    required String address2,
    required String phone,
    required List<Map<String, dynamic>> items,
    required double total,
    required String footer,
    required AppLocalizations l10n,
  }) async {
    if (!_isConnected) return;

    final bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (!connectionStatus) return;

    List<int> bytes = [];

    // Init
    bytes += EscPos.init;

    // Shop Name
    bytes += EscPos.alignCenter;
    bytes += EscPos.boldOn;
    bytes += EscPos.textLarge;
    bytes += _textToBytes(shopName);
    bytes += EscPos.lineFeed;

    // Details
    bytes += EscPos.textNormal;
    bytes += EscPos.boldOff;
    if (address1.isNotEmpty) {
      bytes += _textToBytes(address1);
      bytes += EscPos.lineFeed;
    }
    if (address2.isNotEmpty) {
      bytes += _textToBytes(address2);
      bytes += EscPos.lineFeed;
    }
    bytes += _textToBytes('${l10n.telLabel}: $phone');
    bytes += EscPos.lineFeed;

    String formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
    bytes += _textToBytes(formattedDate);
    bytes += EscPos.lineFeed;

    bytes += _textToBytes('--------------------------------');
    bytes += EscPos.lineFeed;

    // Header
    bytes += EscPos.alignLeft;
    String headerLine = '${l10n.itemsHeader.padRight(16)}${l10n.priceHeader.padRight(8)}${l10n.totalHeader}';
    if (headerLine.length > 32) headerLine = headerLine.substring(0, 32);
    bytes += _textToBytes(headerLine);
    bytes += EscPos.lineFeed;
    bytes += _textToBytes('--------------------------------');
    bytes += EscPos.lineFeed;

    // Items
    for (var item in items) {
      String name = item['name'].toString();
      String qty = item['qty'].toString();
      String price = item['price'].toString();
      String totalItem = item['total'].toString();

      String prefix = '${qty}x $name';
      if (prefix.length > 16) prefix = prefix.substring(0, 16);

      String line = prefix.padRight(16) + price.padRight(8) + totalItem;
      bytes += _textToBytes(line);
      bytes += EscPos.lineFeed;
    }

    bytes += _textToBytes('--------------------------------');
    bytes += EscPos.lineFeed;

    // Total
    bytes += EscPos.alignRight;
    bytes += EscPos.boldOn;
    bytes += _textToBytes('${l10n.totalHeader.toUpperCase()}: $total');
    bytes += EscPos.lineFeed;
    bytes += EscPos.boldOff;
    bytes += EscPos.lineFeed;

    // Footer
    bytes += EscPos.alignCenter;
    if (footer.isNotEmpty) {
      bytes += _textToBytes(footer);
      bytes += EscPos.lineFeed;
    }
    bytes += _textToBytes(l10n.receiptFooterGratitude);
    bytes += EscPos.lineFeed;
    bytes += EscPos.lineFeed;
    bytes += EscPos.lineFeed;

    await PrintBluetoothThermal.writeBytes(bytes);
  }

  Future<void> printText(String text) async {
    if (!_isConnected) return;
    List<int> bytes = [];
    bytes += EscPos.init;
    bytes += _textToBytes(text);
    await PrintBluetoothThermal.writeBytes(bytes);
  }

  List<int> _textToBytes(String text) {
    return List.from(text.codeUnits);
  }
}
