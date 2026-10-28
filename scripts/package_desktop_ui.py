"""Package only the recorded, verified 0.17 desktop artifact and evidence."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT.parent / 'broken-marches-0.17.0-windows'
ARCHIVE = ROOT.parent / 'broken-marches-0.17.0-windows.zip'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    proof = json.loads((ROOT / 'desktop-ui-017-results.json').read_text(encoding='utf-8'))
    assert proof['failed'] == 0 and proof['counted_passed'] == 7522
    assert len(proof['runs']) == 20
    for run in proof['runs']:
        assert run['exit_code'] == 0 and run['failed'] == 0
        assert sha(ROOT / run['report']) == run['report_sha256'], run['suite']
        body = (ROOT / run['log']).read_text(encoding='utf-8-sig')
        assert 'SCRIPT ERROR:' not in body and '\nERROR:' not in body, run['suite']
    for name, expected in proof['source_lf_sha256'].items():
        content = (ROOT / name).read_bytes().replace(b'\r\n', b'\n')
        assert hashlib.sha256(content).hexdigest() == expected, name
    for name, expected in proof['asset_sha256'].items():
        assert sha(ROOT / name) == expected, name
    for name, expected in proof['verified_binary_sha256'].items():
        assert sha(FOLDER / name) == expected, name
    assert proof['isolated_pack']['failed'] == 0 and proof['isolated_pack']['exit_code'] == 0
    assert proof['native_release']['exit_code'] == 0
    for name in ['DESKTOP_UI_017_STATUS.md', 'TAVERN_SELECTION_STATUS.md',
                 'desktop-ui-017-results.json', 'THIRD_PARTY_NOTICES.txt']:
        shutil.copy2(ROOT / name, FOLDER / name)
    for name in ['TAVERN_ART_V2.md', 'TAVERN_IMAGE_PROMPT.txt', 'PROVENANCE.txt']:
        shutil.copy2(ROOT / 'assets/greywake' / name, FOLDER / name)
    shutil.copytree(ROOT / 'evidence/desktop-0.17.0', FOLDER / 'evidence/desktop-0.17.0', dirs_exist_ok=True)
    for run in proof['runs']:
        shutil.copy2(ROOT / run['report'], FOLDER / run['report'])
    for picture in ROOT.glob('desktop-017-*-preview.jpg'):
        shutil.copy2(picture, FOLDER / picture.name)
    (FOLDER / 'START HERE.txt').write_text(
        'The Broken Marches 0.17.0 - desktop interface update\n\n'
        'Run The Broken Marches.exe with The Broken Marches.pck beside it.\n'
        'New Game: Greywake opening. New campaign: original campaign.\n'
        'Tavern: click a person in the painting or their name to view the same profile.\n'
        'Battle: crew and equipment are below the field. Details opens the full inspector.\n'
        'Click a tile/visible target or right-click the field for contextual radial choices.\n'
        'Escape/Cancel closes the radial; Tab/arrows and Enter navigate it.\n'
        'Gold marks the active fighter; red marks the selected visible enemy.\n'
        'Middle drag/WASD/arrows pan, wheel zooms, F centers, Home resets.\n'
        'F1 help, F5 save, F9 confirmed load, F11 fullscreen.\n\n'
        '7522 counted assertions passed, zero failed. See DESKTOP_UI_017_STATUS.md\n'
        'for exact scope, measurements and remaining campaign/art/device work.\n',
        encoding='utf-8')
    files = sorted(p for p in FOLDER.rglob('*') if p.is_file())
    with zipfile.ZipFile(ARCHIVE, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in files:
            archive.write(path, path.relative_to(FOLDER).as_posix())
    with zipfile.ZipFile(ARCHIVE) as archive:
        assert archive.testzip() is None
    result = dict(version=proof['version'], artifact=ARCHIVE.name, bytes=ARCHIVE.stat().st_size,
                  sha256=sha(ARCHIVE), crc_ok=True, counted_passed=proof['counted_passed'], failed=0,
                  files={p.relative_to(FOLDER).as_posix(): sha(p) for p in files}, android_acceptance=False)
    (ROOT / 'desktop-ui-017-release.json').write_bytes((json.dumps(result, indent=2) + '\n').encode('utf-8'))
    print(json.dumps({k: v for k, v in result.items() if k != 'files'}, indent=2))


if __name__ == '__main__':
    main()
