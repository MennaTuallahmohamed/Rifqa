# Package self-test (requires only Python + Pillow + PyYAML if installed).
import json
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parent
base = ROOT/'assets/images/madinah_cinematic'
data = json.loads((ROOT/'assets/data/madinah_cinematic/stories.json').read_text('utf-8'))
assert len(data) == 50 and len({x['id'] for x in data}) == 50
assert all(x['summary'] and x['source'] and x['category'] for x in data)
assert sorted(x['id'] for x in data) == list(range(1,51))
imgs = list(base.rglob('*.jpg'))
assert len(imgs) == 57, len(imgs)
for f in imgs:
    with Image.open(f) as im:
        assert im.format == 'JPEG' and im.width >= 500 and im.height >= 500
        im.verify()
for item in data:
    assert (ROOT/item['cover']).is_file(), item
print('PASS: 50 sourced stories + 50 JPEG covers + 7 scene photos, offline bundle complete.')
