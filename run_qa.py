import subprocess
import time
import sys
import os

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
        print(f"Capturing screenshot for {name}...")
        subprocess.run(['xcrun', 'simctl', 'io', 'booted', 'screenshot', f'{name}.png'])
    elif "ALL_DONE" in line:
        print("Tests completed!")
        process.terminate()
        break

process.stdout.close()
process.wait()
print("Runner finished.")
