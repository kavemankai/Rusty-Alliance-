"""Reproducible release-content checks; not a legal independence determination."""
import argparse, hashlib, io, json, pathlib, re, subprocess, zipfile
parser=argparse.ArgumentParser()
parser.add_argument('--reference',type=pathlib.Path,required=True)
parser.add_argument('--apk',type=pathlib.Path,required=True)
parser.add_argument('--source',type=pathlib.Path)
parser.add_argument('--output',type=pathlib.Path,default=pathlib.Path('release-audit.json'))
args=parser.parse_args();root=pathlib.Path(__file__).resolve().parent.parent
checks=[]
def check(ok,name,details=None):
 checks.append({'name':name,'passed':bool(ok),'details':details})
def digest(blob): return hashlib.sha256(blob).hexdigest()
ref_revision=subprocess.check_output(['git','-C',str(args.reference),'rev-parse','HEAD'],text=True).strip()
reference={}
for path in args.reference.rglob('*'):
 if path.is_file() and '.git' not in path.parts and path.stat().st_size>=512:
  reference.setdefault(digest(path.read_bytes()),[]).append(path.relative_to(args.reference).as_posix())
committed=zipfile.ZipFile(io.BytesIO(subprocess.check_output(['git','archive','--format=zip','HEAD'],cwd=root)))
files=[n for n in committed.namelist() if not n.endswith('/')]
manifest=[];matches=[];sensitive=[]
for name in files:
 blob=committed.read(name);sha=digest(blob)
 manifest.append({'path':name,'bytes':len(blob),'sha256':sha})
 if sha in reference: matches.append({'project':name,'reference':reference[sha]})
 if pathlib.Path(name).suffix.lower() in ['.keystore','.jks','.p12','.pfx','.key'] or re.search(rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----\s*\r?\n[A-Za-z0-9+/=\r\n]+-----END',blob): sensitive.append(name)
check(not matches,'No byte-identical reference files of at least 512 bytes',matches)
check(not sensitive,'No signing/private-key material in tracked source',sensitive)
check(not any(n.startswith(('work/','.git/')) or n.lower().endswith(('.c','.cpp','.h','.exe','.dll')) for n in files),'Tracked project excludes reference checkout and native research binaries')
with zipfile.ZipFile(args.apk) as apk:
 names=apk.namelist()
 forbidden=[n for n in names if pathlib.Path(n).suffix.lower() in ['.c','.cpp','.h','.exe','.keystore','.jks']]
 debug_reports=[n for n in names if re.search(r'(?:profile-(?:baseline|current)|(?:ui-test|test|extended)-results)\.json$',n)]
 check(not forbidden,'APK excludes native source/research/signing files',forbidden)
 check(not debug_reports,'APK excludes development result/profile JSON files',debug_reports)
 check(not any(n.startswith(('assets/builds/','assets/tests/','assets/scripts/')) for n in names),'APK excludes build outputs and test/authoring scripts')
 check(any(n.endswith('THIRD_PARTY_NOTICES.txt') for n in names),'APK includes engine/third-party notices')
 check('AndroidManifest.xml' in names and any(n.startswith('lib/arm64-v8a/') for n in names),'APK has Android manifest and arm64 runtime')
if args.source:
 with zipfile.ZipFile(args.source) as archive:
  names=archive.namelist()
  check(not any(n.startswith(('/', 'work/', '.git/')) or '..' in pathlib.PurePosixPath(n).parts for n in names),'Source archive excludes research and unsafe paths')
  missing=[entry['path'] for entry in manifest if entry['path'] not in names]
  changed=[entry['path'] for entry in manifest if entry['path'] in names and digest(archive.read(entry['path']))!=entry['sha256']]
  check(not missing and not changed,'Source archive exactly matches tracked source',{'missing':missing,'changed':changed})
artifacts={'apk':{'name':args.apk.name,'sha256':digest(args.apk.read_bytes())}}
if args.source: artifacts['source']={'name':args.source.name,'sha256':digest(args.source.read_bytes())}
report={'artifacts':artifacts,'reference_revision':ref_revision,'project_revision':subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),'passed':sum(c['passed'] for c in checks),'failed':sum(not c['passed'] for c in checks),'checks':checks,'manifest':manifest,'limits':['Byte identity checks cannot establish originality, clean-room status, ownership or commercial rights.','Engine notices are generated from the installed engine; no game licence is granted.','Commercial rights review and release signing approval remain external acceptance gates.']}
args.output.write_text(json.dumps(report,indent=2),encoding='utf-8')
print('RELEASE AUDIT: %d passed, %d failed' % (report['passed'],report['failed']))
raise SystemExit(1 if report['failed'] else 0)
