import hashlib
from hashlib import sha256


def dsha256(b: bytes) -> bytes:
    """Double SHA256 hash."""
    return sha256(sha256(b).digest()).digest()


def sha512_256d(b: bytes) -> bytes:
    """
    Double SHA512/256 hash - Radiant's proof-of-work algorithm.
    SHA512/256 is the truncated version of SHA512 using a different IV.
    """
    h1 = hashlib.sha512(b).digest()[:32]  # First round: SHA512 truncated to 256 bits
    h2 = hashlib.sha512(h1).digest()[:32]  # Second round: SHA512 truncated to 256 bits
    return h2


def radiant_pow(header80: bytes) -> bytes:
    """
    Radiant proof-of-work hash using SHA512/256d algorithm.
    """
    return sha512_256d(header80)
