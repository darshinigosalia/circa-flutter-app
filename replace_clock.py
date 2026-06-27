import os

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    if 'DateTime.now()' in content:
        # replace
        content = content.replace('DateTime.now()', 'AppClock.now()')
        
        # add import if not there
        import_stmt = "import 'package:circa_app/utils/app_clock.dart';"
        if import_stmt not in content:
            # find last import
            lines = content.split('\n')
            last_import = -1
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    last_import = i
            if last_import != -1:
                lines.insert(last_import + 1, import_stmt)
            else:
                lines.insert(0, import_stmt)
            content = '\n'.join(lines)
            
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart') and file != 'app_clock.dart':
            process_file(os.path.join(root, file))
