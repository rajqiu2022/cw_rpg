<#
Diagnostics only, not WASAPI/playback/Field/RELEASE approval. Caller must supply
a NEW directory below game/build/joint_world_luoyang_20261003_qa. No overwrite.
No endpoint activation/property store/setter/service/registry/session changes.
Only the read-only enumerator COM object is created; IMMDevice.Activate and
OpenPropertyStore below are UNUSED ABI slots preceding GetId/GetState.

ABI checked 2026-10-08 against Microsoft's complete generated SDK header:
https://raw.githubusercontent.com/microsoft/win32metadata/main/generation/WinSDK/RecompiledIdlHeaders/um/mmdeviceapi.h
Lines391-417: IMMDevice IID; Activate(REFIID,DWORD,PROPVARIANT*,void**),
OpenPropertyStore(DWORD,IPropertyStore**), GetId(LPWSTR*), GetState(DWORD*).
Lines522-534: IMMDeviceCollection IID; GetCount(UINT*), Item(UINT,IMMDevice**).
Lines695-726: IMMDeviceEnumerator IID; first slots EnumAudioEndpoints
(EDataFlow,DWORD,IMMDeviceCollection**), GetDefaultAudioEndpoint
(EDataFlow,ERole,IMMDevice**). Unused trailing slots are intentionally omitted.
Lines130-134/175-186/1401: state mask15, render0, roles0/1/2, enumerator CLSID.
https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdevice-getid
Returned ID is opaque; its allocation is freed using CoTaskMemFree.
https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdeviceenumerator-getdefaultaudioendpoint
Failure HRESULT is retained, not turned into a guessed device/session cause.
https://learn.microsoft.com/en-us/windows/win32/api/combaseapi/nf-combaseapi-coinitializeex
https://learn.microsoft.com/en-us/windows/win32/api/combaseapi/nf-combaseapi-cocreateinstance
HRESULTs use PreserveSig; successful COM initialization is balanced, including
S_FALSE. COM references are released on the SAME MTA worker thread in finally.
The join bounds observation time. A native call that does not return produces
INCOMPLETE/TIMEOUT, never success; the worker is background-only and is reclaimed
at natural termination of this standalone PowerShell process. No thread abort.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [ValidateRange(1,30)][int]$TimeoutSeconds=15
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Windows-only read-only diagnostic' }
$taskWorkspace=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$evidenceRoot=(Resolve-Path -LiteralPath (Join-Path $taskWorkspace 'game\build\joint_world_luoyang_20261003_qa')).Path
$targetDirectory=[IO.Path]::GetFullPath($OutputDirectory)
$requiredPrefix=$evidenceRoot.TrimEnd('\')+'\'
if (-not $targetDirectory.StartsWith($requiredPrefix,[StringComparison]::OrdinalIgnoreCase) -or $targetDirectory -eq $evidenceRoot) { throw 'Output must be a new child of the existing QA BUILD evidence root' }
if (Test-Path -LiteralPath $targetDirectory) { throw 'Evidence directory already exists; no overwrites allowed' }
$targetParent=[IO.Path]::GetDirectoryName($targetDirectory)
if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) { throw 'Caller must provide an existing parent directory' }
for ($ancestor=Get-Item -LiteralPath $targetParent; $null -ne $ancestor; $ancestor=$ancestor.Parent) {
    if (($ancestor.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Reparse-point output ancestors are not allowed' }
    if ($ancestor.FullName -eq $evidenceRoot) { break }
}
function Get-ReadonlyFileRecord([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return [ordered]@{path=$Path;exists=$false} }
    $item=Get-Item -LiteralPath $Path
    return [ordered]@{path=$item.FullName;exists=$true;sha256=(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$item.Length;utc_ticks=[string]$item.LastWriteTimeUtc.Ticks}
}
$projectPath=Join-Path $taskWorkspace 'game\project.godot'
$projectText=[IO.File]::ReadAllText($projectPath)
$expectedProjectName=[string]::Concat([char]0x4E91,[char]0x5F71,[char]0x4FA0,[char]0x4F20)
$projectNamePattern='(?m)^config/name="'+[regex]::Escape($expectedProjectName)+'"\r?$'
if ($projectText -notmatch $projectNamePattern -or $projectText -match '(?m)^config/use_custom_user_dir=true\r?$') { throw 'Normal player-directory contract changed; do not guess another save directory' }
$playerDirectory=Join-Path ([Environment]::GetFolderPath('ApplicationData')) ('Godot\app_userdata\'+$expectedProjectName)
function Get-ReadonlyPlayerSnapshot {
    foreach ($slot in 0..4) {
        foreach ($suffix in @('','.bak','.tmp')) { Get-ReadonlyFileRecord (Join-Path $playerDirectory ('save_'+$slot+'.json'+$suffix)) }
    }
}
$startedUtc=[datetime]::UtcNow.ToString('o')
$sourceBefore=@(Get-ReadonlyFileRecord $PSCommandPath; Get-ReadonlyFileRecord $projectPath)
$playersBefore=@(Get-ReadonlyPlayerSnapshot)
$currentProcess=[Diagnostics.Process]::GetCurrentProcess()
$processEvidence=[ordered]@{pid=$currentProcess.Id;session_id=$currentProcess.SessionId;started_utc=$currentProcess.StartTime.ToUniversalTime().ToString('o');executable_path=$currentProcess.MainModule.FileName;executable_sha256=(Get-FileHash -LiteralPath $currentProcess.MainModule.FileName -Algorithm SHA256).Hash.ToLowerInvariant();powershell_version=$PSVersionTable.PSVersion.ToString();apartment=[Threading.Thread]::CurrentThread.ApartmentState.ToString()}
$currentProcess.Dispose()
$nativeSource=@'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;
namespace JointReadonlyEndpoints20261008 {
    [ComImport, Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IMMDeviceEnumerator {
        [PreserveSig] int EnumAudioEndpoints(int flow, uint states, out IMMDeviceCollection devices);
        [PreserveSig] int GetDefaultAudioEndpoint(int flow, int role, out IMMDevice device);
    }
    [ComImport, Guid("0BD7A1BE-7A1A-44DB-8397-CC5392387B5E"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IMMDeviceCollection {
        [PreserveSig] int GetCount(out uint count);
        [PreserveSig] int Item(uint index, out IMMDevice device);
    }
    [ComImport, Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IMMDevice {
        [PreserveSig] int Activate(ref Guid iid, uint context, IntPtr parameters, out IntPtr result);
        [PreserveSig] int OpenPropertyStore(uint access, out IntPtr properties);
        [PreserveSig] int GetId(out IntPtr id);
        [PreserveSig] int GetState(out uint state);
    }
    public static class Reader {
        [DllImport("ole32.dll", ExactSpelling=true, PreserveSig=true)]
        static extern int CoInitializeEx(IntPtr reserved, uint flags);
        [DllImport("ole32.dll", ExactSpelling=true)] static extern void CoUninitialize();
        [DllImport("ole32.dll", ExactSpelling=true, PreserveSig=true)]
        static extern int CoCreateInstance(ref Guid clsid, IntPtr outer, uint context, ref Guid iid, out IMMDeviceEnumerator result);
        static Dictionary<string,object> Hr(int value) {
            return new Dictionary<string,object>{{"signed_int32",value},{"hex","0x"+unchecked((uint)value).ToString("X8")},{"succeeded",value>=0}};
        }
        static void Release(object value, List<string> errors) {
            if (value==null) return;
            try { if (Marshal.IsComObject(value)) Marshal.ReleaseComObject(value); }
            catch (Exception ex) { errors.Add("COM release: "+ex.GetType().FullName+": "+ex.Message); }
        }
        static Dictionary<string,object> Device(IMMDevice device) {
            var row=new Dictionary<string,object>();
            IntPtr id=IntPtr.Zero;
            try {
                int idHr=device.GetId(out id);
                row["get_id_hresult"]=Hr(idHr);
                row["opaque_endpoint_id"]=(idHr==0 && id!=IntPtr.Zero) ? Marshal.PtrToStringUni(id) : null;
                uint state=0;
                int stateHr=device.GetState(out state);
                row["get_state_hresult"]=Hr(stateHr);
                row["state_uint32"]=state;
                row["state_hex"]="0x"+state.ToString("X8");
                row["complete"]=idHr==0 && id!=IntPtr.Zero && stateHr==0;
                row["observed_utc"]=DateTime.UtcNow.ToString("o");
                return row;
            } finally { if (id!=IntPtr.Zero) Marshal.FreeCoTaskMem(id); }
        }
        static Dictionary<string,object> Observe() {
            var result=new Dictionary<string,object>();
            var cleanupErrors=new List<string>();
            var defaults=new List<Dictionary<string,object>>();
            var endpoints=new List<Dictionary<string,object>>();
            IMMDeviceEnumerator enumerator=null;
            IMMDeviceCollection collection=null;
            bool initialized=false;
            bool complete=true;
            result["diagnostics_complete"]=false;
            result["worker_apartment"]=Thread.CurrentThread.GetApartmentState().ToString();
            using (var process=Process.GetCurrentProcess()) {
                result["actual_process_id"]=process.Id;
                result["actual_session_id"]=process.SessionId;
            }
            result["started_utc"]=DateTime.UtcNow.ToString("o");
            result["defaults"]=defaults;
            result["render_endpoints_all_states"]=endpoints;
            result["cleanup_errors"]=cleanupErrors;
            try {
                int initHr=CoInitializeEx(IntPtr.Zero,0); // COINIT_MULTITHREADED
                result["co_initialize_hresult"]=Hr(initHr);
                if (initHr<0) return result;
                initialized=true;
                Guid clsid=new Guid("BCDE0395-E52F-467C-8E3D-C4579291692E");
                Guid iid=new Guid("A95664D2-9614-4F35-A746-DE8DB63617E6");
                int createHr=CoCreateInstance(ref clsid,IntPtr.Zero,1,ref iid,out enumerator);
                result["enumerator_creation_hresult"]=Hr(createHr);
                if (createHr!=0 || enumerator==null) return result;
                string[] roles={"eConsole","eMultimedia","eCommunications"};
                for (int role=0; role<3; role++) {
                    IMMDevice device=null;
                    var row=new Dictionary<string,object>{{"data_flow",0},{"role_int32",role},{"role",roles[role]},{"observed_utc",DateTime.UtcNow.ToString("o")}};
                    try {
                        int hr=enumerator.GetDefaultAudioEndpoint(0,role,out device);
                        row["get_default_hresult"]=Hr(hr);
                        row["returned_device_nonnull"]=device!=null;
                        if (hr==0 && device!=null) {
                            var details=Device(device);
                            row["device"]=details;
                            complete=complete && (bool)details["complete"];
                        } else if (hr>=0 || device!=null) complete=false;
                        // A captured negative HRESULT is an observation, not
                        // a successful endpoint and not a causal explanation.
                        defaults.Add(row);
                    } finally { Release(device,cleanupErrors); }
                }
                int enumHr=enumerator.EnumAudioEndpoints(0,15,out collection);
                result["enum_render_all_states_hresult"]=Hr(enumHr);
                result["enum_state_mask_uint32"]=15U;
                if (enumHr!=0 || collection==null) return result;
                uint count=0;
                int countHr=collection.GetCount(out count);
                result["get_count_hresult"]=Hr(countHr);
                result["reported_endpoint_count"]=count;
                result["maximum_enumeration_count"]=256;
                if (countHr!=0 || count>256) return result; // reject, never truncate
                for (uint index=0; index<count; index++) {
                    IMMDevice device=null;
                    var row=new Dictionary<string,object>{{"index",index}};
                    try {
                        int hr=collection.Item(index,out device);
                        row["item_hresult"]=Hr(hr);
                        row["returned_device_nonnull"]=device!=null;
                        if (hr==0 && device!=null) {
                            var details=Device(device);
                            row["device"]=details;
                            complete=complete && (bool)details["complete"];
                        } else complete=false;
                        endpoints.Add(row);
                    } finally { Release(device,cleanupErrors); }
                }
                result["diagnostics_complete"]=complete && defaults.Count==3 && endpoints.Count==count;
                return result;
            } catch (Exception ex) {
                result["exception_type"]=ex.GetType().FullName;
                result["exception_message"]=ex.Message;
                result["exception_hresult"]=Hr(ex.HResult);
                result["diagnostics_complete"]=false;
                return result;
            } finally {
                Release(collection,cleanupErrors);
                Release(enumerator,cleanupErrors);
                if (initialized) CoUninitialize();
                result["co_uninitialize_balanced"]=initialized;
                result["com_refs_release_attempted"]=true;
                result["finished_utc"]=DateTime.UtcNow.ToString("o");
                if (cleanupErrors.Count!=0) result["diagnostics_complete"]=false;
            }
        }
        public static Dictionary<string,object> Run(int timeoutMilliseconds) {
            Dictionary<string,object> observed=null;
            var worker=new Thread(delegate() { observed=Observe(); });
            worker.IsBackground=true;
            worker.SetApartmentState(ApartmentState.MTA);
            worker.Start();
            if (!worker.Join(timeoutMilliseconds)) {
                return new Dictionary<string,object>{{"diagnostics_complete",false},{"timed_out",true},{"timeout_milliseconds",timeoutMilliseconds},{"com_refs_release_confirmed",false},{"note","No success/availability claim; background worker reclaimed when standalone diagnostic process naturally exits."}};
            }
            observed["timed_out"]=false;
            observed["timeout_milliseconds"]=timeoutMilliseconds;
            return observed;
        }
    }
}
'@
$nativeResult=$null
$scriptError=$null
try {
    Add-Type -TypeDefinition $nativeSource -Language CSharp -ErrorAction Stop
    $nativeResult=[JointReadonlyEndpoints20261008.Reader]::Run($TimeoutSeconds*1000)
} catch { $scriptError=$_.Exception.ToString() }
$sourceAfter=@(Get-ReadonlyFileRecord $PSCommandPath; Get-ReadonlyFileRecord $projectPath)
$playersAfter=@(Get-ReadonlyPlayerSnapshot)
$sourcesUnchanged=($sourceBefore | ConvertTo-Json -Depth 8 -Compress) -ceq ($sourceAfter | ConvertTo-Json -Depth 8 -Compress)
$playersUnchanged=($playersBefore | ConvertTo-Json -Depth 8 -Compress) -ceq ($playersAfter | ConvertTo-Json -Depth 8 -Compress)
$complete=$null -eq $scriptError -and $null -ne $nativeResult -and $nativeResult['diagnostics_complete'] -eq $true -and $sourcesUnchanged -and $playersUnchanged
$record=[ordered]@{schema=1;scope='READONLY_NATIVE_RENDER_ENDPOINT_DIAGNOSTIC_NOT_AUDIO_OR_FIELD_OR_RELEASE_APPROVAL';started_utc=$startedUtc;finished_utc=[datetime]::UtcNow.ToString('o');process=$processEvidence;native=$nativeResult;script_error=$scriptError;diagnostics_complete=[bool]$complete;sources_before=$sourceBefore;sources_after=$sourceAfter;sources_unchanged=[bool]$sourcesUnchanged;player15_before=$playersBefore;player15_after=$playersAfter;player15_unchanged=[bool]$playersUnchanged;audio_endpoint_activated=$false;property_store_opened=$false;playback_executed=$false;system_or_session_configuration_changed=$false;endpoint_ids_are_opaque=$true;godot_process_hresult_claimed=$false;device_name_or_session_causality_claimed=$false;audio_available_approval=$false;formal_cutover=$false}
New-Item -ItemType Directory -Path $targetDirectory -ErrorAction Stop | Out-Null
$resultPath=Join-Path $targetDirectory 'result.json'
$encoded=$record | ConvertTo-Json -Depth 20
$stream=[IO.File]::Open($resultPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try {
    $bytes=[Text.UTF8Encoding]::new($false).GetBytes($encoded)
    $stream.Write($bytes,0,$bytes.Length)
    $stream.Flush($true)
} finally { $stream.Dispose() }
if ([IO.File]::ReadAllText($resultPath) -cne $encoded) { throw 'Unique evidence write/readback mismatch' }
Write-Output ('READONLY_ENDPOINT_DIAGNOSTIC complete={0} output={1}' -f $complete,$resultPath)
if (-not $complete) { exit 1 }
exit 0
