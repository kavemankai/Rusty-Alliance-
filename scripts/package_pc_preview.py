"""Package the accepted Windows PC slice without changing campaign saves."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT.parent / 'broken-marches-0.16.0-windows'
ARCHIVE = ROOT.parent / 'broken-marches-0.16.0-windows.zip'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    accepted = json.loads((ROOT / 'pc-acceptance-results.json').read_text(encoding='utf-8'))
    assert accepted['failed'] == 0 and accepted['counted_passed'] == 4166
    assert len(accepted['runs']) == 18
    for run in accepted['runs']:
        assert run['exit_code'] == 0 and run['failed'] == 0
        assert digest(ROOT / run['report']) == run['report_sha256'], run['suite']
        log = (ROOT / run['log']).read_text(encoding='utf-8-sig')
        assert 'SCRIPT ERROR:' not in log and '\nERROR:' not in log
    for name, expected in accepted['source_lf_sha256'].items():
        data = (ROOT / name).read_bytes().replace(b'\r\n', b'\n')
        assert hashlib.sha256(data).hexdigest() == expected, name
    for name, expected in accepted['verified_binary_sha256'].items():
        assert digest(FOLDER / name) == expected, name
    assert accepted['release_launch']['exit_code'] == 0
    assert accepted['isolated_pack']['exit_code'] == 0 and accepted['isolated_pack']['failed'] == 0
    for name in ['PC_VALIDATION.md', 'PC_VERTICAL_SLICE.md', 'pc-acceptance-results.json',
                 'THIRD_PARTY_NOTICES.txt']:
        shutil.copy2(ROOT / name, FOLDER / name)
    shutil.copy2(ROOT / 'assets/greywake/PROVENANCE.txt', FOLDER / 'GREYWAKE_ART_PROVENANCE.txt')
    for path in ROOT.glob('pc-*-preview.png'):
        shutil.copy2(path, FOLDER / path.name)
    for run in accepted['runs']:
        shutil.copy2(ROOT / run['report'], FOLDER / run['report'])
    shutil.copytree(ROOT / 'evidence/pc-0.16.0', FOLDER / 'evidence/pc-0.16.0', dirs_exist_ok=True)
    (FOLDER / 'START HERE.txt').write_text(
        'The Broken Marches 0.16.0 - PC vertical slice\n\n'
        'Run The Broken Marches.exe with The Broken Marches.pck beside it.\n'
        'New Game: Greywake opening. New campaign: original campaign.\n'
        'Left click: select/preview. Enter: confirm. Space: end turn. R: reload. G: guard.\n'
        'Middle drag/WASD/arrows: camera. Wheel: zoom. F: center. Home: reset.\n'
        '1-9/Tab/Shift+Tab: fighters. Escape: cancel then Settings.\n'
        'F5/Ctrl+S: save. F9: confirmed load. F1: help. F11: fullscreen.\n'
        'Settings: display, render scale, frame limit and remappable keys.\n\n'
        '4166 counted assertions, zero failures; two further UI suites report zero failures.\n'
        'See PC_VALIDATION.md for exact scope, measurements and limitations.\n'
        'This is the existing playable slice, not the full Greywake campaign or final art/audio.\n',
        encoding='utf-8')
    files = sorted(p for p in FOLDER.rglob('*') if p.is_file())
    with zipfile.ZipFile(ARCHIVE, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in files:
            archive.write(path, path.relative_to(FOLDER).as_posix())
    with zipfile.ZipFile(ARCHIVE) as archive:
        assert archive.testzip() is None, 'ZIP CRC failure'
    result = dict(version=accepted['version'], artifact=ARCHIVE.name,
                  bytes=ARCHIVE.stat().st_size, sha256=digest(ARCHIVE), crc_ok=True,
                  files={str(p.relative_to(FOLDER)).replace('\\', '/'): digest(p) for p in files},
                  assertions_passed=accepted['counted_passed'], failed=0,
                  android_acceptance=False)
    (ROOT / 'pc-release-results.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: v for k, v in result.items() if k != 'files'}, indent=2))


if __name__ == '__main__':
    main()
