param([string]$Workspace='F:\Code\RPG_GAME',[string]$Author='luoyang_harbour_life_author_20261016.gd',[string]$Crowd='luoyang_harbour_life_crowd_20261016.gd')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies @('System.Drawing.Common','System.Drawing.Primitives','System.Private.Windows.GdiPlus','System.Private.Windows.Core') -TypeDefinition @'
using System; using System.Collections.Generic; using System.Drawing;
public class HarbourScout {
 public static bool Inside(double x,double y,double[][] p) {bool inside=false;for(int i=0,j=p.Length-1;i<p.Length;j=i++) if(((p[i][1]>y)!=(p[j][1]>y))&&(x<(p[j][0]-p[i][0])*(y-p[i][1])/(p[j][1]-p[i][1])+p[i][0])) inside=!inside; return inside;}
 public static string Check(string png,double[][][] solids,double[][] points,int halfY) {
  if(solids==null) solids=new double[0][][];
  using(var image=new Bitmap(png)) for(int i=0;i<points.Length-1;i++) {
   double dx=points[i+1][0]-points[i][0],dy=points[i+1][1]-points[i][1]; int n=Math.Max(1,(int)Math.Ceiling(Math.Sqrt(dx*dx+dy*dy)/4));
   for(int j=0;j<=n;j++) {double x=points[i][0]+dx*j/n,y=points[i][1]+dy*j/n;
    for(int oy=-halfY;oy<=halfY;oy++) for(int ox=-17;ox<=17;ox++) {double px=x+ox,py=y+oy;int ix=(int)Math.Round(px),iy=(int)Math.Round(py);
     if(ix<0||iy<0||ix>=image.Width||iy>=image.Height) return "OUTSIDE "+x+","+y;
     Color c=image.GetPixel(ix,iy);if(c.A<128||c.R<128)return "OLD_MASK "+x+","+y+" sample "+ix+","+iy;
     for(int k=0;k<solids.Length;k++) if(Inside(px,py,solids[k])) return "NEW_SOLID "+k+" foot "+x+","+y+" sample "+px+","+py;
    }
   }
  } return "CLEAR";
 }
}
'@
$taskAuthor=Get-Content -LiteralPath (Join-Path $Workspace ('game/scripts/city/'+$Author)) -Raw
$taskCrowd=Get-Content -LiteralPath (Join-Path $Workspace ('game/scripts/city/'+$Crowd)) -Raw
$taskDock='res://art/maps/luoyang_city_revision_v1_20261015/ch4_s2_canal_docks/candidate_manifest.json'
$taskMarket='res://art/maps/luoyang_city_revision_retry2_20261015/ch4_s3_luoyang_market/candidate_manifest.json'
function Local([string]$Value){ Join-Path $Workspace ('game/'+$Value.Substring(6)) }
$taskParent=Get-Content -LiteralPath (Local $taskDock) -Raw|ConvertFrom-Json
$taskComponents=Get-Content -LiteralPath (Join-Path $Workspace 'game/art/maps/luoyang_harbour_life_20261016/components-author-v1.json') -Raw|ConvertFrom-Json
$taskSolids=[System.Collections.Generic.List[double[][]]]::new()
$taskSolidIDs=[System.Collections.Generic.List[string]]::new()
foreach($taskLine in ($taskAuthor -split "`n")) {
 if($taskLine -notmatch '^\s*\{"id":'){continue}
 $taskJSON=[regex]::Match($taskLine,'^\s*(\{.*\})[,\]]*').Groups[1].Value.Replace('"manifest":DOCK',('"manifest":"'+$taskDock+'"')).Replace('"manifest":MARKET',('"manifest":"'+$taskMarket+'"'))
 try {$taskItem=$taskJSON|ConvertFrom-Json}catch{continue}
 if($taskItem.manifest) {
  $taskDonor=Get-Content -LiteralPath (Local $taskItem.manifest) -Raw|ConvertFrom-Json
  $taskSource=@($taskDonor.objects|Where-Object id -eq $taskItem.source_id)[0]
  foreach($taskPolygon in $taskSource.solid_polygons_px) {
   $taskPoints=[System.Collections.Generic.List[double[]]]::new()
   foreach($taskPoint in $taskPolygon) { $taskPoints.Add([double[]]@(([single]($taskItem.foot[0]+([single]$taskPoint[0]-[single]$taskSource.world_foot_px[0])*$taskItem.ratio)),([single]($taskItem.foot[1]+([single]$taskPoint[1]-[single]$taskSource.world_foot_px[1])*$taskItem.ratio)))) }
   $taskSolids.Add($taskPoints.ToArray());$taskSolidIDs.Add($taskItem.id)
  }
 } elseif($taskItem.component -eq 'harbour_warehouse_v1') {
  $taskSource=@($taskComponents.components|Where-Object id -eq $taskItem.component)[0]
  foreach($taskPolygon in $taskSource.ground_solid_polygons_px) {
   $taskPoints=[System.Collections.Generic.List[double[]]]::new()
   foreach($taskPoint in $taskPolygon) {$taskPoints.Add([double[]]@(([single]($taskItem.foot[0]+($taskPoint[0]-$taskSource.source_ground_anchor_px[0])*$taskItem.scale)),([single]($taskItem.foot[1]+($taskPoint[1]-$taskSource.source_ground_anchor_px[1])*$taskItem.scale))))}
   $taskSolids.Add($taskPoints.ToArray());$taskSolidIDs.Add($taskItem.id)
  }
 }
}
Write-Output ('SOURCE_SOLIDS='+($taskSolidIDs -join ','))
foreach($taskRoute in $taskParent.routes) {
 $taskPoints=[System.Collections.Generic.List[double[]]]::new();foreach($taskPoint in $taskRoute.points_px){$taskPoints.Add([double[]]$taskPoint)}
 $taskResult=[HarbourScout]::Check((Local $taskParent.walk_path),$taskSolids.ToArray(),$taskPoints.ToArray(),12)
 Write-Output ($taskRoute.id+': '+$taskResult)
}
$taskRows=[regex]::Matches($taskCrowd,'\["(gate_|docks_)[^\r\n]+')
foreach($taskMatch in $taskRows) {
 $taskJSON=$taskMatch.Value.Trim().TrimEnd(',').TrimEnd(']')+']'
 try {$taskRow=$taskJSON|ConvertFrom-Json}catch{Write-Output ('PARSE '+$taskMatch.Value);continue}
 $taskFoot=$taskRow[2];$taskDistance=$taskRow[3]
 $taskPoints=[double[][]]@([double[]]@(($taskFoot[0]-$taskDistance),$taskFoot[1]),[double[]]@(($taskFoot[0]+$taskDistance),$taskFoot[1]))
 $taskMask=if($taskRow[0].StartsWith('gate_')){Join-Path $Workspace 'game/art/maps/luoyang_gate_fortification_v3_refined/walk.png'}else{Local $taskParent.walk_path}
 $taskPolys=if($taskRow[0].StartsWith('gate_')){[double[][][]]@()}else{$taskSolids.ToArray()}
 Write-Output ($taskRow[0]+': '+[HarbourScout]::Check($taskMask,$taskPolys,$taskPoints,15))
}
Write-Output 'SCOUT_ONLY: original cooked mask plus new bases; not independent raw raster, continuous875+17 or Physics acceptance.'
