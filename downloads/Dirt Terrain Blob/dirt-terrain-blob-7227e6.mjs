/*
 * Dirt Terrain Blob
 * https://polyfork.dev/asset/dirt-terrain-blob-7227e6
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './dirt-terrain-blob-7227e6.mjs';
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
 *   colorway     choice  'packed-dirt'  'packed-dirt' | 'dry-chalk' | 'meadow-turf' | 'dark-loam'
 *   top          color   '#b89b72'      any hex or THREE.Color
 *   skirt        color   '#8c6a4a'      any hex or THREE.Color
 *   skirtShade   color   '#6f4e37'      any hex or THREE.Color
 *   grassTip     color   '#7d8a5a'      any hex or THREE.Color
 *   grassBase    color   '#4a6a4f'      any hex or THREE.Color
 *   surface      choice  'packed'       'packed' | 'tilled' | 'ridged'
 *   width        range   1              0.87 to 1.3
 *   lobing       range   1              0 to 1.6
 *   grass        range   11             0 to 20
 *
 * Every option is described in full at https://polyfork.dev/cdn/dirt-terrain-blob-7227e6-params.json
 *
 * SPECS  360 triangles, 1 material, 6.97 x 0.74 x 6.26 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const COLORWAYS = {
  'packed-dirt': { top: 0xb89b72, skirt: 0x8c6a4a, skirtShade: 0x6f4e37, grassTip: 0x7d8a5a, grassBase: 0x4a6a4f },
  'dry-chalk':   { top: 0xe8dcc0, skirt: 0xb89b72, skirtShade: 0x8c6a4a, grassTip: 0x7d8a5a, grassBase: 0x4a6a4f },
  'meadow-turf': { top: 0x7d8a5a, skirt: 0x8c6a4a, skirtShade: 0x6f4e37, grassTip: 0xe8dcc0, grassBase: 0xb89b72 },
  'dark-loam':   { top: 0x8c6a4a, skirt: 0x6f4e37, skirtShade: 0x4a6a4f, grassTip: 0x7d8a5a, grassBase: 0x3c4550 },
};
export const presets = COLORWAYS;

export const params = {
  colorway: { type: 'choice', default: 'packed-dirt', label: 'Colorway',
              options: ['packed-dirt', 'dry-chalk', 'meadow-turf', 'dark-loam'],
              describe: 'curated earth scheme; sets all five zone albedos at once. packed-dirt = shipped tan dirt over mid/dark brown banding; dry-chalk = pale sun-baked cream top on tan walls; meadow-turf = olive grass-grown top with bleached straw tufts; dark-loam = damp dark-brown soil whose shaded skirt facets go mossy green' },
  top: { type: 'color', default: '#b89b72', label: 'Top dirt',
         describe: 'albedo of the whole flat top plane — the dominant surface, ~55% of the visible pixels from above' },
  skirt: { type: 'color', default: '#8c6a4a', label: 'Skirt',
           describe: 'albedo of the majority (about two thirds) of the faceted skirt wall panels that taper from the top plane down to y=0' },
  skirtShade: { type: 'color', default: '#6f4e37', label: 'Skirt banding',
                describe: 'albedo of the darker skirt facets scattered among the skirt panels (seeded, about one third of them) plus the underside cap; this is the two-tone packed-earth banding, so keep it darker than skirt or the banding stops reading' },
  grassTip: { type: 'color', default: '#7d8a5a', label: 'Grass tips',
              describe: 'albedo of the TALL blades in every tuft (roughly half of them) — the lit olive tone that makes the tufts read against the dirt' },
  grassBase: { type: 'color', default: '#4a6a4f', label: 'Grass base',
               describe: 'albedo of the SHORT blades in every tuft; darker than grassTip, it roots the clump into the ground. Blades are flat-coloured one per blade, never graded inside a face' },
  surface: { type: 'choice', default: 'packed', label: 'Surface', icon: '🌾', affects: 'geometry',
             options: ['packed', 'tilled', 'ridged'],
             describe: 'which worked state this plot is in — the same plot, not a different asset. packed = the shipped bare hard-packed dirt, one dead-flat plane; tilled = close-pitch plough furrows running along X, ridges 90 mm proud on a 0.45 m pitch (a freshly worked bed; reads from above, the elevation stays flat); ridged = medieval ridge-and-furrow strip field, 190 mm ridges on a 0.95 m pitch, big enough to serrate the top line in the side views. Both use 25 degree flanks and hipped ends that die into the plane; pitch and height are FIXED in metres, so a wider plot gains more furrows instead of fatter ones, and every value keeps the same outline, origin, thickness, palette and rim grass' },
  width: { type: 'range', default: 1.0, min: 0.87, max: 1.3, label: 'Width', icon: '↔️', affects: 'geometry',
          describe: 'width of the island across X: 0.87 = 6.1 m, 1.0 = 6.97 m (shipped), 1.3 = 9.0 m, always ~0.9x as deep in Z. REBUILT, not scaled: the facet chord is held at a constant ~0.62 m so the outline gains skirt facets (29/34/44 columns) and the tuft count follows the area, which keeps facet size and grass density identical at every width. Slab thickness stays 0.42 m throughout' },
  lobing: { type: 'range', default: 1.0, min: 0, max: 1.6, label: 'Lobing', icon: '☁️', affects: 'geometry',
            describe: 'how far the cloud outline bulges in and out: 0 = a clean smooth oval island with only the fine per-facet jitter left, 1.0 = the shipped flattened-cloud outline, 1.6 = deeply scalloped with pronounced bays between fat lobes. Amplitude of all three outline harmonics; the concave floor opens with it so a high value never pinches the blob in two. Triangle-neutral — read it in top.png' },
  grass: { type: 'range', default: 11, min: 0, max: 20, label: 'Grass tufts', icon: '🌿', affects: 'geometry',
           describe: 'number of grass tufts freckling the outer rim band at width 1.0 (integer; the actual count scales with width). 0 = bare packed dirt with no scatter at all, 11 = the shipped sparse freckling, 20 = a well-grown rim. The inner 55% of the top stays bare at every value' },
};

export const rig = {};
export const detach = [];

export const night = {};

const ZONE_KEYS = ['top', 'skirt', 'skirtShade', 'grassTip', 'grassBase'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['packed-dirt'];
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {
    let hex = (hexOf(o[k]) ?? cw[k] ?? cw.top) & 0xFFFFFF;
    while (used.has(hex)) hex = (hex + 1) & 0xFFFFFF;
    used.add(hex);
    out[k] = hex;
  }
  return out;
}
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function prep(geo, hex) {
  geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  if (!geo.getAttribute('color')) {
    const c = new THREE.Color(hex);
    const n = geo.attributes.position.count;
    const col = new Float32Array(n * 3);
    for (let i = 0; i < n; i++) { col[i*3] = c.r; col[i*3+1] = c.g; col[i*3+2] = c.b; }
    geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  }
  return geo;
}

const TOP_Y = 0.42;
const SQZ   = 0.88;
const N0    = 34;
const R0    = 3.35;
const NG0   = 11;

const SURFACE = {
  packed: null,
  tilled: { pitch: 0.45, halfW: 0.19, h: 0.09 },
  ridged: { pitch: 0.95, halfW: 0.40, h: 0.19 },
};

const DEFAULTS = { colorway: 'packed-dirt', surface: 'packed', width: 1, lobing: 1, grass: NG0 };

export function createAsset(opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const C = zonesFor(String(o.colorway), o);
  const width = clamp(num(o.width, 1), 0.87, 1.3);
  const lob  = clamp(num(o.lobing, 1), 0, 1.6);
  const nGrassBase = Math.round(clamp(num(o.grass, NG0), 0, 20));
  const furrow = SURFACE[String(o.surface)] !== undefined ? SURFACE[String(o.surface)] : SURFACE.packed;

  const BASE_R = R0 * width;

  const N = Math.max(12, Math.round(N0 * width));
  const NGRASS = Math.round(nGrassBase * width);

  const parts = [];
  const add  = (g, c) => parts.push({ g, c });
  const addC = (g)    => parts.push({ g });

  const floorK = lob === 1 ? 0.90 : 1 - 0.10 * lob;
  const lobeR = (a) => {
    const k = 1
      + 0.075 * lob * Math.sin(5 * a + 0.6)
      + 0.045 * lob * Math.sin(8 * a + 2.1)
      + 0.040 * lob * Math.sin(3 * a + 4.0);
    return BASE_R * Math.max(k, floorK);
  };

  const jr = prng(41);
  const top = [], bot = [];
  for (let i = 0; i < N; i++) {
    const a = (i / N) * Math.PI * 2;
    const r = lobeR(a) * (0.985 + jr() * 0.03);
    const cx = Math.cos(a) * r, cz = Math.sin(a) * r * SQZ;
    top.push([cx, TOP_Y, cz]);
    bot.push([cx * 0.9, 0, cz * 0.9]);
  }

  {
    const cTop = new THREE.Color(C.top);
    const pos = [], col = [];
    const pushTri = (a, b, c) => {
      tri(pos, a, b, c);
      for (let k = 0; k < 3; k++) col.push(cTop.r, cTop.g, cTop.b);
    };
    const FR = [0, 0.45, 0.72, 1.0];
    const center = [0, TOP_Y, 0];
    const ringPt = (L, i) => [top[i][0] * FR[L], TOP_Y, top[i][2] * FR[L]];
    for (let i = 0; i < N; i++) {
      const j = (i + 1) % N;

      pushTri(center, ringPt(1, j), ringPt(1, i));

      for (let L = 1; L <= 2; L++) {
        pushTri(ringPt(L, i), ringPt(L, j), ringPt(L + 1, j));
        pushTri(ringPt(L, i), ringPt(L + 1, j), ringPt(L + 1, i));
      }
    }
    const g = posGeo(pos);
    g.setAttribute('color', new THREE.BufferAttribute(new Float32Array(col), 3));
    addC(g);
  }

  {
    const jn = prng(19);
    const cA = new THREE.Color(C.skirt), cB = new THREE.Color(C.skirtShade);
    const pos = [], col = [];
    const pushTri = (a, b, c, colr) => {
      tri(pos, a, b, c);
      for (let k = 0; k < 3; k++) col.push(colr.r, colr.g, colr.b);
    };
    for (let i = 0; i < N; i++) {
      const j = (i + 1) % N;
      const t0 = top[i], t1 = top[j], b0 = bot[i], b1 = bot[j];
      const colr = jn() < 0.34 ? cB : cA;

      pushTri(t0, t1, b1, colr);
      pushTri(t0, b1, b0, colr);
    }
    const g = posGeo(pos);
    g.setAttribute('color', new THREE.BufferAttribute(new Float32Array(col), 3));
    addC(g);
  }

  {
    const pos = [];
    const center = [0, 0, 0];
    for (let i = 0; i < N; i++) {
      const b0 = bot[i], b1 = bot[(i + 1) % N];
      tri(pos, center, b0, b1);
    }
    add(posGeo(pos), C.skirtShade);
  }

  if (furrow) {
    const { pitch, halfW, h } = furrow;
    const INSET = 0.24;

    const spansAt = (z) => {
      const xs = [];
      for (let i = 0; i < N; i++) {
        const p0 = top[i], p1 = top[(i + 1) % N];
        if ((p0[2] <= z && p1[2] > z) || (p1[2] <= z && p0[2] > z)) {
          xs.push(p0[0] + ((z - p0[2]) / (p1[2] - p0[2])) * (p1[0] - p0[0]));
        }
      }
      xs.sort((a, b) => a - b);
      const out = [];
      for (let i = 0; i + 1 < xs.length; i += 2) out.push([xs[i], xs[i + 1]]);
      return out;
    };

    const overlapping = (spans, a, b) => {
      let best = null, bestLen = 0;
      for (const s of spans) {
        const len = Math.min(b, s[1]) - Math.max(a, s[0]);
        if (len > bestLen) { bestLen = len; best = s; }
      }
      return best;
    };
    let zLo = Infinity, zHi = -Infinity;
    for (const p of top) { zLo = Math.min(zLo, p[2]); zHi = Math.max(zHi, p[2]); }
    const pos = [];
    for (let k = Math.ceil(zLo / pitch); k <= Math.floor(zHi / pitch); k++) {
      const z = k * pitch;
      const here = spansAt(z), near = spansAt(z + halfW), far = spansAt(z - halfW);
      for (const [a, b] of here) {
        const n0 = overlapping(near, a, b), f0 = overlapping(far, a, b);
        if (!n0 || !f0) continue;
        const xa = Math.max(a, n0[0], f0[0]) + INSET;
        const xb = Math.min(b, n0[1], f0[1]) - INSET;
        if (xb - xa < 2 * halfW + 0.45) continue;
        const zN = z + halfW, zF = z - halfW, yT = TOP_Y + h;

        const ca = xa + halfW, cb = xb - halfW;
        tri(pos, [xa, TOP_Y, zN], [xb, TOP_Y, zN], [cb, yT, z]);
        tri(pos, [xa, TOP_Y, zN], [cb, yT, z],     [ca, yT, z]);
        tri(pos, [xb, TOP_Y, zF], [xa, TOP_Y, zF], [ca, yT, z]);
        tri(pos, [xb, TOP_Y, zF], [ca, yT, z],     [cb, yT, z]);
        tri(pos, [xb, TOP_Y, zN], [xb, TOP_Y, zF], [cb, yT, z]);
        tri(pos, [xa, TOP_Y, zF], [xa, TOP_Y, zN], [ca, yT, z]);
      }
    }
    if (pos.length) add(posGeo(pos), C.top);
  }

  const grassTuft = (x, z, seed) => {
    const rand = prng(seed);
    const pos = [], col = [];
    const cB = new THREE.Color(C.grassBase), cT = new THREE.Color(C.grassTip);
    const blades = 4 + Math.floor(rand() * 2);
    for (let bI = 0; bI < blades; bI++) {
      const yaw = rand() * Math.PI * 2;
      const dx = Math.cos(yaw), dz = Math.sin(yaw);
      const ox = (rand() - 0.5) * 0.08, oz = (rand() - 0.5) * 0.08;
      const bx = x + ox, bz = z + oz;
      const w = 0.018;
      const h = 0.20 + rand() * 0.12;
      const bend = 0.04 + rand() * 0.05;
      const b0 = [bx - dz * w, TOP_Y, bz + dx * w];
      const b1 = [bx + dz * w, TOP_Y, bz - dx * w];
      const apex = [bx + dx * bend, TOP_Y + h, bz + dz * bend];

      tri(pos, b0, b1, apex);
      tri(pos, b1, b0, apex);
      const cBlade = h > 0.26 ? cT : cB;
      for (let k = 0; k < 6; k++) col.push(cBlade.r, cBlade.g, cBlade.b);
    }
    const g = posGeo(pos);
    g.setAttribute('color', new THREE.BufferAttribute(new Float32Array(col), 3));
    addC(g);
  };

  const js = prng(123);

  for (let gi = 0; gi < NGRASS; gi++) {
    const a = (gi / NGRASS) * Math.PI * 2 + 0.31 + (js() - 0.5) * 0.4;
    const localR = lobeR(a);
    const f = 0.58 + js() * 0.26;
    const gx = Math.cos(a) * localR * f;
    const gz = Math.sin(a) * localR * SQZ * f;
    grassTuft(gx, gz, 500 + gi * 17);
  }

  const g = new THREE.Group();
  g.name = 'terrain-blob-dirt';
  const merged = mergeGeometries(parts.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.9, metalness: 0,
  }));
  mesh.name = 'terrain-blob-dirt-mesh';
  g.add(mesh);
  return g;
}

export default createAsset;
