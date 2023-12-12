import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_list_viewport/page_list_viewport.dart';

void main() {
  group("Panning simulation", () {
    testWidgets("reports zero velocity when it completes", (widgetTester) async {
      final controller = PageListViewportController(vsync: widgetTester);
      await _pumpPageListViewport(widgetTester, controller: controller);

      Offset? latestVelocity;
      controller.addListener(() {
        latestVelocity = controller.velocity;
      });

      // Fling up, to scroll down, and run a panning simulation.
      await widgetTester.fling(find.byType(Scaffold), const Offset(0, -500), 4000);
      await widgetTester.pumpAndSettle();

      // Ensure that the final reported velocity is zero.
      expect(latestVelocity, isNotNull);
      expect(latestVelocity, Offset.zero);
    });
  });
  group("Stylus functionality", () {
    testWidgets("stops panning viewport", (widgetTester) async {
      final controller = PageListViewportController(vsync: widgetTester);
      await _pumpPageListViewport(widgetTester, controller: controller);
      Offset? latestVelocity;
      controller.addListener(() {
        latestVelocity = controller.velocity;
      });

      // Fling up, to scroll down, and run a panning simulation.
      await widgetTester.fling(find.byType(Scaffold), const Offset(0, -500), 4000);
      // The viewport is moving
      widgetTester.pump;
      expect(latestVelocity == Offset.zero, false);

      await widgetTester.startGesture(const Offset(0, 0), kind: PointerDeviceKind.stylus);
      // Pumping one frame does not suffice to propagate the stylus gesture
      // and stop the scrolling simulation, so we're using a pumping duration.
      while (latestVelocity != Offset.zero) {
        await widgetTester.pump(const Duration(milliseconds: 100));
      }
      expect(latestVelocity == Offset.zero, true);
    });

    testWidgets("operates as a panning device", (widgetTester) async {
      final controller = PageListViewportController(vsync: widgetTester);

      //Add stylus to PageListViewPortGestures
      final deviceKind = {
        PointerDeviceKind.stylus,
      };
      await _pumpPageListViewport(widgetTester, controller: controller, pointerDevices: deviceKind);

      Offset? latestVelocity;
      controller.addListener(() {
        latestVelocity = controller.velocity;
      });

      // Fling up with stylus
      await widgetTester.fling(find.byType(Scaffold), const Offset(0, -500), 4000, deviceKind: PointerDeviceKind.stylus);

      // The viewport is moving after fling
      widgetTester.pump;
      expect(latestVelocity != Offset.zero, false);
    });
  });
}

Future<void> _pumpPageListViewport(
  WidgetTester tester, {
  PageListViewportController? controller,
  int pageCount = 10,
  Size? naturalPageSize,
  PageBuilder? pageBuilder,
  Set<PointerDeviceKind>? pointerDevices,
}) async {
  controller ??= PageListViewportController(vsync: tester);
  naturalPageSize ??= const Size(8.5, 11) * 72;
  pageBuilder ??= _defaultPageBuilder;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PageListViewportGestures(
          controller: controller,
          panAndZoomPointerDevices: pointerDevices ??
              const {
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.touch,
              },
          child: PageListViewport(
            controller: controller,
            pageCount: pageCount,
            naturalPageSize: naturalPageSize,
            builder: pageBuilder,
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Widget _defaultPageBuilder(BuildContext context, int pageIndex) {
  return const ColoredBox(
    color: Colors.white,
  );
}
