#!/usr/bin/env python3
# Zadanie CTF: znajdź hasło albo odzyskaj flagę z kodu.
# Nie zakładaj, że program musi być "atakowany"; czasem wystarczy analiza.

import sys

def check(p):
    target = [111, 116, 119, 97, 114, 99, 105, 101]
    return [ord(c) for c in p] == target

def reveal():
    nums = [93, 87, 90, 92, 64, 73, 94, 90, 95, 100, 79, 83, 94, 100, 88, 84, 95, 94, 70]
    return "".join(chr(n ^ 59) for n in nums)

password = input("Hasło: ")

if check(password):
    print(reveal())
else:
    print("Niepoprawne hasło.")
