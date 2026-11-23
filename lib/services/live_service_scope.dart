import 'package:flutter/material.dart';

import 'live_service.dart';

/// Даёт экранам доступ к единому [LiveService] уровня приложения.
///
/// Намеренно использует `getInheritedWidgetOfExactType`, а не `dependOn...`:
/// подписку на обновления делает [ListenableBuilder] там, где она нужна,
/// иначе каждое live-сообщение пересобирало бы всё дерево.
class LiveServiceScope extends InheritedNotifier<LiveService> {
  const LiveServiceScope({
    super.key,
    required LiveService service,
    required super.child,
  }) : super(notifier: service);

  static LiveService of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<LiveServiceScope>();
    assert(scope?.notifier != null, 'LiveServiceScope отсутствует в дереве');
    return scope!.notifier!;
  }
}

/// Держит [LiveService] и выключает опрос, когда приложение уходит в фон.
class LiveLifecycleController extends StatefulWidget {
  final LiveService service;
  final Widget child;

  const LiveLifecycleController({
    super.key,
    required this.service,
    required this.child,
  });

  @override
  State<LiveLifecycleController> createState() => _LiveLifecycleControllerState();
}

class _LiveLifecycleControllerState extends State<LiveLifecycleController>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.service.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.service.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    widget.service.setAppActive(active);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
