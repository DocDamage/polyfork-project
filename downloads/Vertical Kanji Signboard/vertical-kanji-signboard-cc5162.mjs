/*
 * Vertical Kanji Signboard
 * https://polyfork.dev/asset/vertical-kanji-signboard-cc5162
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './vertical-kanji-signboard-cc5162.mjs';
 *   scene.add(createAsset());
 *
 * The bare "three" specifiers below resolve through any bundler, or through
 * an importmap in your page:
 *
 *   { "imports": { "three": "https://unpkg.com/three@0.180.0/build/three.module.js",
 *                  "three/addons/": "https://unpkg.com/three@0.180.0/examples/jsm/" } }
 *
 * Browsers refuse to load ES modules from file:// URLs, so a page of your own
 * that imports this file has to be served over http:  python3 -m http.server
 *
 * The index.html in this asset's .zip download sidesteps that and opens with
 * a double-click. The store page above has the same snippet for Unity, Godot,
 * Blender and GLB.
 *
 * OPTIONS  createAsset({ ... })
 *
 *   colorway    choice  'shoten-cream' 'shoten-cream' | 'lacquer-black' | 'matcha-green' | 'sakura-pink'
 *   frame       color   '#8C7355'      any hex or THREE.Color
 *   field       color   '#D9CFBC'      any hex or THREE.Color
 *   inkTop      color   '#8E1F1B'      any hex or THREE.Color
 *   inkBottom   color   '#3C4145'      any hex or THREE.Color
 *   plate       color   '#A9AFB4'      any hex or THREE.Color
 *   characters  range   4              2 to 4
 *   mount       choice  'blade'        'blade' | 'flush'
 *
 * Every option is described in full at https://polyfork.dev/cdn/vertical-kanji-signboard-cc5162-params.json
 *
 * SPECS  330 triangles, 1 material, 0.69 x 2.4 x 0.16 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const params = {
  colorway: {
    type: 'choice', default: 'shoten-cream', label: 'Colorway',
    options: ['shoten-cream', 'lacquer-black', 'matcha-green', 'sakura-pink'],
    describe: 'curated painted-sign scheme for the whole board. shoten-cream is the '
            + 'approved default: warm softwood frame, aged paper face, oxblood upper '
            + 'characters over indigo lower ones. lacquer-black is a near-black frame '
            + 'around a bright white face for a modern shopfront; matcha-green puts a '
            + 'deep green frame on an off-white face with all-dark ink; sakura-pink is '
            + 'a seasonal blossom-pink face in a dark stained frame. The face stays '
            + 'PALE in every scheme, because it is the surface that lights up at night.',
  },
  frame: {
    type: 'color', default: '#8C7355', label: 'Frame timber',
    describe: 'albedo of the milled timber frame — the band on all four sides of both '
            + 'faces, the outer edge, the chamfer and the two bracket arms. It rings '
            + 'the whole silhouette, so it needs a clear value step DOWN from the paper '
            + 'face or the board loses its border and reads as a bare sheet.',
  },
  field: {
    type: 'color', default: '#D9CFBC', label: 'Paper face',
    describe: 'albedo of the paper/acrylic panel recessed 30 mm inside the frame, front '
            + 'and back. The largest zone and the background the characters are read '
            + 'against, so it must stay PALE and well clear in value of both inks. This '
            + 'is also the zone declared lit after dark (see export const night): a warm '
            + 'lamp glow behind the pane, the way an andon-kanban lights at night.',
  },
  inkTop: {
    type: 'color', default: '#8E1F1B', label: 'Upper ink',
    describe: 'albedo of the upper HALF of the character column (2 of 4 by default) — '
            + 'oxblood red in the reference. Half of the graphic identity; keep it dark '
            + 'and saturated against the paper, and distinct in HUE from the lower ink '
            + 'so the two-tone split reads at street distance.',
  },
  inkBottom: {
    type: 'color', default: '#3C4145', label: 'Lower ink',
    describe: 'albedo of the lower characters — a cool blue-black slate standing in for '
            + 'the reference\'s indigo. It must carry the SAME WEIGHT against the paper '
            + 'as inkTop does (both land near value 65 of 255 on a 204 field): a mid-value '
            + 'indigo here reads as a faded half of the column rather than as a second '
            + 'ink. Painted onto the same plane as the paper face, so any value works, '
            + 'but keep it dark and keep it clear of inkTop in hue.',
  },
  plate: {
    type: 'color', default: '#A9AFB4', label: 'Wall plates',
    describe: 'albedo of the two steel plates at the outboard end of the bracket arms — '
            + 'the surfaces that bolt to the facade. Mill-finish grey, kept a clear step '
            + 'LIGHTER than the timber arms so each bracket reads as two parts rather '
            + 'than one brown stub.',
  },
  characters: {
    type: 'range', default: 4, min: 2, max: 4, step: 1, affects: 'geometry',
    label: 'Characters',
    describe: 'how many kanji the board carries, and therefore HOW TALL IT IS. The board '
            + 'is REBUILT, never stretched: a character cell is always 0.380 m square at '
            + 'a constant 0.500 m pitch, and the frame band, board depth, field recess, '
            + 'stroke width and bracket sections are identical at every value — only the '
            + 'number of cells changes, so the triangle count steps with the knob. '
            + 'Height = 0.40 + 0.50 x characters: 2 gives a 1.40 m board reading 東京 '
            + '(Tokyo), 3 a 1.90 m board reading 大東京 (Greater Tokyo), 4 the approved '
            + '2.40 m board reading 東京中央 (Tokyo Central). The upper half of the '
            + 'column always takes inkTop and the rest inkBottom. The two brackets stay '
            + 'symmetric about mid-height at 0.271 of the height either side.',
  },
  mount: {
    type: 'choice', default: 'blade', affects: 'geometry', label: 'Mount',
    options: ['blade', 'flush'],
    describe: 'which way the two brackets carry the board off the facade. blade (the '
            + 'default, and what refs/hero.png shows) runs the arms sideways out of the '
            + 'board LEFT edge so the sign projects perpendicular from the wall and '
            + 'reads along the street — the plates stand 0.185 m clear on -X and are '
            + 'visible in the silhouette. flush runs the same two arms REARWARD out of '
            + 'the back face so the board hangs parallel to the wall, 0.185 m off it, '
            + 'with nothing breaking the front outline. Same board, same origin, same '
            + 'palette either way; only the bracket axis moves.',
  },
};
for (const k of Object.keys(params)) if (!params[k].affects) params[k].affects = 'colors';

const COLORWAYS = {

  'shoten-cream':  { frame: '#8C7355', field: '#D9CFBC', inkTop: '#8E1F1B', inkBottom: '#3C4145', plate: '#A9AFB4' },
  'lacquer-black': { frame: '#2E3134', field: '#F2EFE7', inkTop: '#B5462F', inkBottom: '#42352A', plate: '#6B7278' },
  'matcha-green':  { frame: '#2F6B4F', field: '#E4E2DC', inkTop: '#8E1F1B', inkBottom: '#42352A', plate: '#8A9197' },
  'sakura-pink':   { frame: '#63503C', field: '#F7C9D6', inkTop: '#8E1F1B', inkBottom: '#3C4145', plate: '#C7CBCC' },
};
export const presets = COLORWAYS;

function resolve(user = {}) {
  const p = {};
  for (const [k, spec] of Object.entries(params)) p[k] = spec.default;
  Object.assign(p, COLORWAYS[user.colorway ?? p.colorway] ?? {});
  for (const k of Object.keys(params)) if (user[k] !== undefined) p[k] = user[k];
  const hex = (s) => (typeof s === 'string' ? parseInt(s.replace('#', ''), 16) : s);
  const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, Number(v)));
  return {
    C: {
      frame: hex(p.frame), field: hex(p.field), inkTop: hex(p.inkTop),
      inkBottom: hex(p.inkBottom), plate: hex(p.plate),
    },
    N: Math.round(clamp(p.characters, 2, 4)),
    blade: (p.mount === 'flush' ? false : true),
  };
}

const W = 0.500, HW = W / 2;
const DEPTH = 0.160, HD = DEPTH / 2;
const FRAME = 0.060;
const RECESS_F = 0.030;
const RECESS_B = 0.045;

const CH = 0.012;

const FIELD_W = W - 2 * FRAME;
const CELL_W = 0.320;
const CELL_H = 0.380;

const STROKE = 0.049;

const CGAP = 0.120;
const MARGIN = 0.200;

const heightFor = (N) => 2 * FRAME + 2 * MARGIN + N * CELL_H + (N - 1) * CGAP;

const ARM_W = 0.090, ARM_H = 0.110, ARM_L = 0.140;
const PLATE_W = 0.120, PLATE_H = 0.210, PLATE_T = 0.045;
const BED = 0.020;
const PBED = 0.015;
const BRACKET_F = 0.271;

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}
function prep(geo, hex) {
  if (geo.index) geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const c = new THREE.Color(hex);
  const n = geo.attributes.position.count;
  const col = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { col[i * 3] = c.r; col[i * 3 + 1] = c.g; col[i * 3 + 2] = c.b; }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return geo;
}

function boxFaces(out, x0, x1, y0, y1, z0, z1, skip = '') {
  if (!skip.includes('+x')) quad(out, [x1, y0, z1], [x1, y0, z0], [x1, y1, z0], [x1, y1, z1]);
  if (!skip.includes('-x')) quad(out, [x0, y0, z0], [x0, y0, z1], [x0, y1, z1], [x0, y1, z0]);
  if (!skip.includes('+y')) quad(out, [x0, y1, z1], [x1, y1, z1], [x1, y1, z0], [x0, y1, z0]);
  if (!skip.includes('-y')) quad(out, [x0, y0, z0], [x1, y0, z0], [x1, y0, z1], [x0, y0, z1]);
  if (!skip.includes('+z')) quad(out, [x0, y0, z1], [x1, y0, z1], [x1, y1, z1], [x0, y1, z1]);
  if (!skip.includes('-z')) quad(out, [x1, y0, z0], [x0, y0, z0], [x0, y1, z0], [x1, y1, z0]);
}

const rectCorners = (x0, x1, y0, y1) => [[x0, y0], [x1, y0], [x1, y1], [x0, y1]];

function prismWall(out, corners, z0, z1, outward = true) {
  for (let i = 0; i < corners.length; i++) {
    const p = corners[i], q = corners[(i + 1) % corners.length];
    if (outward) quad(out, [p[0], p[1], z0], [q[0], q[1], z0], [q[0], q[1], z1], [p[0], p[1], z1]);
    else quad(out, [q[0], q[1], z0], [p[0], p[1], z0], [p[0], p[1], z1], [q[0], q[1], z1]);
  }
}

function ring(out, outer, inner, z, front = true) {
  for (let i = 0; i < 4; i++) {
    const o0 = outer[i], o1 = outer[(i + 1) % 4], i1 = inner[(i + 1) % 4], i0 = inner[i];
    if (front) quad(out, [o0[0], o0[1], z], [o1[0], o1[1], z], [i1[0], i1[1], z], [i0[0], i0[1], z]);
    else quad(out, [o0[0], o0[1], z], [i0[0], i0[1], z], [i1[0], i1[1], z], [o1[0], o1[1], z]);
  }
}

function skirt(out, outer, zOuter, inner, zInner) {
  for (let i = 0; i < 4; i++) {
    const o0 = outer[i], o1 = outer[(i + 1) % 4], i1 = inner[(i + 1) % 4], i0 = inner[i];
    quad(out, [o0[0], o0[1], zOuter], [o1[0], o1[1], zOuter],
              [i1[0], i1[1], zInner], [i0[0], i0[1], zInner]);
  }
}

const SU = STROKE / CELL_W, SV = STROKE / CELL_H;
const hbar = (v, u0, u1) => [u0, u1, v - SV / 2, v + SV / 2];
const vbar = (u, v0, v1) => [u - SU / 2, u + SU / 2, v0, v1];

const ring4 = (u0, u1, v0, v1) => [
  hbar(v0 + SV / 2, u0, u1), hbar(v1 - SV / 2, u0, u1),
  vbar(u0 + SU / 2, v0, v1), vbar(u1 - SU / 2, v0, v1),
];
const GLYPHS = {

  '東': [
    vbar(0.500, 0.000, 0.930),
    hbar(0.930, 0.060, 0.940),
    ...ring4(0.200, 0.800, 0.225, 0.800),
    hbar(0.5125, 0.200, 0.800),
    vbar(0.150, 0.000, 0.290), vbar(0.850, 0.000, 0.290),
  ],

  '京': [
    vbar(0.500, 0.905, 1.000),
    hbar(0.855, 0.070, 0.930),
    ...ring4(0.260, 0.740, 0.400, 0.730),
    vbar(0.500, 0.020, 0.330),
    vbar(0.185, 0.050, 0.280), vbar(0.815, 0.050, 0.280),
  ],

  '中': [
    vbar(0.500, 0.000, 1.000),
    ...ring4(0.185, 0.815, 0.215, 0.780),
  ],

  '央': [
    hbar(0.885, 0.160, 0.840),
    vbar(0.2366, 0.600, 0.885), vbar(0.7634, 0.600, 0.885),
    hbar(0.635, 0.050, 0.950),
    vbar(0.500, 0.190, 0.885),
    vbar(0.145, 0.000, 0.600), vbar(0.855, 0.000, 0.600),
  ],

  '大': [
    hbar(0.665, 0.060, 0.940),
    vbar(0.500, 0.270, 1.000),
    vbar(0.135, 0.000, 0.665), vbar(0.865, 0.000, 0.665),
  ],
};

const WORDS = {
  2: ['東', '京'],
  3: ['大', '東', '京'],
  4: ['東', '京', '中', '央'],
};

const EPS = 1e-6;
function paintField(bufs, x0, x1, y0, y1, z, marks) {
  const ys = new Set([y0, y1]);
  for (const m of marks) {
    if (m.y0 > y0 + EPS && m.y0 < y1 - EPS) ys.add(m.y0);
    if (m.y1 > y0 + EPS && m.y1 < y1 - EPS) ys.add(m.y1);
  }
  const cuts = [...ys].sort((a, b) => a - b);

  const bands = [];
  for (let i = 0; i + 1 < cuts.length; i++) {
    const ya = cuts[i], yb = cuts[i + 1];
    if (yb - ya < EPS) continue;
    const live = marks.filter((m) => m.y0 <= ya + EPS && m.y1 >= yb - EPS)
      .sort((a, b) => a.x0 - b.x0);
    const runs = [];
    for (const m of live) {
      const last = runs[runs.length - 1];
      if (last && m.x0 <= last.x1 + EPS && last.c === m.c) last.x1 = Math.max(last.x1, m.x1);
      else runs.push({ x0: m.x0, x1: m.x1, c: m.c });
    }
    bands.push({ ya, yb, runs });
  }

  const key = (b) => b.runs.map((r) => `${r.x0.toFixed(5)},${r.x1.toFixed(5)},${r.c}`).join('|');
  const merged = [];
  for (const b of bands) {
    const prev = merged[merged.length - 1];
    if (prev && key(prev) === key(b) && Math.abs(prev.yb - b.ya) < EPS) prev.yb = b.yb;
    else merged.push({ ya: b.ya, yb: b.yb, runs: b.runs });
  }

  const face = (xa, xb, ya, yb, c) => {
    if (xb - xa < EPS || yb - ya < EPS) return;
    quad(bufs(c), [xa, ya, z], [xb, ya, z], [xb, yb, z], [xa, yb, z]);
  };
  for (const b of merged) {
    let cursor = x0;
    for (const r of b.runs) {
      face(cursor, r.x0, b.ya, b.yb, null);
      face(r.x0, r.x1, b.ya, b.yb, r.c);
      cursor = r.x1;
    }
    face(cursor, x1, b.ya, b.yb, null);
  }
}

export function createAsset(userParams = {}) {
  const { C, N, blade } = resolve(userParams);
  const H = heightFor(N);
  const zF = HD - RECESS_F, zB = -(HD - RECESS_B);
  const FI = FIELD_W / 2;

  const buf = { [C.frame]: [], [C.field]: [], [C.inkTop]: [], [C.inkBottom]: [], [C.plate]: [] };
  const T = buf[C.frame], F = buf[C.field], P = buf[C.plate];
  const bucket = (c) => (c === null ? F : buf[c]);

  const outer = rectCorners(-HW, HW, 0, H);
  const inset = rectCorners(-HW + CH, HW - CH, CH, H - CH);
  const open = rectCorners(-FI, FI, FRAME, H - FRAME);
  prismWall(T, outer, -HD, HD - CH, true);
  skirt(T, outer, HD - CH, inset, HD);
  ring(T, inset, open, HD, true);
  prismWall(T, open, zF, HD, false);
  ring(T, outer, open, -HD, false);
  prismWall(T, open, -HD, zB, false);

  const word = WORDS[N];
  const nRed = Math.ceil(N / 2);
  const marks = [];
  for (let i = 0; i < N; i++) {

    const top = H - FRAME - MARGIN - i * (CELL_H + CGAP);
    const bottom = top - CELL_H;
    const c = i < nRed ? C.inkTop : C.inkBottom;
    for (const [u0, u1, v0, v1] of GLYPHS[word[i]]) {
      marks.push({
        x0: (u0 - 0.5) * CELL_W, x1: (u1 - 0.5) * CELL_W,
        y0: bottom + v0 * CELL_H, y1: bottom + v1 * CELL_H, c,
      });
    }
  }
  paintField(bucket, -FI, FI, FRAME, H - FRAME, zF, marks);

  quad(F, [FI, FRAME, zB], [-FI, FRAME, zB], [-FI, H - FRAME, zB], [FI, H - FRAME, zB]);

  for (const s of [-1, 1]) {
    const yc = H / 2 + s * BRACKET_F * H;
    const ya = yc - ARM_H / 2, yb = yc + ARM_H / 2;
    if (blade) {

      const px1 = -(HW + ARM_L), px0 = px1 - PLATE_T;
      boxFaces(T, px1 - PBED, -HW + BED, ya, yb, -ARM_W / 2, ARM_W / 2, '+x-x');
      boxFaces(P, px0, px1, yc - PLATE_H / 2, yc + PLATE_H / 2, -PLATE_W / 2, PLATE_W / 2);
    } else {

      const pz1 = -(HD + ARM_L), pz0 = pz1 - PLATE_T;
      boxFaces(T, -ARM_W / 2, ARM_W / 2, ya, yb, pz1 - PBED, zB + BED, '+z-z');
      boxFaces(P, -PLATE_W / 2, PLATE_W / 2, yc - PLATE_H / 2, yc + PLATE_H / 2, pz0, pz1);
    }
  }

  const merged = mergeGeometries(
    Object.entries(buf).filter(([, p]) => p.length).map(([hex, p]) => prep(posGeo(p), Number(hex))));
  merged.computeBoundingBox();
  const bb = merged.boundingBox;
  merged.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);
  merged.computeVertexNormals();

  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'signboard';

  const root = new THREE.Group();
  root.name = 'vertical-kanji-signboard';
  root.add(mesh);
  return root;
}

export const rig = {};
export const detach = [];

export const night = {
  field: { color: '#F0C24B', intensity: 0.85, describe: 'warm lamp glow behind the paper sign face' },
};
export default createAsset;
