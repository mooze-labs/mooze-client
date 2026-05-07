/// Long-lived resources owned by orchestrators implement this.
abstract interface class Disposable {
  Future<void> dispose();
}
