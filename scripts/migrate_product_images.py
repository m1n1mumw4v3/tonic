#!/usr/bin/env python3
"""
One-shot migration: download each product hero image from its origin URL,
resize to <=1200px, encode WebP @ q=85, upload to Supabase Storage
bucket `product-images`, and rewrite products.image_url to the Storage URL.

`image_source_url` (already backfilled from the original `image_url`) is left
untouched so we can re-fetch and detect upstream drift later.

Usage:
    SUPABASE_SERVICE_ROLE_KEY=sb_secret_... python3 scripts/migrate_product_images.py
"""

import concurrent.futures
import io
import json
import os
import sys
import urllib.parse
import urllib.request

from PIL import Image

PROJECT_REF = "cklufwujnouncgwnkdkc"
SUPABASE_URL = f"https://{PROJECT_REF}.supabase.co"
BUCKET = "product-images"
MAX_DIM = 1200
WEBP_QUALITY = 85
WORKERS = 8
UA = "Mozilla/5.0"

SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
if not SERVICE_KEY:
    sys.exit("ERROR: set SUPABASE_SERVICE_ROLE_KEY in env (get it from Supabase Dashboard → Settings → API).")


def fetch_products():
    url = f"{SUPABASE_URL}/rest/v1/products?select=id,image_source_url&image_source_url=not.is.null&order=id"
    req = urllib.request.Request(url, headers={
        "apikey": SERVICE_KEY,
        "Authorization": f"Bearer {SERVICE_KEY}",
    })
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def download(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read()


def to_webp(raw: bytes) -> bytes:
    img = Image.open(io.BytesIO(raw))
    if img.mode not in ("RGB", "RGBA"):
        img = img.convert("RGBA" if "A" in img.mode else "RGB")
    w, h = img.size
    if max(w, h) > MAX_DIM:
        scale = MAX_DIM / max(w, h)
        img = img.resize((int(w * scale), int(h * scale)), Image.LANCZOS)
    buf = io.BytesIO()
    img.save(buf, format="WEBP", quality=WEBP_QUALITY, method=6)
    return buf.getvalue()


def upload(path: str, body: bytes) -> None:
    url = f"{SUPABASE_URL}/storage/v1/object/{BUCKET}/{path}"
    req = urllib.request.Request(url, data=body, method="PUT", headers={
        "apikey": SERVICE_KEY,
        "Authorization": f"Bearer {SERVICE_KEY}",
        "Content-Type": "image/webp",
        "x-upsert": "true",
        "cache-control": "public, max-age=31536000, immutable",
    })
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            if r.status >= 400:
                raise RuntimeError(f"upload {r.status}: {r.read()[:300].decode('utf-8', errors='replace')}")
    except urllib.error.HTTPError as e:
        body_preview = e.read()[:300].decode('utf-8', errors='replace')
        raise RuntimeError(f"upload {e.code}: {body_preview}")


def patch_row(pid: str, new_url: str) -> None:
    url = f"{SUPABASE_URL}/rest/v1/products?id=eq.{pid}"
    body = json.dumps({"image_url": new_url}).encode()
    req = urllib.request.Request(url, data=body, method="PATCH", headers={
        "apikey": SERVICE_KEY,
        "Authorization": f"Bearer {SERVICE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
    })
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            if r.status >= 400:
                raise RuntimeError(f"patch {r.status}: {r.read()[:300].decode('utf-8', errors='replace')}")
    except urllib.error.HTTPError as e:
        body_preview = e.read()[:300].decode('utf-8', errors='replace')
        raise RuntimeError(f"patch {e.code}: {body_preview}")


def public_url(path: str) -> str:
    return f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/{urllib.parse.quote(path)}"


def process(row: dict) -> dict:
    pid, src = row["id"], row["image_source_url"]
    try:
        raw = download(src)
        webp = to_webp(raw)
        path = f"{pid}.webp"
        upload(path, webp)
        new_url = public_url(path)
        patch_row(pid, new_url)
        return {"id": pid, "ok": True, "in": len(raw), "out": len(webp), "url": new_url}
    except Exception as e:
        return {"id": pid, "ok": False, "err": f"{type(e).__name__}: {e}", "src": src}


def main():
    rows = fetch_products()
    print(f"Processing {len(rows)} products...")
    ok, fail = 0, 0
    bytes_in, bytes_out = 0, 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=WORKERS) as ex:
        for r in ex.map(process, rows):
            if r["ok"]:
                ok += 1
                bytes_in += r["in"]
                bytes_out += r["out"]
                ratio = r["out"] / r["in"] * 100 if r["in"] else 0
                print(f"  ✓ {r['id']}  {r['in']//1024:>5} KB → {r['out']//1024:>4} KB ({ratio:.0f}%)")
            else:
                fail += 1
                print(f"  ✗ {r['id']}  {r['err']}  ({r['src']})")
    print()
    print(f"Done: {ok} ok, {fail} failed")
    if ok:
        print(f"Bytes: {bytes_in/1024/1024:.1f} MB → {bytes_out/1024/1024:.1f} MB ({bytes_out/bytes_in*100:.0f}% of original)")


if __name__ == "__main__":
    main()
