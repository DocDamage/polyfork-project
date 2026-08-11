/*
 * Water Blob
 * https://polyfork.dev/asset/water-blob-f266b8
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './water-blob-f266b8.mjs';
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
 *   colorway    choice  'forest-pond'  'forest-pond' | 'clear-brook' | 'mossy-pool' | 'peat-bog'
 *   water       color   '#3f8fa8'      any hex or THREE.Color
 *   shore       color   '#63b3c4'      any hex or THREE.Color
 *   bed         color   '#2f6f86'      any hex or THREE.Color
 *   foamColor   color   '#9fd8dd'      any hex or THREE.Color
 *   surf        range   0.5            0 to 1.5
 *   drift       range   1              0 to 2.5
 *   spread      range   1              0.7 to 1.15
 *   elongation  range   0.85           0.4 to 1
 *   ruggedness  range   1              0.3 to 1.45
 *
 * Every option is described in full at https://polyfork.dev/cdn/water-blob-f266b8-params.json
 *
 * SPECS  320 triangles, 1 material, 8 x 0.04 x 6.8 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'forest-pond': { water: '#3f8fa8', shore: '#63b3c4', bed: '#2f6f86', crest: '#9fd8dd' },
  'clear-brook': { water: '#63b3c4', shore: '#9fd8dd', bed: '#3f8fa8', crest: '#f4ece0' },
  'mossy-pool':  { water: '#3d6b34', shore: '#6f8f3c', bed: '#25402c', crest: '#c8d98a' },
  'peat-bog':    { water: '#5d4430', shore: '#8c6a47', bed: '#3a2a1e', crest: '#c2a479' },
};

export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'forest-pond', label: 'Colorway', affects: 'colors',
    options: ['forest-pond', 'clear-brook', 'mossy-pool', 'peat-bog'],
    describe: 'Curated Nature & Forest schemes, each moving the deep/shallow pair that fills ' +
      'the frame. "forest-pond" is the default cool blue-teal woodland pond; "clear-brook" ' +
      'lifts the whole body one step lighter for a shallow sunlit stream reach; "mossy-pool" ' +
      'swaps the water for the kit greens — a stagnant algal pool; "peat-bog" goes to the kit ' +
      'browns for peaty bog water and flooded mud.',
  },
  water: {
    type: 'color', default: '#3f8fa8', label: 'Deep water', affects: 'colors',
    describe: 'Albedo of the deep interior of the sheet — the inner 78% of the radius, and by ' +
      'far the largest zone. Keep it clearly darker than Shallows or the depth step around the ' +
      'shore stops reading at thumbnail size.',
  },
  shore: {
    type: 'color', default: '#63b3c4', label: 'Shallows', affects: 'colors',
    describe: 'Albedo of the wide shallow shelf ringing the outline (the outer 22% of the ' +
      'radius, about 0.9 m of band). Lies in the same flat plane as the deep water and is told ' +
      'apart from it by colour alone, so it needs a real value step above Deep water. This is ' +
      'also the band the surf shader whitens as it breathes.',
  },
  bed: {
    type: 'color', default: '#2f6f86', label: 'Submerged rim', affects: 'colors',
    describe: 'Albedo of the tapered rim facet and the whole faceted underside. Take it below ' +
      'both water tones: the wafer is only 40 mm thick, and an under-valued edge makes the ' +
      'patch read as a flat decal instead of a body of water sitting in a hollow. Do not take ' +
      'it near black — it is the only thing a camera below the ground plane sees.',
  },
  foamColor: {
    type: 'color', default: '#9fd8dd', label: 'Foam crest', affects: 'material',
    describe: 'The colour the shallows band mixes toward at the peak of the surf cycle. Follows ' +
      'the colorway unless you set it — pale cyan on the blue ponds, pale green on the mossy ' +
      'pool, pale sand on the bog. Set it to the kit off-white #f4ece0 for hard white surf. It ' +
      'is never visible in a still: the surf is zero at rest and only shows once a host drives ' +
      'userData.tick.',
  },
  surf: {
    type: 'range', default: 0.5, min: 0, max: 1.5, label: 'Surf', affects: 'material',
    describe: 'How hard the shallows band breathes. 0 is glassy still water and the band holds ' +
      'its flat Shallows albedo with no movement at all; 0.5 is the default gentle lap of a ' +
      'woodland pond, lightening one shore at a time; 1.5 runs the crest colour right across ' +
      'the shelf at the peak of every cycle. The band beats on two periods of different ' +
      'length, so one stretch of shore surges while the opposite side draws back. At rest ' +
      '(and in every still render) the band is its plain Shallows albedo whatever this is set ' +
      'to — the surf only appears once a host drives userData.tick.',
  },
  drift: {
    type: 'range', default: 1, min: 0, max: 2.5, label: 'Drift', affects: 'material',
    describe: 'Lateral movement of the water sheet. The surface never rises or falls — nothing ' +
      'in a kit floats, so a rising sheet would pass through every rock and jetty placed in it ' +
      '— this shears it sideways instead, by at most ~35 mm. 0 freezes it, 1 is a gentle ' +
      'current, 2.5 is a running stream.',
  },
  spread: {
    type: 'range', default: 1.0, min: 0.7, max: 1.15, affects: 'geometry', label: 'Spread',
    describe: 'How far the patch reaches: 0.7 is a 5.6 m puddle, 1.0 the standard 8.0 m pond, ' +
      '1.15 a 9.2 m lake bay. It REBUILDS rather than scaling — the outline keeps a constant ' +
      '~1.5 m facet pitch, so a bigger patch is cut from more sides and more rings (176 ' +
      'triangles at 0.7, 320 at 1.0, 396 at 1.15) and the facets stay the same size in metres.',
  },
  elongation: {
    type: 'range', default: 0.85, min: 0.4, max: 1.0, affects: 'geometry', label: 'Elongation',
    describe: 'Depth of the patch across Z against its 8 m width. 1.0 is a round pond; 0.85 is ' +
      'the default broad oval; 0.4 squeezes it to a 3.2 m wide reach that clones end to end ' +
      'into a winding river. Only the Z axis moves — the outline lobes and the facet lattice ' +
      'are rebuilt to the new proportion, not stretched from the round one.',
  },
  ruggedness: {
    type: 'range', default: 1.0, min: 0.3, max: 1.45, affects: 'geometry', label: 'Ruggedness',
    describe: 'How wildly the shoreline wanders. 0.3 is an almost calm rounded oval for a still ' +
      'formal pool; 1.0 is the default woodland outline with lobes and one bay biting the +Z ' +
      'side; 1.45 cuts deep concave bays between blunt headlands, which is what makes overlapped ' +
      'clones read as a natural waterline rather than as a row of bubbles.',
  },
};

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }
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

const SPAN = 8.0;
const Y_TOP = 0.040;
const Y_RIM = 0.022;
const Y_UND = 0.008;
const R_RIM = 0.96;
const R_UND = 0.72;
const SHORE_IN = 0.78;
const SHORE_MID = 0.89;

function angDiff(a, b) {
  let d = (a - b) % (Math.PI * 2);
  if (d > Math.PI) d -= Math.PI * 2;
  if (d < -Math.PI) d += Math.PI * 2;
  return d;
}
function profile(t, rug) {
  const f = 0.040 * Math.sin(t * 2 + 0.62)
    + 0.086 * Math.sin(t * 3 - 1.94)
    + 0.074 * Math.sin(t * 5 + 2.71)
    + 0.045 * Math.sin(t * 7 + 0.35)
    + 0.024 * Math.sin(t * 11 - 0.80)
    - 0.185 * Math.exp(-Math.pow(angDiff(t, Math.PI / 2) / 0.42, 2))
    + 0.095 * Math.exp(-Math.pow(angDiff(t, -Math.PI / 2) / 0.40, 2));
  return Math.max(0.48, Math.min(1.45, 1 + f * rug));
}

export function createAsset(opts = {}) {

  const cw = COLORWAYS[opts.colorway] ? opts.colorway : params.colorway.default;
  const C = { ...COLORWAYS[params.colorway.default], ...COLORWAYS[cw] };
  for (const k of ['water', 'shore', 'bed']) {
    if (typeof opts[k] === 'string') C[k] = opts[k];
  }
  const num = (k) => {
    const s = params[k];
    const v = opts[k] === undefined ? s.default : Number(opts[k]);
    return Number.isFinite(v) ? Math.max(s.min, Math.min(s.max, v)) : s.default;
  };
  const sp = num('spread');
  const elong = num('elongation');
  const rug = num('ruggedness');
  const surf = num('surf');
  const drift = num('drift');
  const foamCol = typeof opts.foamColor === 'string' ? opts.foamColor : C.crest;

  const g = new THREE.Group();
  g.name = 'water-blob';

  const N = Math.max(11, Math.min(20, Math.round(16 * sp)));
  const K = Math.max(4, Math.min(8, Math.round(6 * sp)));

  const RINGS = [0];
  for (let i = 1; i <= K; i++) RINGS.push(SHORE_IN * Math.sqrt(i / K));
  RINGS.push(SHORE_MID, 1.0);

  const zoneOf = (i) => (RINGS[i] >= SHORE_IN - 1e-9 ? 'shore' : 'water');

  const rand = prng(9);
  const RX = [], RZ = [];
  for (let i = 0; i < RINGS.length; i++) {
    RX.push([]); RZ.push([]);
    if (RINGS[i] === 0) { RX[i].push(0); RZ[i].push(0); continue; }
    const jit = (i > 0 && i < K) ? 0.030 * (1 - i / K) + 0.008 : 0;
    for (let j = 0; j < N; j++) {
      const t = (j / N) * Math.PI * 2;
      const r = profile(t, rug) * RINGS[i] * (1 + (rand() - 0.5) * 2 * jit);
      RX[i].push(Math.cos(t) * r);
      RZ[i].push(Math.sin(t) * r);
    }
  }

  const O = RINGS.length - 1;
  let minX = Infinity, maxX = -Infinity, minZ = Infinity, maxZ = -Infinity;
  for (let j = 0; j < N; j++) {
    minX = Math.min(minX, RX[O][j]); maxX = Math.max(maxX, RX[O][j]);
    minZ = Math.min(minZ, RZ[O][j]); maxZ = Math.max(maxZ, RZ[O][j]);
  }
  const SX = (SPAN * sp) / (maxX - minX), SZ = (SPAN * sp * elong) / (maxZ - minZ);
  const OX = -(minX + maxX) / 2, OZ = -(minZ + maxZ) / 2;
  const P = [];
  for (let i = 0; i < RINGS.length; i++) {
    P.push(RX[i].map((x, j) => [(x + OX) * SX, Y_TOP, (RZ[i][j] + OZ) * SZ]));
  }

  const zones = { water: [], shore: [], bed: [] };

  const fanUp = (out, ring, y) => {
    for (let j = 0; j < N; j++) tri(out, [0, y, 0], ring[(j + 1) % N], ring[j]);
  };
  const stripUp = (out, inner, outer) => {
    for (let j = 0; j < N; j++) {
      const k = (j + 1) % N;
      tri(out, inner[j], inner[k], outer[k]);
      tri(out, inner[j], outer[k], outer[j]);
    }
  };

  fanUp(zones[zoneOf(0)], P[1], Y_TOP);
  for (let i = 1; i < RINGS.length - 1; i++) stripUp(zones[zoneOf(i)], P[i], P[i + 1]);

  const shrink = (f, y) => P[O].map((p) => [p[0] * f, y, p[2] * f]);
  const B1 = shrink(R_RIM, Y_RIM);
  const B2 = shrink(R_UND, Y_UND);
  const B = zones.bed;
  for (let j = 0; j < N; j++) {
    const k = (j + 1) % N;
    quad(B, P[O][j], P[O][k], B1[k], B1[j]);
  }
  for (let j = 0; j < N; j++) {
    const k = (j + 1) % N;
    quad(B, B1[j], B1[k], B2[k], B2[j]);
  }
  for (let j = 0; j < N; j++) tri(B, [0, 0, 0], B2[j], B2[(j + 1) % N]);

  const mat = new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });

  mat.onBeforeCompile = (shader) => {
    shader.uniforms.uTime = { value: 0 };
    shader.uniforms.uShore = { value: new THREE.Color(C.shore) };
    shader.uniforms.uCrest = { value: new THREE.Color(foamCol) };
    shader.uniforms.uDrift = { value: 0.035 * drift };
    shader.uniforms.uSurf = { value: surf };
    shader.uniforms.uHalf = { value: new THREE.Vector2(SPAN * sp * 0.5, SPAN * sp * elong * 0.5) };
    shader.vertexShader = shader.vertexShader
      .replace('#include <common>', '#include <common>\n'
        + 'uniform float uTime; uniform vec3 uShore; uniform vec3 uCrest;\n'
        + 'uniform float uDrift; uniform float uSurf; uniform vec2 uHalf;')
      .replace('#include <begin_vertex>', '#include <begin_vertex>\n'

        + '  float rN = length(position.xz / uHalf);\n'
        + '  float isWater = (1.0 - smoothstep(0.42, 0.86, rN)) * step(0.030, position.y);\n'

        + '  float px = (sin(position.z * 0.72 + uTime * 0.53) - sin(position.z * 0.72))\n'
        + '           + (sin(position.z * 1.55 - uTime * 0.31) - sin(position.z * 1.55)) * 0.5;\n'
        + '  float pz = (sin(position.x * 0.66 - uTime * 0.44) - sin(position.x * 0.66))\n'
        + '           + (sin(position.x * 1.37 + uTime * 0.27) - sin(position.x * 1.37)) * 0.5;\n'
        + '  transformed.x += px * uDrift * isWater;\n'
        + '  transformed.z += pz * uDrift * isWater;\n'

        + '  float isRing = 1.0 - smoothstep(0.02, 0.10, distance(color, uShore));\n'

        + '  float sp1 = (position.x + position.z) * 0.12;\n'
        + '  float sp2 = (position.x - position.z) * 0.075;\n'
        + '  float a  = sin(uTime * 0.41 + sp1) - sin(sp1);\n'
        + '  float b2 = sin(uTime * 0.67 - sp2) - sin(-sp2);\n'
        + '  float swell = clamp(0.34 * a + 0.22 * b2, 0.0, 1.0);\n'
        + '  float wet = clamp(swell * uSurf * 0.7, 0.0, 1.0);\n'
        + '  vColor.rgb = mix(vColor.rgb, mix(uShore, uCrest, wet), isRing);');
    mat.userData.shader = shader;
  };

  mat.customProgramCacheKey = () => 'natureWaterBlobWaves';

  const merged = mergeGeometries([
    prep(posGeo(zones.water), C.water),
    prep(posGeo(zones.shore), C.shore),
    prep(posGeo(zones.bed), C.bed),
  ]);
  if (!merged) throw new Error('water-blob: mergeGeometries returned null');
  merged.computeVertexNormals();
  g.add(new THREE.Mesh(merged, mat));

  g.userData.tick = (t) => {
    const sh = mat.userData.shader;
    if (sh) sh.uniforms.uTime.value = t;
  };
  return g;
}

export const rig = {};
export const detach = [];
export const night = {};
export default createAsset;
