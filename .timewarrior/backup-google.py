import sys

SEP = ' '

for line in sys.stdin:
  tokens = line.rstrip('\n').split(SEP)
  try:
    tag = tokens.index('#')
    tokens[tag+1] = "google"
  except:
    tokens.extend(['#', 'google'])
  sys.stdout.write(SEP.join(tokens) + "\n")
