import 'dart:async';

/// Stream event global untuk mendeteksi HTTP 401 dari mana pun di aplikasi.
///
/// Ketika [ApiClient] menerima 401 Unauthorized (token kadaluarsa/dicabut),
/// event dipublikasikan ke stream ini. Siapa pun yang mendaftar (biasanya
/// AuthProvider atau app shell) bisa bereaksi — mis. memaksa logout dan
/// redirect ke LoginScreen.
///
/// Catatan desain:
///   - Broadcast stream sehingga satu event bisa didengar banyak listener.
///   - ApiClient tidak boleh langsung mengakses ChangeNotifier/Provider
///     agar tetap decoupled & tidak perlu BuildContext.
class ApiAuthStream {
  /// Controller singleton — satu stream untuk lifetime aplikasi.
  static final StreamController<int> _controller = StreamController<int>.broadcast();

  /// Stream yang berisi statusCode (selalu 401) setiap kali ada 401.
  static Stream<int> get stream => _controller.stream;

  /// Publikasikan event. Dipanggil oleh ApiClient saat menerima 401.
  static void emitUnauthorized() {
    if (!_controller.isClosed) {
      _controller.add(401);
    }
  }
}
