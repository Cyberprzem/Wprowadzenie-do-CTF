# Uzupełnij skrypt albo napisz własny.
# Cel: sprawdzić wszystkie możliwe wartości 1-bajtowego klucza XOR.

data = bytes.fromhex(open("cipher.hex").read().strip())

for key in range(256):
    plaintext = bytes([b ^ key for b in data])
    if b"flag{" in plaintext:
        print(key, plaintext)
