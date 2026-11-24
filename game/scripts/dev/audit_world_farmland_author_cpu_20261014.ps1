param(
    [string]$AuthorPath = 'game/scripts/dev/world_farmland_coherent_author_v2_20261014.gd',
    [string]$OutputPath = 'game/build/world_farmland_author_cpu_20261014/result.json',
    [switch]$Scout
)
$ErrorActionPreference = 'Stop'
$auditRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$projectRoot = $auditRoot
Set-Location -LiteralPath $projectRoot
$roadPath = Join-Path $projectRoot 'game/art/maps/world_map_v15_complete_v9c/capture/roads_reconstructed.png'
$ecoPath = Join-Path $projectRoot 'game/art/maps/world_map_v15_complete_v9c/capture/ecology_reconstructed.png'
$rfPath = Join-Path $projectRoot 'game/art/maps/world_map_v15_complete_v9c/terrain_height.rf'
$expected = @{
    $roadPath = '77DBEE9E3D4B73972F4A272A95BE2568B6A4D85187583EBB95F02F709DBEE05E'
    $ecoPath = '174092AF13CF00F6802968EE0277DF86C1E64993A7A3F2FA06A3056E89EB8A51'
    $rfPath = '7158EAF91C38CE55541E895B449EE5645A772A2CD037479357EEDAF1917E6F4B'
}
$before = @{}
foreach ($path in $expected.Keys) {
    $item = Get-Item -LiteralPath $path
    $sha = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ($sha -ne $expected[$path]) { throw "Original audit input changed: $path" }
    $before[$path] = @{ sha256=$sha; bytes=$item.Length; ticks=$item.LastWriteTimeUtc.Ticks }
}
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Drawing;
public sealed class FarmNativeCpuAudit : IDisposable {
  readonly Bitmap road, eco;
  readonly byte[] rf;
  public FarmNativeCpuAudit(string roads, string ecology, string heights) {
    road = new Bitmap(roads); eco = new Bitmap(ecology); rf = System.IO.File.ReadAllBytes(heights);
    if (road.Width != 3072 || road.Height != 2048 || eco.Width != 3072 || eco.Height != 2048 || rf.Length != 1537*1025*4) throw new Exception("Exact original owner/RF shape required");
  }
  double H(double x, double y) {
    double qx=x/8.0, qy=y/8.0; int ix=Math.Max(0,Math.Min(1535,(int)Math.Floor(qx))), iy=Math.Max(0,Math.Min(1023,(int)Math.Floor(qy)));
    double fx=qx-ix, fy=qy-iy; int off=(iy*1537+ix)*4;
    double a=BitConverter.ToSingle(rf,off), b=BitConverter.ToSingle(rf,off+4), c=BitConverter.ToSingle(rf,off+1537*4), d=BitConverter.ToSingle(rf,off+1537*4+4);
    return fx+fy<=1.0 ? a+(b-a)*fx+(c-a)*fy : d+(c-d)*(1.0-fx)+(b-d)*(1.0-fy);
  }
  static bool ChannelBad(Color v, bool alpha) { return v.R/255.0>=.02 || v.G/255.0>=.02 || v.B/255.0>=.02 || (alpha && v.A/255.0>=.02); }
  public int[] Audit(int cx,int cy,int hx,int hy) {
    int samples=0,bad=0,ecoBad=0,roadBad=0,waterBad=0;
    for(int y=cy-hy;y<=cy+hy;y+=4) for(int x=cx-hx;x<=cx+hx;x+=4) {
      bool eb=ChannelBad(eco.GetPixel(x/4,y/4),true), rb=false, wb=false;
      for(int dy=-32;dy<=32;dy+=32) for(int dx=-32;dx<=32;dx+=32) rb |= ChannelBad(road.GetPixel((x+dx)/4,(y+dy)/4),false);
      for(int dy=-64;dy<=64;dy+=64) for(int dx=-64;dx<=64;dx+=64) wb |= H(x+dx,y+dy)<-.015;
      samples++; if(eb)ecoBad++; if(rb)roadBad++; if(wb)waterBad++; if(eb||rb||wb)bad++;
    }
    return new[]{samples,bad,ecoBad,roadBad,waterBad};
  }
  public void Dispose() { road.Dispose(); eco.Dispose(); }
}
'@ -ReferencedAssemblies ([System.Drawing.Bitmap].Assembly.Location)
$audit = [FarmNativeCpuAudit]::new($roadPath,$ecoPath,$rfPath)
$timer = [System.Diagnostics.Stopwatch]::StartNew()
try {
    if ($Scout) {
        $candidates = @()
        foreach ($frame in @(@(3180,4220,3470,3940,130,105),@(6900,7350,6470,6750,100,50))) {
            for ($y=$frame[2]; $y -le $frame[3]; $y+=40) {
                for ($x=$frame[0]; $x -le $frame[1]; $x+=40) {
                    $r = $audit.Audit($x,$y,$frame[4],$frame[5])
                    if ($r[1] -eq 0) { $candidates += @{ parcel=@($x,$y,$frame[4],$frame[5]); samples=$r[0] } }
                }
            }
        }
        $candidates | ConvertTo-Json -Depth 4 -Compress
        exit 0
    }
    $absoluteAuthor = [System.IO.Path]::GetFullPath((Join-Path $projectRoot $AuthorPath))
    if (-not $absoluteAuthor.StartsWith($projectRoot+[System.IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Author outside project' }
    $authorSha = (Get-FileHash -LiteralPath $absoluteAuthor -Algorithm SHA256).Hash
    $source = Get-Content -LiteralPath $absoluteAuthor -Raw
    $parcels = [regex]::Matches($source,'Vector4\((\d+),(\d+),(\d+),(\d+)\)')
    if ($parcels.Count -lt 2 -or $parcels.Count -gt 16) { throw 'Expected bounded literal author parcels' }
    $rows = @(); $failures = @()
    foreach ($p in $parcels) {
        $cx=[int]$p.Groups[1].Value; $cy=[int]$p.Groups[2].Value; $hx=[int]$p.Groups[3].Value; $hy=[int]$p.Groups[4].Value
        $r=$audit.Audit($cx,$cy,$hx,$hy)
        $rows += @{ parcel=@($cx,$cy,$hx,$hy); samples=$r[0]; excluded=$r[1]; ecology_excluded=$r[2]; road_excluded=$r[3]; water_excluded=$r[4]; full_rectangle_clear=($r[1]-eq 0) }
        if ($r[1] -ne 0) { $failures += "Parcel $cx,$cy has $($r[1]) excluded samples" }
    }
    foreach ($path in $before.Keys) {
        $item=Get-Item -LiteralPath $path
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $before[$path].sha256 -or $item.Length -ne $before[$path].bytes -or $item.LastWriteTimeUtc.Ticks -ne $before[$path].ticks) { $failures += "Original source changed: $path" }
    }
    if ((Get-FileHash -LiteralPath $absoluteAuthor -Algorithm SHA256).Hash -ne $authorSha) { $failures += 'Author changed during audit' }
    $result=@{ scope='INDEPENDENT_CPU_FULL4PX_CLEARANCE_AUDIT_NOT_GPU_OR_FORMAL'; passed=($failures.Count-eq 0); parcel_count=$rows.Count; records=$rows; failures=$failures; author_path=$AuthorPath; author_sha256=$authorSha; source_before=$before; road_clearance_px=32; water_clearance_px=64; native_clearance_offsets=9; elapsed_ms=$timer.ElapsedMilliseconds; GPU_allocated=$false; NAV_changed=$false; formal_changed=$false }
    $absoluteOutput=[System.IO.Path]::GetFullPath((Join-Path $projectRoot $OutputPath))
    $allowed=[System.IO.Path]::GetFullPath((Join-Path $projectRoot 'game/build/world_farmland_author_cpu_20261014'))+[System.IO.Path]::DirectorySeparatorChar
    if (-not $absoluteOutput.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Audit output outside its own build directory' }
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($absoluteOutput))|Out-Null
    [System.IO.File]::WriteAllText($absoluteOutput,($result|ConvertTo-Json -Depth 8),[System.Text.UTF8Encoding]::new($false))
    ([pscustomobject]$result)|Select-Object scope,passed,parcel_count,elapsed_ms|ConvertTo-Json -Compress
    exit $(if ($result.passed) {0} else {1})
} finally { $audit.Dispose() }
