import os

for path in os.listdir("results/2"):
  if not os.path.isdir(path):
    continue
  print(path)

