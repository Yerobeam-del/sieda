class Helpers {
  static String formatGender(String? gender) {
    if (gender == null) return '-';
    final upper = gender.toUpperCase().trim();
    if (upper == 'L' || upper == 'LAKI-LAKI') return 'Laki-laki';
    if (upper == 'P' || upper == 'PEREMPUAN') return 'Perempuan';
    return gender;
  }

  static String formatYesNo(String? value) {
    if (value == null) return '-';
    final upper = value.toUpperCase().trim();
    if (upper == 'Y' || upper == 'YA' || upper == 'YES') return 'Ya';
    if (upper == 'T' || upper == 'TIDAK' || upper == 'NO') return 'Tidak';
    return value;
  }

  static String formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '-';
    if (phone.length >= 12) {
      return '${phone.substring(0, 4)}-${phone.substring(4, 8)}-${phone.substring(8)}';
    }
    return phone;
  }

  static String formatNumeric(dynamic value) {
    if (value == null) return '0';
    final num = (value is num) ? value : double.tryParse(value.toString()) ?? 0;
    return num.toStringAsFixed(0);
  }

  static String formatRupiah(dynamic value) {
    if (value == null) return 'Rp 0';
    final num = (value is num) ? value : double.tryParse(value.toString()) ?? 0;
    final formatted = num.toStringAsFixed(0);
    final regex = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
    return 'Rp ${formatted.replaceAllMapped(regex, (match) => '${match.group(1)}.')}';
  }

  static String getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  static String truncate(String? text, int maxLength) {
    if (text == null || text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
