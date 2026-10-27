#!/usr/bin/env python3
"""Read-only verification: never imports a simulator or executes MATLAB."""
from pathlib import Path
import hashlib, json, sys

def digest(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
    return h.hexdigest()

def verify(root):
    root=Path(root).resolve()
    entries={}
    for line in (root/'SHA256SUMS.txt').read_text().splitlines():
        expected, rel=line.split('  ',1)
        assert len(expected)==64 and all(c in '0123456789abcdef' for c in expected), 'Malformed checksum'
        q=Path(rel)
        assert not q.is_absolute() and '..' not in q.parts and rel not in entries, 'Unsafe/duplicate entry'
        f=root/q
        assert f.is_file() and not f.is_symlink(), f'Missing or linked file: {rel}'
        assert root in f.resolve().parents, 'Path escapes package'
        assert digest(f)==expected, f'Hash mismatch: {rel}'
        entries[rel]=expected
    actual={x.relative_to(root).as_posix() for x in root.rglob('*') if x.is_file() and '__pycache__' not in x.parts}
    assert actual==set(entries)|{'SHA256SUMS.txt'}, 'Manifest coverage mismatch'
    assert entries['baseline/LRC_Phase2_OpenLoop.slx']=='3833d3951b4c33ec265f54b8e91c4b4c4a65474fee357e8186fccc19ca992fd1'
    assert entries['baseline/MASTER_EXECUTION_PROMPT.txt']=='c9a36231db3f0e50b1c1d4d29a394f3b431a501c29011d60fc19a246fbebb759'
    owner=json.loads((root/'OWNER_REVIEW_TEMPLATE.json').read_text())
    assert owner['construction_authorized'] is False and owner['simulation_authorized'] is False
    assert owner['proposed_criteria_approved'] is False and owner['supplemental_stress_approved'] is False
    recorded=json.loads((root/'STATIC_CHECKS.json').read_text())
    assert recorded['final_component_count']==len(entries), 'Recorded component count mismatch'
    assert owner['test_register_sha256']==entries['TEST_REGISTER.md']
    print(f'Static package integrity PASS: {len(entries)} component hashes; exact current model and master identity.')
    print('TEST_REGISTER SHA-256: '+entries['TEST_REGISTER.md'])
    print('Native construction, simulation, equivalence and acceptance remain UNVERIFIED. Overall NOT ACCEPTED.')
    return entries

if __name__=='__main__':
    try: verify(Path(__file__).resolve().parents[1] if len(sys.argv)==1 else sys.argv[1])
    except Exception as e:
        print(f'INTEGRITY FAILURE: {e}',file=sys.stderr); raise SystemExit(1)
