"""Check the decoded OPL phrases against build/soundcmp/regs.csv (tools/soundcmp.py).

Usage: python tools/soundcheck.py CMD [CMD ...]
For the first three YM3526 channels of each command: the key-on times, fitted to one tick
period, against the decoded steps' cumulative durations.
"""
import csv,json,sys
import romset
R=romset.ROOT
c=json.load(open(R/'build'/'sound'/'commands.json'))
rows=[(r[0],float(r[1]),r[2],int(r[3])&1,int(r[4],16)) for r in csv.reader(open(R/'build'/'soundcmp'/'regs.csv')) if r[0]]
def exp(cmd):
    out={}
    for b in c[cmd]['items']:
        if 'queue' in b or b.get('now') or not b['record'].startswith('OPL') or not b['record'].endswith('A'): continue
        ch=int(b['record'].split()[1][2:])-1
        t=0;seq=[]
        for _ in range(b['passes']):
            for ph in b['phrases']:
                for _ in range(ph['repeats'] or 1):
                    for s in ph['steps']:
                        if any('note' in e for e in s['events']): seq.append(t)
                        t+=s['dur'] or 0
        out[ch]=seq
    return out
for cmd in sys.argv[1:]:
    reg=None;on={}
    state={}
    for c_,t,chip,p,v in rows:
        if c_!=cmd or chip!='opl':continue
        if p==0:reg=v
        elif 0xB0<=reg<=0xB8:
            ch=reg-0xB0; was=state.get(ch,0)
            if v&0x20 and not was: on.setdefault(ch,[]).append(t)
            state[ch]=v&0x20
    ex=exp(cmd)
    for ch in sorted(ex)[:3]:
        obs=on.get(ch,[]); seq=ex[ch]
        print(cmd,'ch',ch+1,'expected',len(seq),'observed',len(obs),'(last 40 ticks:',seq[:8],')')
        if len(obs)>1 and len(seq)>1:
            n=min(len(obs),len(seq)); 
            m_s=sum(seq[:n])/n; m_o=sum(obs[:n])/n
            tick=sum((a-m_s)*(b-m_o) for a,b in zip(seq[:n],obs[:n]))/sum((a-m_s)**2 for a in seq[:n]); res=[(o-obs[0])/tick-s_ for o,s_ in zip(obs[:n],seq[:n])]
            res=[r-res[0] for r in res]
            print('   tick %.5f s, residual ticks: max %.2f, first bad index %s'%(tick,max(abs(r) for r in res),next((i for i,r in enumerate(res) if abs(r)>1.5),None)))
