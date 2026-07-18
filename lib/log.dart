import 'package:wallrio/services/packages/export.dart';

// DevelopmentFilter (the package default) wraps its check in an `assert()`,
// so it silently omits every log in profile/release builds — including
// TestFlight. ProductionFilter uses the same level check without that, so
// logs actually show up outside of debug mode too.
var logger = Logger(filter: ProductionFilter());
