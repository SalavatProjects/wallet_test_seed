String formatAddressForCell(String address, double textScaleFactor) {
  const prefix = '0x';
  
  final hasPrefix = address.startsWith(prefix);
  final mainPart = hasPrefix ? address.substring(prefix.length) : address;

  if (mainPart.length <= 12) {
    return address;
  }

  final leadingLength = textScaleFactor < 1.6 ? 6 : 4;
  final leadingPart = mainPart.substring(0, leadingLength);
  final trailingPart = mainPart.substring(mainPart.length - 4);

  return '${hasPrefix ? prefix : ''}$leadingPart…$trailingPart';
}