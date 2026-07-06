import re
import subprocess

try:
    out = subprocess.check_output(['flutter', 'analyze'], stderr=subprocess.STDOUT).decode('utf-8')
except subprocess.CalledProcessError as e:
    out = e.output.decode('utf-8')
    
lines = out.split('\n')

issues = []
for line in lines:
    if ' • ' in line:
        parts = line.split(' • ')
        if len(parts) >= 3:
            msg = parts[1]
            file_info = parts[2]
            if ':' in file_info:
                file_path, line_no, col = file_info.split(':')
                issues.append((file_path, int(line_no), msg))

for file_path, line_no, msg in issues:
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
            if 0 <= line_no - 1 < len(lines):
                print(f"--- {file_path}:{line_no} ---")
                print(f"MSG: {msg}")
                # print context
                start = max(0, line_no - 2)
                end = min(len(lines), line_no + 1)
                for i in range(start, end):
                    prefix = ">> " if i == line_no - 1 else "   "
                    print(f"{prefix}{i+1}: {lines[i].rstrip()}")
                print()
    except Exception as e:
        pass
