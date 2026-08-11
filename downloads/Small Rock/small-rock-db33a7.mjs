/*
 * Small Rock
 * https://polyfork.dev/asset/small-rock-db33a7
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './small-rock-db33a7.mjs';
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
 *   colorway   choice  'granite-grey' 'granite-grey' | 'mossy-shade' | 'sandstone' | 'dark-slate'
 *   stone      color   '#87847c'      any hex or THREE.Color
 *   moss       color   '#5f9a4b'      any hex or THREE.Color
 *   lichen     color   '#3d6b34'      any hex or THREE.Color
 *   size       range   0.35           0.18 to 0.38
 *   sides      range   6              5 to 8
 *   squat      range   0.62           0.4 to 0.74
 *   mossCover  range   0.4            0 to 1
 *
 * Every option is described in full at https://polyfork.dev/cdn/small-rock-db33a7-params.json
 *
 * SPECS  202 triangles, 1 material, 0.35 x 0.22 x 0.26 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';

const COLORWAYS = {
  'granite-grey': { stone: '#87847c', moss: '#5f9a4b', lichen: '#3d6b34' },
  'mossy-shade':  { stone: '#6e6b63', moss: '#4c8140', lichen: '#2f4f2e' },
  'sandstone':    { stone: '#a5855e', moss: '#8fa84a', lichen: '#6f8f3c' },
  'dark-slate':   { stone: '#57544e', moss: '#3d6b34', lichen: '#25402c' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'granite-grey', label: 'Colorway',
    options: ['granite-grey', 'mossy-shade', 'sandstone', 'dark-slate'],
    describe: 'Curated Nature & Forest stone schemes, all from the kit palette and all ' +
      'sharing the family used by this kit\'s large boulder and medium rock, so a scatter ' +
      'of mixed rocks stays coherent. granite-grey is the shipped mid warm-grey stone ' +
      'under bright spring moss; mossy-shade is a darker damp-forest grey under deep shade ' +
      'green, for the floor of a closed canopy; sandstone is a warm tan stone with dry ' +
      'yellow-green lichen, for sunlit clearings and riverbanks; dark-slate is a cold ' +
      'near-charcoal stone with very dark moss, for ravines and wet gullies. Sets stone, ' +
      'moss and lichen unless those are passed explicitly.',
  },
  stone: {
    type: 'color', default: '#87847c', label: 'Stone',
    describe: 'Albedo of the rock body — every facet that is not a moss patch, about 85% ' +
      'of the visible surface and the dominant colour of the asset. A stone is one ' +
      'material, so this is its single flat tone at every size: all the value variation ' +
      'you see across the facets comes from their angles and the scene lights, never from ' +
      'this colour. Keep it a neutral mid rung of the kit grey ramp so the green reads.',
  },
  moss: {
    type: 'color', default: '#5f9a4b', label: 'Moss',
    describe: 'Albedo of the brightest green crust — the largest and best-turned of the ' +
      'patches, and the one colour block that has to be legible against the grey from ' +
      '10 m, so keep it saturated and a clear value step off Stone. Unused when Moss ' +
      'cover is 0.',
  },
  lichen: {
    type: 'color', default: '#3d6b34', label: 'Lichen',
    describe: 'Albedo of the deeper green crusts — every patch except the largest one, ' +
      'roughly two thirds of the green on the shipped rock. Sits one clear value step ' +
      'below Moss; matched to Moss the patches flatten into a single sticker wrapped ' +
      'round the rim. Unused below a Moss cover of 0.15, where there is one patch only ' +
      'and it takes the Moss tone.',
  },
  size: {
    type: 'range', default: 0.35, min: 0.18, max: 0.38, step: 0.01, label: 'Size',
    affects: 'geometry',
    describe: 'Width of the stone across X in METRES. A genuine REBUILD, not a scale: the ' +
      'facet cell is a rock\'s repeat unit, so the number of cell BANDS wrapped round the ' +
      'stone follows its surface area (2 bands below 0.27 m, 3 at the 0.35 m default, 4 ' +
      'above 0.36 m) and each cell stays roughly a constant size in world units instead of ' +
      'the whole pebble getting coarser or finer. The crown gains a cell over the same ' +
      'range. 0.18 m is a stone you kick aside; 0.38 m is a chunky sitting rock. The range ' +
      'is skewed DOWNWARD on purpose: the store\'s variant proof frames the DEFAULT ' +
      'bounding box, and this pebble already fills it, so a top end much past +10% crops ' +
      'its own picture. Scenes wanting a bigger stone reach for the kit\'s medium rock.',
  },
  sides: {
    type: 'range', default: 6, min: 5, max: 8, step: 1, label: 'Sides',
    affects: 'geometry',
    describe: 'How many flat cells go round the plan — the knob that owns this rock\'s ' +
      'identity and the kit\'s "5-8 sided" style rule made explicit. 5 is a blunt ' +
      'wedge-cornered stone with long straight silhouette runs and wide creases; 6 is the ' +
      'shipped hexagonal pebble; 8 is a more eroded stone with shorter outline segments ' +
      'that still never curves. Changes the number of corners in every elevation and the ' +
      'triangle count; the 0.35 m footprint and the proportions do not move.',
  },
  squat: {
    type: 'range', default: 0.62, min: 0.40, max: 0.74, step: 0.02, label: 'Squatness',
    affects: 'geometry',
    describe: 'Height of the stone as a fraction of its width, so 0.62 is the shipped ' +
      '0.216 m tall pebble under a 0.35 m footprint. 0.40 is a flat skimming stone that ' +
      'barely clears the grass; 0.74 is a chunky lump nearly as tall as it is deep. The ' +
      'cutting planes are re-solved against the new form, so the crown plateau and the ' +
      'shoulder band re-proportion and the cell layout changes with it — but a pebble has ' +
      'no repeating structure to multiply in height, so this rung rebuilds the cell ' +
      'pattern rather than gaining courses. The whole change is in the FRONT elevation.',
  },
  mossCover: {
    type: 'range', default: 0.40, min: 0, max: 1, step: 0.05, label: 'Moss cover',
    affects: 'geometry',
    describe: 'How much of the crown rim carries moss, as real crusts cut out of the ' +
      'stone\'s own cells — a bare stone margin, a 4 mm rim and a flat top — spread one ' +
      'per azimuth sector so at least one faces any camera. EXACTLY 0 is a clean bare ' +
      'stone with no green geometry and no green triangles at all, for dry, rocky or ' +
      'winter ground; 0.40 is the shipped rock, three patches about 0.09 m across; 1.00 ' +
      'wraps up to five slightly larger patches most of the way round the rim, a stone ' +
      'that has sat in deep shade for years. Never on the crown centre, never on a lower ' +
      'flank and never underneath, at any value. The triangle count moves with it.',
  },
};

export const rig = {};
export const detach = [];

export const night = {};

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

const dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
const sub = (a, b) => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
const cross = (a, b) => [
  a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0],
];
function norm(a) {
  const l = Math.hypot(a[0], a[1], a[2]) || 1;
  return [a[0] / l, a[1] / l, a[2] / l];
}
const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

function profAt(table, t) {
  if (t <= table[0][0]) return table[0][1];
  for (let i = 1; i < table.length; i++) {
    if (t <= table[i][0]) {
      const [t0, r0] = table[i - 1], [t1, r1] = table[i];
      return r0 + (r1 - r0) * ((t - t0) / (t1 - t0));
    }
  }
  return table[table.length - 1][1];
}

const EPS = 1e-6;

function capPolygon(pts, n) {
  const c = [0, 0, 0];
  for (const p of pts) { c[0] += p[0]; c[1] += p[1]; c[2] += p[2]; }
  c[0] /= pts.length; c[1] /= pts.length; c[2] /= pts.length;
  const a = Math.abs(n[1]) < 0.9 ? [0, 1, 0] : [1, 0, 0];
  const u = norm(cross(a, n));
  const v = cross(n, u);
  const keyed = pts.map((p) => {
    const d = sub(p, c);
    return { p, ang: Math.atan2(dot(d, v), dot(d, u)) };
  });
  keyed.sort((x, y) => x.ang - y.ang);
  return dedupeLoop(keyed.map((k) => k.p));
}

function dedupeLoop(loop, tol = 2e-5) {
  const out = [];
  for (const p of loop) {
    const q = out[out.length - 1];
    if (q && Math.abs(p[0] - q[0]) < tol && Math.abs(p[1] - q[1]) < tol && Math.abs(p[2] - q[2]) < tol) continue;
    out.push(p);
  }
  const f = out[0], l = out[out.length - 1];
  if (out.length > 1 && Math.abs(f[0] - l[0]) < tol && Math.abs(f[1] - l[1]) < tol && Math.abs(f[2] - l[2]) < tol) out.pop();
  return out;
}

function clipByPlane(faces, pl) {
  const kept = [];
  const cut = [];
  for (const f of faces) {
    const dist = f.map((p) => dot(pl.n, p) - pl.d);
    const nf = [];
    for (let i = 0; i < f.length; i++) {
      const j = (i + 1) % f.length;
      const di = dist[i], dj = dist[j];
      if (di <= EPS) nf.push(f[i]);
      if (Math.abs(di) <= EPS) cut.push(f[i]);
      else if ((di < 0 && dj > EPS) || (di > EPS && dj < 0)) {
        const s = di / (di - dj);
        const p = [
          f[i][0] + (f[j][0] - f[i][0]) * s,
          f[i][1] + (f[j][1] - f[i][1]) * s,
          f[i][2] + (f[j][2] - f[i][2]) * s,
        ];
        nf.push(p); cut.push(p);
      }
    }
    const loop = dedupeLoop(nf);
    if (loop.length >= 3) kept.push(loop);
  }
  if (cut.length >= 3) {
    const cap = capPolygon(cut, pl.n);
    if (cap.length >= 3) kept.push(cap);
  }
  return kept;
}

function faceArea(f) {
  let a = [0, 0, 0];
  for (let i = 1; i + 1 < f.length; i++) {
    const c = cross(sub(f[i], f[0]), sub(f[i + 1], f[0]));
    a = [a[0] + c[0], a[1] + c[1], a[2] + c[2]];
  }
  return Math.hypot(a[0], a[1], a[2]) / 2;
}

const centroidOf = (f) => {
  const c = [0, 0, 0];
  for (const p of f) { c[0] += p[0]; c[1] += p[1]; c[2] += p[2]; }
  return [c[0] / f.length, c[1] / f.length, c[2] / f.length];
};

function resampleLoop(loop, n) {
  const out = loop.slice();
  while (out.length < n) {
    let bi = 0, bl = -1;
    for (let i = 0; i < out.length; i++) {
      const a = out[i], b = out[(i + 1) % out.length];
      const L = Math.hypot(b[0] - a[0], b[1] - a[1], b[2] - a[2]);
      if (L > bl) { bl = L; bi = i; }
    }
    if (bl <= 0) break;
    const a = out[bi], b = out[(bi + 1) % out.length];
    out.splice(bi + 1, 0, [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[2] + b[2]) / 2]);
  }
  return out;
}

const PROFILE = [
  [0.00, 0.30], [0.14, 0.62], [0.32, 0.88], [0.50, 1.00],
  [0.62, 0.99], [0.78, 0.90], [0.90, 0.74], [1.00, 0.52],
];

const PLAN_SQUASH = 0.802;
const BURIED = 0.20;

function surfacePoints(cfg) {
  const pts = [];
  const RINGS = 18, SEGS = 30;
  for (let i = 0; i <= RINGS; i++) {
    const u = i / RINGS;
    const rf = profAt(PROFILE, u);
    const y = (u - BURIED) * cfg.H;
    for (let j = 0; j < SEGS; j++) {
      const a = (j / SEGS) * Math.PI * 2;

      const m = 1 + 0.085 * Math.sin(3 * a + 0.9) + 0.048 * Math.sin(5 * a + 2.6);
      const r = cfg.R * rf * m;
      pts.push([
        Math.cos(a) * r + cfg.shearX * u * u,
        y,
        Math.sin(a) * r * PLAN_SQUASH + cfg.shearZ * u * u,
      ]);
    }
  }
  return pts;
}

const R0 = 0.50;

function buildRock(cfg) {
  const pts = surfacePoints(cfg);
  const centre = [0, (0.44 - BURIED) * cfg.H, 0];
  const rand = prng(cfg.seed);

  const tangent = (n, bite) => {
    let s = -Infinity;
    for (const p of pts) { const v = dot(n, p); if (v > s) s = v; }
    const c = dot(n, centre);
    return c + (s - c) * (1 - bite);
  };

  let topY = -Infinity;
  for (const p of pts) if (p[1] > topY) topY = p[1];

  const planes = [{ n: [0, -1, 0], d: 0 }];

  const CROWN = [[0.55, 0.085, 0.985], [2.70, 0.115, 0.978], [4.45, 0.070, 0.990], [1.75, 0.100, 0.982]];
  for (let i = 0; i < cfg.crown; i++) {
    const [az, tilt, lift] = CROWN[i];
    const n = norm([Math.cos(az) * tilt, 1, Math.sin(az) * tilt]);
    planes.push({ n, d: n[1] * topY * lift });
  }

  const NY_TOP = 0.66, NY_LOW = -0.02;
  for (let b = 0; b < cfg.bands; b++) {
    const t = cfg.bands === 1 ? 0 : b / (cfg.bands - 1);
    const ny = NY_TOP + (NY_LOW - NY_TOP) * t;
    const ch = Math.sqrt(Math.max(0.04, 1 - ny * ny));
    for (let k = 0; k < cfg.N; k++) {
      const az = Math.PI / 2 + (k + (b % 2) * 0.5) * (Math.PI * 2 / cfg.N);
      const n = norm([Math.cos(az) * ch, ny + 0.05 * rand(), Math.sin(az) * ch]);

      planes.push({ n, d: tangent(n, 0.020 + 0.080 * t + 0.018 * rand()) });
    }
  }

  const FOOT = 0.72;
  for (let i = 0; i < cfg.N; i++) {
    const a = Math.PI / 2 + (i + ((cfg.bands - 1) % 2 ? 0 : 0.5)) * (Math.PI * 2 / cfg.N)
      + 0.14 * Math.sin(i * 2.1);
    const hx = Math.cos(a), hz = Math.sin(a);
    let rEq = 0;
    for (const p of pts) { const v = p[0] * hx + p[2] * hz; if (v > rEq) rEq = v; }
    const r = rEq * FOOT * (0.94 + 0.10 * Math.sin(i * 3.3 + 1.2));
    const n = norm([hx * 0.78, -0.63, hz * 0.78]);
    planes.push({ n, d: n[0] * hx * r + n[2] * hz * r });
  }

  const S = 8;
  const c = [
    [-S, -S, -S], [S, -S, -S], [S, -S, S], [-S, -S, S],
    [-S, S, -S], [S, S, -S], [S, S, S], [-S, S, S],
  ];
  let faces = [
    [c[3], c[2], c[1], c[0]],
    [c[4], c[5], c[6], c[7]],
    [c[0], c[1], c[5], c[4]],
    [c[2], c[3], c[7], c[6]],
    [c[1], c[2], c[6], c[5]],
    [c[3], c[0], c[4], c[7]],
  ];
  for (const pl of planes) faces = clipByPlane(faces, pl);

  return faces.filter((f) => faceArea(f) > 1.2e-4);
}

function pickMossFaces(faces, count, topY, minHalf) {
  if (count <= 0) return [];
  const best = new Array(count).fill(null);
  for (const f of faces) {
    const n = norm(cross(sub(f[1], f[0]), sub(f[2], f[0])));

    if (n[1] < 0.42) continue;
    const c = centroidOf(f);
    if (c[1] < topY * 0.42) continue;

    let rIn = Infinity;
    for (const p of f) rIn = Math.min(rIn, Math.hypot(p[0] - c[0], p[1] - c[1], p[2] - c[2]));
    if (rIn < minHalf) continue;
    const az = Math.atan2(c[2], c[0]);
    const k = Math.floor(((az + Math.PI * 2) % (Math.PI * 2)) / (Math.PI * 2 / count)) % count;

    const t = (n[1] - 0.66) / 0.24;
    const score = Math.sqrt(faceArea(f)) * Math.exp(-t * t);
    if (!best[k] || score > best[k].score) best[k] = { f, n, score };
  }
  return best.filter(Boolean);
}

export function createAsset(userParams = {}) {
  const P = {};
  for (const k of Object.keys(params)) P[k] = params[k].default;
  Object.assign(P, userParams);

  const way = COLORWAYS[P.colorway] || COLORWAYS[params.colorway.default];
  const pick = (k) => userParams[k] ?? (userParams.colorway ? way[k] : params[k].default);
  const C = { stone: pick('stone'), moss: pick('moss'), lichen: pick('lichen') };

  const SIZE = clamp(Number(P.size) || params.size.default, 0.18, 0.38);
  const N = clamp(Math.round(Number(P.sides)), 5, 8);
  const SQUAT = clamp(Number(P.squat ?? params.squat.default), 0.40, 0.74);
  const COVER = clamp(Number(P.mossCover ?? params.mossCover.default), 0, 1);

  const bands = SIZE < 0.27 ? 2 : (SIZE > 0.36 ? 4 : 3);
  const crown = SIZE < 0.27 ? 2 : (SIZE > 0.36 ? 4 : 3);

  const faces = buildRock({
    H: (SQUAT / 0.80) * 1.06, R: R0, N, bands, crown,
    shearX: -0.030, shearZ: 0.024,
    seed: 20260807,
  });

  let mnx = Infinity, mxx = -Infinity, mnz = Infinity, mxz = -Infinity, mxy = -Infinity;
  for (const f of faces) for (const p of f) {
    if (p[0] < mnx) mnx = p[0]; if (p[0] > mxx) mxx = p[0];
    if (p[2] < mnz) mnz = p[2]; if (p[2] > mxz) mxz = p[2];
    if (p[1] > mxy) mxy = p[1];
  }
  const FIT = SIZE / (mxx - mnx);

  const YFIT = (SIZE * SQUAT) / (mxy * FIT);
  const ox = (mnx + mxx) / 2, oz = (mnz + mxz) / 2;
  const fitted = faces.map((f) => f.map((p) => [
    (p[0] - ox) * FIT, p[1] * FIT * YFIT, (p[2] - oz) * FIT,
  ]));

  const pos = [], col = [];
  const tmp = new THREE.Color();
  const paint = (hex) => { tmp.set(hex); for (let i = 0; i < 3; i++) col.push(tmp.r, tmp.g, tmp.b); };
  const tri = (a, b, c2, hex) => {
    pos.push(a[0], a[1], a[2], b[0], b[1], b[2], c2[0], c2[1], c2[2]);
    paint(hex);
  };
  const fan = (loop, hex) => {
    for (let i = 1; i + 1 < loop.length; i++) tri(loop[0], loop[i], loop[i + 1], hex);
  };

  const nPatch = COVER <= 0 ? 0 : clamp(Math.round(0.8 + 5.2 * COVER), 1, N - 1);

  const sizeK = 0.55 + 0.45 * SIZE / 0.35;
  const PATCH_R = (0.036 + 0.014 * COVER) * sizeK;

  const mossed = pickMossFaces(fitted, nPatch, SIZE * SQUAT, 0.036 * sizeK * 0.85);

  mossed.sort((a, b) => b.score - a.score);
  const mossedSet = new Set(mossed.map((m) => m.f));

  for (const f of fitted) if (!mossedSet.has(f)) fan(f, C.stone);

  const T = 0.004;
  for (let h = 0; h < mossed.length; h++) {
    const { f, n } = mossed[h];
    const hex = h === 0 ? C.moss : C.lichen;
    const rand = prng(4001 + h * 977);
    const c = centroidOf(f);

    let best = f[0], bestD = -Infinity;
    for (const p of f) {
      const d = Math.hypot(p[0], p[2]);
      if (d > bestD) { bestD = d; best = p; }
    }
    const aL = Math.hypot(best[0] - c[0], best[1] - c[1], best[2] - c[2]) || 1;
    const aK = Math.min(aL * 0.22, 0.016) / aL;
    const P = [
      c[0] + (best[0] - c[0]) * aK, c[1] + (best[1] - c[1]) * aK, c[2] + (best[2] - c[2]) * aK,
    ];

    const L2 = resampleLoop(f, 8);
    let faceR = 0;
    for (const p of L2) faceR = Math.max(faceR, Math.hypot(p[0] - P[0], p[1] - P[1], p[2] - P[2]));
    const rTarget = Math.min(PATCH_R, faceR * 0.70);

    const S1 = L2.map((p) => {
      const dx = p[0] - P[0], dy = p[1] - P[1], dz = p[2] - P[2];
      const len = Math.hypot(dx, dy, dz) || 1;
      const r = Math.min(rTarget * (0.90 + 0.20 * rand()), len * 0.86);
      return [P[0] + dx / len * r, P[1] + dy / len * r, P[2] + dz / len * r];
    });
    const A1 = S1.map((p) => [
      P[0] + (p[0] - P[0]) * 0.88 + n[0] * T,
      P[1] + (p[1] - P[1]) * 0.88 + n[1] * T,
      P[2] + (p[2] - P[2]) * 0.88 + n[2] * T,
    ]);

    const ring = (lo, hi, col2) => {
      for (let i = 0; i < lo.length; i++) {
        const j = (i + 1) % lo.length;
        tri(lo[i], lo[j], hi[j], col2); tri(lo[i], hi[j], hi[i], col2);
      }
    };
    ring(L2, S1, C.stone);
    ring(S1, A1, hex);
    fan(A1, hex);
  }

  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  geo.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
  geo.computeVertexNormals();

  const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'rock';

  const g = new THREE.Group();
  g.name = 'small-rock';
  g.add(mesh);
  return g;
}

export default createAsset;
