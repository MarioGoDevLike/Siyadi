import 'package:flutter_test/flutter_test.dart';
import 'package:siyadi_admin/theme/admin_theme.dart';

void main() {
  test('admin color tokens stay on forest/brass palette', () {
    expect(AdminColors.canopy.value, isNonZero);
    expect(AdminColors.brass.value, isNonZero);
    expect(AdminColors.bark.value, isNonZero);
  });
}
