# FLUTTER_STRUCTURE.md
Flutter Clean Architecture

lib/
 ├ core/
 │   ├ config/
 │   ├ constants/
 │   ├ network/
 │   └ utils/
 │
 ├ features/
 │   ├ auth/
 │   ├ domains/
 │   ├ aliases/
 │   ├ catchall/
 │   └ analytics/
 │
 ├ shared/
 │   ├ widgets/
 │   ├ themes/
 │   └ models/
 │
 └ main.dart

## Layers
Presentation → UI
Domain → business logic
Data → repositories and API
Core → shared utilities