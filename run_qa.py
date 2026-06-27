import subprocess
import time
import sys
import os

screenshot_dir = 'test/integration/screenshots'
os.makedirs(screenshot_dir, exist_ok=True)

print("Starting flutter test...")
process = subprocess.Popen(
    ['flutter', 'test', 'integration_test/qa_test.dart', '-d', 'iPhone 17'],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    bufsize=1
)

for line in iter(process.stdout.readline, ''):
    print("TEST_OUT: " + line.strip())
    if "SCREENSHOT_READY:" in line:
        name = line.strip().split("SCREENSHOT_READY:")[1].strip()
        screenshot_path = os.path.join(screenshot_dir, f'{name}.png')
        print(f"Capturing screenshot for {name} to {screenshot_path}...")
        subprocess.run(['xcrun', 'simctl', 'io', 'booted', 'screenshot', screenshot_path])
    elif "ALL_DONE" in line:
        print("Tests completed!")
        process.terminate()
        break

process.stdout.close()
process.wait()
print("Runner finished.")
