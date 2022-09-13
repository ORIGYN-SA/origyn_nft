import hashlib
import base64
import math
import binascii
import sys

"""Run `python3 principal_to_accountid.py {Principal}`
    """
if __name__ == '__main__':
    # principal_id_str_in = "m7b5y-itxyr-mr2gt-kvadr-2dity-bh3n5-ff7bb-vvm2v-3ftew-5wjtg-2qe"
    principal_id_str_in = sys.argv[1]
    # print("converting {}".format(principal_id_str_in))
    subaccount = bytearray(32)
    principal_id_str = principal_id_str_in.replace('-', '')
    pad_length = math.ceil(len(principal_id_str) / 8) * \
        8 - len(principal_id_str)
    # print(principal_id_str)
    principal_bytes = base64.b32decode(
        principal_id_str.encode('ascii') + b'=' * pad_length, True, None)
    principal_bytes = principal_bytes[4:]  # remove CRC32 checksum bytes
    ADS = b"\x0Aaccount-id"
    h = hashlib.sha224()
    h.update(ADS)
    h.update(principal_bytes)
    # print(subaccount)
    h.update(subaccount)

    checksum = binascii.crc32(h.digest())
    checksum_bytes = checksum.to_bytes(4, byteorder='big')

    identifier = checksum_bytes + h.digest()

    # print(identifier)

    # print('account identifier {} of principal {}'.format(
    #     identifier.hex(), principal_id_str_in))
    print(identifier.hex())