def hash(key: str) -> int:
    code = 0
    for i,c in enumerate(key):
        code += ord(c) << i
    return code
print(hash("Harry Potter") % 32)
print(hash("Jon Snow") % 32)

