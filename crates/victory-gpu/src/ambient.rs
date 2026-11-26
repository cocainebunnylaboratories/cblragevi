//! A least amount of indirect light (ported from Belobug/VIctory-Belobug-AMD,
//! GPL-3.0-or-later).
//!
//! The title's indirect diffuse light comes from probes it fills by tracing
//! rays, which do not run here yet: its program that resolves them
//! (`CS_ScreenProbes_TemporalResolve_*`) leaves next to nothing, and whatever
//! the sun does not reach directly is black. Right after that program, its
//! output is replaced by a constant shaded by depth occlusion from the scene's
//! depth buffer. The title's own lighting then applies it with the surfaces'
//! colors.
//!
//! The trial is enabled with VICTORY_AMBIENT=1.

use std::sync::OnceLock;
use windows::Win32::Graphics::Direct3D::Fxc::D3DCompile;
use windows::Win32::Graphics::Direct3D::ID3DBlob;
use windows::Win32::Graphics::Direct3D12::*;
use windows::Win32::Graphics::Dxgi::Common::*;
use windows::core::s;

use crate::host::{HostList, host};
use crate::object::This;

/// The programs it follows, by the start of their name.
pub(crate) const PROGRAM: &[u8] = b"CS_ScreenProbes_TemporalResolve";
/// Where they write the indirect diffuse light (R9G9B9E5 as 32-bit
/// integers): root parameter and place in its table.
pub(crate) const LIGHT: (u8, u32) = (1, 176);

/// The resolve reads reversed scene depth here.
pub(crate) const DEPTH: (u8, u32) = (0, 464);

pub(crate) fn enabled() -> bool {
    static ON: OnceLock<bool> = OnceLock::new();
    *ON.get_or_init(|| std::env::var("VICTORY_AMBIENT").as_deref() == Ok("1"))
}

const SOURCE: &str = r#"
#define RS "RootConstants(num32BitConstants=8, b0), DescriptorTable(UAV(u0), SRV(t0))"
cbuffer Floor : register(b0) {
    float level; float3 tint;
    float strength; float radius; float near; float tan_y;
};
RWTexture2D<uint> light : register(u0);
Texture2D<float> depth : register(t0);
float3 seen(int2 p, float2 size) {
    float d = depth.Load(int3(clamp(p, int2(0, 0), int2(size) - 1), 0));
    float z = near / max(d, 1e-7);
    float2 ndc = (float2(p) + 0.5) / size * 2.0 - 1.0;
    return float3(ndc.x * tan_y * size.x / size.y * z, -ndc.y * tan_y * z, z);
}
float open_to_light(int2 p, float2 size) {
    float3 c = seen(p, size);
    if (c.z > 400.0) return 1.0;
    float3 l = seen(p + int2(-1, 0), size), r = seen(p + int2(1, 0), size);
    float3 u = seen(p + int2(0, -1), size), d = seen(p + int2(0, 1), size);
    float3 dx = abs(l.z - c.z) < abs(r.z - c.z) ? c - l : r - c;
    float3 dy = abs(u.z - c.z) < abs(d.z - c.z) ? c - u : d - c;
    float3 normal = cross(dy, dx);
    float length2 = dot(normal, normal);
    if (length2 < 1e-12) return 1.0;
    float3 n = normal * rsqrt(length2);
    if (dot(n, c) > 0.0) n = -n;
    float px = radius * size.y / (2.0 * tan_y * c.z);
    if (px < 1.5) return 1.0;
    px = min(px, 128.0);
    float noise = frac(52.9829189 * frac(dot(float2(p), float2(0.06711056, 0.00583715))));
    float sum = 0.0;
    const int N = 16;
    for (int i = 0; i < N; i++) {
        float a = i * 2.399963 + noise * 6.2831853;
        float2 o = float2(cos(a), sin(a)) * (sqrt((i + 0.5) / N) * px);
        float3 v = seen(p + int2(round(o)), size) - c;
        float vv = dot(v, v);
        float over = dot(v, n) - 0.004 * c.z - 0.005;
        sum += max(over, 0.0) / sqrt(vv + 1e-6) * saturate(1.0 - vv / (radius * radius));
    }
    return saturate(1.0 - strength * 2.0 * sum / N);
}
uint pack(float3 c) {
    c = clamp(c, 0.0, 65408.0);
    float most = max(c.r, max(c.g, c.b));
    int e = clamp(int(floor(log2(max(most, 1e-9)))) + 16, 0, 31);
    float scale = exp2(float(24 - e));
    if (most * scale >= 511.5) { e = min(e + 1, 31); scale = exp2(float(24 - e)); }
    uint3 m = min(uint3(c * scale + 0.5), 511u);
    return m.r | (m.g << 9) | (m.b << 18) | (uint(e) << 27);
}
[RootSignature(RS)]
[numthreads(8, 8, 1)]
void main(uint3 at : SV_DispatchThreadID) {
    uint w, h;
    light.GetDimensions(w, h);
    if (at.x >= w || at.y >= h) return;
    float open = strength > 0.0 ? open_to_light(int2(at.xy), float2(w, h)) : 1.0;
    light[at.xy] = pack(tint * level * open);
}
"#;

struct Pass {
    root: ID3D12RootSignature,
    pso: ID3D12PipelineState,
}
// SAFETY: D3D12 objects are free-threaded.
unsafe impl Send for Pass {}
// SAFETY: as above.
unsafe impl Sync for Pass {}

fn make(device: &ID3D12Device) -> windows::core::Result<Pass> {
    let mut code: Option<ID3DBlob> = None;
    let mut errors: Option<ID3DBlob> = None;
    // SAFETY: the source and names live through the call; out pointers ours.
    let compiled = unsafe {
        D3DCompile(
            SOURCE.as_ptr().cast(),
            SOURCE.len(),
            s!("ambient"),
            None,
            None,
            s!("main"),
            s!("cs_5_1"),
            0,
            0,
            &mut code,
            Some(&mut errors),
        )
    };
    let text = |b: &ID3DBlob| {
        // SAFETY: the blob's own bytes.
        unsafe { std::slice::from_raw_parts(b.GetBufferPointer().cast::<u8>(), b.GetBufferSize()) }
            .to_vec()
    };
    if let Err(e) = compiled {
        if let Some(errors) = errors {
            tracing::warn!("ambient light: {}", String::from_utf8_lossy(&text(&errors)));
        }
        return Err(e);
    }
    let code = text(&code.ok_or_else(windows::core::Error::empty)?);
    // SAFETY: the root signature is inside the shader; plain creations.
    unsafe {
        let root: ID3D12RootSignature = device.CreateRootSignature(0, &code)?;
        let pso = device.CreateComputePipelineState(&D3D12_COMPUTE_PIPELINE_STATE_DESC {
            pRootSignature: std::mem::transmute_copy(&root),
            CS: D3D12_SHADER_BYTECODE {
                pShaderBytecode: code.as_ptr().cast(),
                BytecodeLength: code.len(),
            },
            ..Default::default()
        })?;
        Ok(Pass { root, pso })
    }
}

fn uav_barrier(list: &ID3D12GraphicsCommandList) {
    let barrier = D3D12_RESOURCE_BARRIER {
        Type: D3D12_RESOURCE_BARRIER_TYPE_UAV,
        ..Default::default()
    };
    // SAFETY: an open list; the barrier names no resource.
    unsafe { list.ResourceBarrier(&[barrier]) };
}

/// Raises what `light` holds to the floor, in `list`, after the program that
/// wrote it as an image. Whether it recorded anything (the list's bindings
/// are then ours).
pub(crate) fn raise(list: &HostList, light_id: This, depth_id: This) -> bool {
    let (Some(host), Some(light), Some(depth)) = (
        host(),
        crate::resource::ambient_texture(light_id),
        crate::resource::ambient_texture(depth_id),
    ) else {
        tracing::debug!("ambient skipped: host textures unavailable");
        return false;
    };
    record(host, list, &light, &depth)
}

fn record(
    host: &crate::host::Host,
    list: &HostList,
    light: &ID3D12Resource,
    depth: &ID3D12Resource,
) -> bool {
    // SAFETY: the owned references keep both resources live.
    let (d, z) = unsafe { (light.GetDesc(), depth.GetDesc()) };
    let plain = |r: &D3D12_RESOURCE_DESC| {
        r.Dimension == D3D12_RESOURCE_DIMENSION_TEXTURE2D
            && r.DepthOrArraySize == 1
            && r.SampleDesc.Count == 1
    };
    if !plain(&d)
        || !plain(&z)
        || d.Format != DXGI_FORMAT_R32_UINT
        || !d.Flags.contains(D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS)
        || z.Format != DXGI_FORMAT_R32G8X24_TYPELESS
        || z.Flags.contains(D3D12_RESOURCE_FLAG_DENY_SHADER_RESOURCE)
        || (d.Width, d.Height) != (z.Width, z.Height)
    {
        static WARN: std::sync::Once = std::sync::Once::new();
        WARN.call_once(|| tracing::warn!(?d, ?z, "ambient skipped: unsupported light or depth"));
        return false;
    }
    static PASS: OnceLock<Option<Pass>> = OnceLock::new();
    let Some(pass) = PASS.get_or_init(|| {
        make(&host.device)
            .inspect_err(|e| tracing::warn!(error = %e, "ambient pipeline unavailable"))
            .ok()
    }) else {
        return false;
    };
    // The recorded list owns these immutable descriptors through its last execution.
    let kind = D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV;
    let desc = D3D12_DESCRIPTOR_HEAP_DESC {
        Type: kind,
        NumDescriptors: 2,
        Flags: D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE,
        NodeMask: 0,
    };
    // SAFETY: a valid heap description on the active device.
    let Ok(views): windows::core::Result<ID3D12DescriptorHeap> =
        (unsafe { host.device.CreateDescriptorHeap(&desc) })
    else {
        return false;
    };
    let step = unsafe { host.device.GetDescriptorHandleIncrementSize(kind) };
    list.keep(&views);
    list.keep(light);
    list.keep(depth);
    static ACTIVE: std::sync::Once = std::sync::Once::new();
    ACTIVE.call_once(|| {
        tracing::info!(
            width = d.Width,
            height = d.Height,
            "depth-shaded ambient pass recorded"
        )
    });
    #[cfg(feature = "diagnostics")]
    list.note_op(|| "ambient depth-shaded".into());
    let l = &list.list;
    uav_barrier(l);
    // SAFETY: an open list; a live texture the list keeps, in the
    // unordered-access state as the program before left it; a view in a slot
    // no list in flight reads.
    unsafe {
        let cpu = views.GetCPUDescriptorHandleForHeapStart();
        let gpu = views.GetGPUDescriptorHandleForHeapStart();
        let at = D3D12_CPU_DESCRIPTOR_HANDLE { ptr: cpu.ptr };
        let view = D3D12_UNORDERED_ACCESS_VIEW_DESC {
            Format: DXGI_FORMAT_R32_UINT,
            ViewDimension: D3D12_UAV_DIMENSION_TEXTURE2D,
            ..Default::default()
        };
        host.device
            .CreateUnorderedAccessView(light, None::<&ID3D12Resource>, Some(&view), at);
        let seen = D3D12_SHADER_RESOURCE_VIEW_DESC {
            Format: DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS,
            ViewDimension: D3D12_SRV_DIMENSION_TEXTURE2D,
            Shader4ComponentMapping: D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING,
            Anonymous: D3D12_SHADER_RESOURCE_VIEW_DESC_0 {
                Texture2D: D3D12_TEX2D_SRV {
                    MipLevels: 1,
                    ..Default::default()
                },
            },
        };
        let beside = D3D12_CPU_DESCRIPTOR_HANDLE {
            ptr: at.ptr + step as usize,
        };
        host.device
            .CreateShaderResourceView(depth, Some(&seen), beside);
        l.SetDescriptorHeaps(&[Some(views.clone())]);
        l.SetComputeRootSignature(&pass.root);
        l.SetPipelineState(&pass.pso);
        let constants: [f32; 8] = [0.6, 1.0, 0.98, 0.94, 1.0, 0.6, 0.1, 0.45];
        l.SetComputeRoot32BitConstants(0, 8, constants.as_ptr().cast(), 0);
        l.SetComputeRootDescriptorTable(1, D3D12_GPU_DESCRIPTOR_HANDLE { ptr: gpu.ptr });
        l.Dispatch((d.Width as u32).div_ceil(8), d.Height.div_ceil(8), 1);
    }
    uav_barrier(l);
    #[cfg(feature = "diagnostics")]
    list.note_op(|| "after ambient".into());
    true
}

#[cfg(test)]
mod tests {
    /// The pass compiles with the system's compiler and the host takes it.
    #[test]
    fn ambient_pass_builds() {
        let Some(host) = crate::host::host() else {
            return;
        };
        super::make(&host.device).expect("the ambient pass");
    }
}

#[cfg(all(test, feature = "diagnostics"))]
#[test]
#[ignore = "requires a D3D12 device"]
fn ambient_dispatch_writes_expected_flat_light() {
    let host = host().expect("D3D12 device");
    let make_texture = |format, flags, state, width| {
        let desc = D3D12_RESOURCE_DESC {
            Dimension: D3D12_RESOURCE_DIMENSION_TEXTURE2D,
            Width: width,
            Height: 9,
            DepthOrArraySize: 1,
            MipLevels: 1,
            Format: format,
            SampleDesc: DXGI_SAMPLE_DESC {
                Count: 1,
                Quality: 0,
            },
            Flags: flags,
            ..Default::default()
        };
        let props = D3D12_HEAP_PROPERTIES {
            Type: D3D12_HEAP_TYPE_DEFAULT,
            ..Default::default()
        };
        let mut resource = None;
        // SAFETY: committed textures have zero-initialized storage and one sample.
        unsafe {
            host.device.CreateCommittedResource(
                &props,
                D3D12_HEAP_FLAG_NONE,
                &desc,
                state,
                None,
                &mut resource,
            )
        }
        .unwrap();
        resource.unwrap()
    };
    let uav = D3D12_RESOURCE_STATE_UNORDERED_ACCESS;
    let srv = D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE;
    let light = make_texture(
        DXGI_FORMAT_R32_UINT,
        D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS,
        uav,
        9,
    );
    let depth = |width| {
        make_texture(
            DXGI_FORMAT_R32G8X24_TYPELESS,
            D3D12_RESOURCE_FLAG_ALLOW_DEPTH_STENCIL,
            srv,
            width,
        )
    };
    let list = host.new_list().unwrap();
    assert!(!record(host, &list, &light, &depth(8)));
    assert!(record(host, &list, &light, &depth(9)));
    // SAFETY: light was written as a UAV and now becomes the copy source.
    unsafe {
        list.list.ResourceBarrier(&[crate::host::transition(
            &light,
            uav,
            D3D12_RESOURCE_STATE_COPY_SOURCE,
        )])
    };
    let (buf, layout) = crate::capture::read_back(&host.device, &list.list, &light).unwrap();
    list.close();
    host.execute(&[&list]);
    let mut ptr = std::ptr::null_mut();
    // SAFETY: execute waited and the mapped footprint contains all nine rows.
    unsafe {
        buf.Map(0, None, Some(&mut ptr)).unwrap();
        for y in 0..9 {
            let row = ptr
                .cast::<u8>()
                .add(layout.Offset as usize + y * layout.Footprint.RowPitch as usize);
            for x in 0..9 {
                assert_eq!(
                    *row.cast::<u32>().add(x),
                    307 | (301 << 9) | (289 << 18) | (15 << 27)
                );
            }
        }
        buf.Unmap(0, None);
    }
}
