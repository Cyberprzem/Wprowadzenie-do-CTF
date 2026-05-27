#!/usr/bin/env python3
import sqlite3

username = input("Username: ")
password = input("Password: ")

con = sqlite3.connect("users.db")
cur = con.cursor()

# Celowo podatny kod do zadania CTF. Nie kopiować do prawdziwych aplikacji.
query = f"SELECT username, role, flag FROM users WHERE username = '{username}' AND password = '{password}'"
print("[debug] SQL:", query)

rows = cur.execute(query).fetchall()

if not rows:
    print("Login failed")
else:
    for username, role, flag in rows:
        print(f"Logged as: {username} ({role})")
        if flag:
            print(flag)
