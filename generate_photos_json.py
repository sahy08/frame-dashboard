#!/usr/bin/env python3
import argparse
import json
import os
import random

EXTS = {'.jpg', '.jpeg', '.png', '.webp'}

def main():
    parser = argparse.ArgumentParser(description='Genera photos.json desde un directorio de imágenes')
    parser.add_argument('--dir',    default='/opt/slideshow',        help='Directorio de imágenes')
    parser.add_argument('--output', default='/opt/dashboard/photos.json', help='Archivo JSON de salida')
    args = parser.parse_args()

    if not os.path.isdir(args.dir):
        print(f'Error: directorio no existe: {args.dir}')
        raise SystemExit(1)

    files = [
        f for f in os.listdir(args.dir)
        if os.path.splitext(f)[1].lower() in EXTS
    ]
    random.shuffle(files)

    with open(args.output, 'w') as fh:
        json.dump({'photos': files}, fh, indent=2)

    print(f'{len(files)} imágenes → {args.output}')

if __name__ == '__main__':
    main()
