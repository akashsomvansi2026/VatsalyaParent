"""Size the approved launcher artwork for existing platform icon resources."""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/branding/vatsalya_guard_parent_icon.png'
art = Image.open(SOURCE).convert('RGB')


def save(path, size):
    path.parent.mkdir(parents=True, exist_ok=True)
    art.resize((size, size), Image.Resampling.LANCZOS).save(path)


for density, size in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96,
                      'xxhdpi': 144, 'xxxhdpi': 192}.items():
    save(ROOT / f'android/app/src/main/res/mipmap-{density}/ic_launcher.png', size)

for platform, folder in [
    ('ios', 'ios/Runner/Assets.xcassets/AppIcon.appiconset'),
    ('macos', 'macos/Runner/Assets.xcassets/AppIcon.appiconset'),
]:
    directory = ROOT / folder
    catalog = json.loads((directory / 'Contents.json').read_text())
    for item in catalog['images']:
        if 'filename' in item:
            size = round(float(item['size'].split('x')[0]) *
                         float(item['scale'].removesuffix('x')))
            save(directory / item['filename'], size)

for size in [192, 512]:
    save(ROOT / f'web/icons/Icon-{size}.png', size)
    save(ROOT / f'web/icons/Icon-maskable-{size}.png', size)
save(ROOT / 'web/favicon.png', 32)
art.save(ROOT / 'windows/runner/resources/app_icon.ico',
         sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64),
                (128, 128), (256, 256)])
manifest_path = ROOT / 'web/manifest.json'
manifest = json.loads(manifest_path.read_text())
manifest.update(background_color='#176B61', theme_color='#176B61',
                description='Vatsalya Guard Parent: family safety and device supervision.')
manifest_path.write_text(json.dumps(manifest, indent=4) + '\n')
print('Updated Android, iOS, web, macOS and Windows launcher icons.')
