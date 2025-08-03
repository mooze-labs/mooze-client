  String formatAddress(String address) {
    if (address.isEmpty) return '';
    if (address.length <= 12) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
  }