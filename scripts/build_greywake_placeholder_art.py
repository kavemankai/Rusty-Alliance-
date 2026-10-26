"""Original temporary vector plates, replaceable by the approved production art pack."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1];out=root/'assets/greywake';out.mkdir(parents=True,exist_ok=True)
head='''<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="900" viewBox="0 0 1600 900"><defs><linearGradient id="night" x2="0" y2="1"><stop stop-color="#101d24"/><stop offset="1" stop-color="#655c53"/></linearGradient><radialGradient id="warm"><stop stop-color="#b7803b"/><stop offset=".7" stop-color="#513326"/><stop offset="1" stop-color="#211c1c"/></radialGradient><linearGradient id="wood" x2="0" y2="1"><stop stop-color="#63432b"/><stop offset="1" stop-color="#261f1a"/></linearGradient><pattern id="mail" width="10" height="10" patternUnits="userSpaceOnUse"><rect width="10" height="10" fill="#555c5c"/><path d="M0 5 Q5 0 10 5 Q5 10 0 5" fill="none" stroke="#91918a" stroke-width="1"/></pattern></defs>'''
def save(name,parts): (out/name).write_text(head+''.join(parts)+'</svg>',encoding='utf8')
def rect(x,y,w,h,fill,stroke=None):return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}"'+(f' stroke="{stroke}" stroke-width="3"' if stroke else '')+'/>'
def path(d,fill,stroke=None):return f'<path d="{d}" fill="{fill}"'+(f' stroke="{stroke}" stroke-width="4"' if stroke else '')+'/>'
def ellipse(x,y,rx,ry,fill):return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}"/>'
def candle(x,y):return rect(x-7,y,14,45,'#c4ad74')+ellipse(x,y-12,7,17,'#efc86b')+ellipse(x,y+46,27,7,'#241b16')
def tank(x,y):return rect(x-15,y,30,42,'#88755a','#221c16')+path(f'M{x+15} {y+7} Q{x+47} {y+19} {x+15} {y+33}','none','#8f8066')
# Tavern: beams, windows, fire, floor boards and distinct vignettes; no baked labels.
p=[rect(0,0,1600,900,'url(#warm)')]
for x in range(0,1600,200): p.append(rect(x,0,22,610,'#221c18','#765335'))
for y in [70,140,550]:p.append(rect(0,y,1600,24,'#2c221b','#765335'))
for x in [430,660]:p.extend([rect(x,160,150,210,'#192e36','#aa8760'),path(f'M{x+75} 160 V370 M{x} 250 H{x+150}','none','#755238')])
p.extend([path('M0 620 L1600 620 V900 H0 Z','url(#wood)')])
for x in range(-600,2200,130):p.append(path(f'M800 550 L{x} 900','none','#251d17'))
for y in [690,760,850]:p.append(path(f'M0 {y} H1600','none','#31251a'))
p.extend([rect(925,220,190,280,'#443b33','#897057'),path('M953 480 V330 Q1020 225 1087 330 V480 Z','#171c1e'),path('M978 480 Q962 426 1004 387 Q993 440 1026 407 Q1070 454 1053 480 Z','#d38b42'),rect(1390,250,210,360,'#493022','#9e7040')])
for x,y,rx in [(300,665,230),(755,590,215),(1250,440,135)]:
 p.extend([rect(x-rx+40,y+20,25,165,'#2d2119'),rect(x+rx-65,y+20,25,165,'#2d2119'),ellipse(x,y,rx,60,'#211915'),ellipse(x,y-13,rx,57,'#8a6037'),ellipse(x,y-19,rx-12,46,'#715133')])
 p.extend([candle(x,y-90),tank(x+65,y-60)])
positions={'militia_spearman':(.15,.56),'militia_crossbowman':(.27,.60),'mara':(.42,.53),'oswin':(.52,.50),'ada':(.10,.30),'bram':(.66,.72),'elin':(.65,.30),'nessa':(.36,.29),'garran':(.86,.50),'sabine':(.87,.65),'roderic':(.79,.35),'ysra':(.48,.25)}
rows=json.loads((root/'data/greywake_roster.json').read_text())['templates']
for i,row in enumerate(rows):
 x,y=positions[row['id']];x=int(x*1600);y=int(y*900)
 cloth={'clothing':'#847159','padded':'#967c56','leather':'#614c35','mail':'url(#mail)','plate':'#a0a39a'}[row['armour']]
 p.extend([ellipse(x,y+63,57,16,'#241e19'),path(f'M{x-20} {y+10} L{x-31} {y+69} H{x-8} L{x+3} {y+30} L{x+15} {y+70} H{x+34} L{x+24} {y+7} Z','#302c27'),path(f'M{x-31} {y-65} Q{x} {y-81} {x+31} {y-65} L{x+43} {y+20} L{x-43} {y+20} Z',cloth,'#282622'),ellipse(x,y-93,22,29,'#a48a65'),path(f'M{x-23} {y-96} Q{x-28} {y-140} {x+24} {y-114} L{x+23} {y-87} L{x+12} {y-109} L{x-21} {y-101} Z','#3d352b'),path(f'M{x-35} {y-55} L{x-53} {y-1} L{x-34} {y+4} M{x+34} {y-55} L{x+53} {y-8} L{x+33} {y+1}',cloth,'#282622'),rect(x-35,y-4,70,8,'#30291f')])
 if row.get('shield'):p.append(path(f'M{x-50} {y-31} L{x-10} {y-22} L{x-10} {y+13} Q{x-30} {y+45} {x-50} {y+9} Z','#7c795f','#c0a76b'))
 if row['weapon']=='spear':p.extend([path(f'M{x+52} {y+65} L{x+71} {y-141}','none','#ae8e57'),path(f'M{x+70} {y-163} L{x+61} {y-130} L{x+76} {y-129} Z','#bec2b5')])
 elif row['weapon'] in ['bow','crossbow']:p.append(path(f'M{x+43} {y-99} Q{x+105} {y-18} {x+43} {y+55} L{x+43} {y-99}','none','#bc9b62'))
 elif row['weapon'] in ['sword','dagger','mace']:p.extend([path(f'M{x+42} {y+42} L{x+62} {y-39}','none','#bcc3bd'),path(f'M{x+43} {y+19} L{x+66} {y+25}','none','#c7a164')])
# Non-recruit sparring partner makes the brawl a readable paired vignette.
p.extend([path('M1190 630 L1140 700 L1190 760 L1230 720 L1260 670 Z','#604a39','#201d19'),ellipse(1218,610,23,28,'#9d7955'),path('M1170 660 L1110 620 L1070 650','none','#9d7955')])
save('tavern.svg',p)
# First-person employer composition; the face is entirely shadowed.
p=[rect(0,0,1600,900,'url(#warm)')]
for x in [160,400,1100,1400]:p.append(rect(x,0,25,650,'#25211d','#604b33'))
p.extend([rect(0,90,1600,26,'#28221b'),path('M530 670 L580 320 Q800 110 1020 320 L1100 670 Z','#262928','#141917'),path('M641 341 Q800 152 951 341 L918 474 Q800 559 678 463 Z','#10191c','#3b3d36'),path('M690 357 Q800 226 905 358 L869 470 Q800 495 720 455 Z','#090f13'),path('M0 640 L1600 640 V900 H0 Z','url(#wood)','#8c693f'),ellipse(800,705,470,100,'#4a3425'),candle(485,550),tank(1130,640),path('M720 680 L730 616 L790 593 L850 628 L862 684 Q790 725 720 680 Z','#796440','#332b22')])
for x,y in [(810,710),(850,726),(880,701)]:p.append(ellipse(x,y,15,6,'#c5a260'))
save('employer.svg',p)
p=[rect(0,0,1600,900,'url(#night)'),ellipse(1150,180,110,110,'#9b9b83'),path('M0 540 L80 490 L150 518 L200 440 L320 450 L420 330 L480 394 L610 290 L710 379 L810 364 L900 465 L1070 458 L1160 516 L1290 490 L1430 541 L1600 490 V900 H0 Z','#293634'),rect(0,610,1600,290,'#243d47')]
for y in range(620,900,35):
 for x in range(0,1600,220):p.append(path(f'M{x} {y} Q{x+80} {y-12} {x+160} {y+2}','none','#67746b'))
p.extend([path('M410 730 Q750 870 1150 728 L1050 830 Q780 935 500 826 Z','#211e1c','#997f58'),path('M785 726 L790 227','none','#8f7956'),path('M800 250 Q1120 430 1050 654 L800 635 Z','#acaa92','#544d3c'),path('M782 300 L572 663 H776 Z','#777f76','#544d3c')])
save('voyage.svg',p)
if not (out/'PROVENANCE.txt').exists(): (out/'PROVENANCE.txt').write_text('''# Temporary Greywake opening art

The requested Greywake_Opening_Art_ProductionPack_v02.zip was not found in the task workspace or Downloads during the initial audit. No files from that package are claimed as imported or approved.

These four SVG plates are original, deliberately temporary vector illustrations for this project. The employer, tavern and voyage plates are generated by scripts/build_greywake_placeholder_art.py; island.svg is a separately authored vector based on the canonical land mask. They contain no baked dialogue, names, prices or statistics. Tavern silhouettes show broad loadout categories and are not approved identity portraits. Native hotspots and profile data reference the actual twelve roster IDs. Profile role thumbnails reuse the documented Quaternius CC0 icons; they are labelled role portraits and are not presented as identity-matched commissioned portraits. No portrait likeness/biography was invented.

Replace these plates and role thumbnails after the production archive can be inspected for provenance, resolution, suitability and roster mapping. All audio remains missing; no unavailable ambience is claimed. The live island view keeps base illustration, location labels/icons, ownership, fog, company and route overlays separate.
''',encoding='utf8')
print('Created 3 original temporary SVG plates (island.svg is separately authored); no production art archive imported.')
