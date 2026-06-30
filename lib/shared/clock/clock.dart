/// Time abstraction so deterministic tests can drive lifecycles.
abstract interface class Clock {
  DateTime now();
  Future<void> sleep(Duration duration);
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
  @override
  Future<void> sleep(Duration duration) => Future.delayed(duration);
}
