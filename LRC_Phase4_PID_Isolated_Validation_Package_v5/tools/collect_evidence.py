#!/usr/bin/env python3
"""Collect only existing experiment evidence. Exclusive output creation."""
from pathlib import Path
import hashlib, json, sys, zipfile

def digest(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
    return h.hexdigest()

def collect(source,dest):
    source=Path(source).resolve(); dest=Path(dest).resolve()
    assert source.is_dir() and source.name.startswith('P4_RUN_'), 'Expected isolated P4_RUN_* directory'
    assert not dest.exists() and source not in dest.parents, 'Output must be new and outside result directory'
    files=sorted(f for f in source.rglob('*') if f.is_file())
    assert files and not any(f.is_symlink() for f in files), 'Empty or linked result tree'
    record=json.loads((source/'build_record.json').read_text())
    assert record['model']=='LRC_Phase4_PID_Isolated', 'Unexpected experiment model name'
    assert record['source_sha256']=='3833d3951b4c33ec265f54b8e91c4b4c4a65474fee357e8186fccc19ca992fd1'
    model=source/(record['model']+'.slx')
    assert digest(model)==record['model_sha256'], 'Experiment model differs from build record'
    required=['configuration_snapshot.json','build_diary.txt','convergence_comparison.json','fresh_comparison.json']
    for run in ['nominal_base','nominal_refined','stress_base','stress_refined','nominal_fresh']:
        required += [f'{run}/{f}' for f in ['run_declaration.json','native_simulation.mat','raw_timeseries.mat','assessment.json','completion.json','execution_diary.txt']]
    missing=[n for n in required if not (source/n).is_file()]
    names={f.relative_to(source).as_posix() for f in files}
    reserved={'SHA256SUMS_EXPERIMENT.txt','COLLECTION_STATUS.json'}
    assert not names & reserved, 'Collector-reserved name collision'
    initial={f.relative_to(source).as_posix():digest(f) for f in files}
    status={'classification':'COLLECTION_ONLY_NOT_ACCEPTANCE','missing_expected_files':missing,
            'scope_evidence_files':sorted(n for n in names if n.startswith('scope_evidence/')),
            'model_sha256':digest(model),'source_sha256':record['source_sha256'],
            'historical_original_manifest_model_sha256':'f1f32172e7970712af4bbe7060c71918eaea45cc59ebef1fa60f26dcfaf03c2f',
            'provenance_discrepancy':'UNRESOLVED','overall_project':'NOT ACCEPTED'}
    status_bytes=(json.dumps(status,indent=2)+'\n').encode()
    hashes=dict(initial); hashes['COLLECTION_STATUS.json']=hashlib.sha256(status_bytes).hexdigest()
    manifest=''.join(h+'  '+n+'\n' for n,h in sorted(hashes.items()))
    with zipfile.ZipFile(dest,'x',compression=zipfile.ZIP_DEFLATED,allowZip64=True) as z:
        for f in files: z.write(f,f.relative_to(source).as_posix())
        z.writestr('COLLECTION_STATUS.json',status_bytes)
        z.writestr('SHA256SUMS_EXPERIMENT.txt',manifest)
    assert all(digest(source/n)==h for n,h in initial.items()), 'Evidence changed during collection; discard new ZIP and investigate'
    with zipfile.ZipFile(dest) as z:
        assert z.testzip() is None
        for n,h in hashes.items():
            hh=hashlib.sha256()
            with z.open(n) as f:
                for b in iter(lambda:f.read(1024*1024),b''): hh.update(b)
            assert hh.hexdigest()==h, 'Archived-byte hash mismatch'
    print(str(dest)); print('SHA-256: '+digest(dest))
    print('Missing expected evidence: '+json.dumps(missing))
    print('Existing evidence collected only; no acceptance claim; no simulation or manifest rewrite.')

if __name__=='__main__':
    if len(sys.argv)!=3: raise SystemExit('Usage: collect_evidence.py P4_RUN_directory NEW_output.zip')
    try: collect(*sys.argv[1:])
    except Exception as e:
        print(f'COLLECTION FAILURE: {e}',file=sys.stderr); raise SystemExit(1)
