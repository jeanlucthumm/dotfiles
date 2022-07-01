import random

choices = []
choices.extend('0123456789abcdef')

out = ''
for i in range(6):
  out += str(random.choice(choices))

print(out)
