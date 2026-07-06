import re

def clean_file(path):
    with open(path, 'r') as f:
        lines = f.readlines()
    
    seen_imports = set()
    new_lines = []
    for line in lines:
        if line.startswith("import "):
            if line in seen_imports:
                continue
            seen_imports.add(line)
            # Remove bad imports from subscription.dart
            if "subscription.dart" in path:
                if "provider/provider.dart" in line or "purchases_flutter/purchases_flutter.dart" in line:
                    continue
        new_lines.append(line)
        
    with open(path, 'w') as f:
        f.writelines(new_lines)

clean_file("lib/provider/subscription.dart")
clean_file("lib/provider/wall_action.dart")
clean_file("lib/ui/oauth/login_page.dart")

