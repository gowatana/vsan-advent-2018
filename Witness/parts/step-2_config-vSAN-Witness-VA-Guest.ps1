# Setup Witness-VA Guest
function nested_esxcli {
    param(
        $ESXiVM, $ESXiUser, $ESXiPass, $ESXCLICmd
    )

    $vm = Get-VM $ESXiVM | select -First 1
    "ESXi VM Name:" + $vm.Name

    $vm_id = $vm.Id
    $vc_name = $vm.Uid  -replace "^.*@|:.*$",""
    $vc = $global:DefaultVIServers | where {$_.Name -eq $vc_name}

    # set Authentication info.
    $cred = New-Object VMware.Vim.NamePasswordAuthentication
    $cred.Username = $ESXiUser
    $cred.Password = $ESXiPass

    # set esxcli.
    $gps = New-Object VMware.Vim.GuestProgramSpec
    $gps.WorkingDirectory = "/tmp"
    $gps.ProgramPath = "/bin/esxcli"
    $gps.Arguments = $ESXCLICmd

    # Invoke Guest Command.
    $gom = Get-View $vc.ExtensionData.Content.GuestOperationsManager
    $pm = Get-View $gom.ProcessManager
    $gos_pid = $pm.StartProgramInGuest($vm_Id, $cred, $gps)
    $pm.ListProcessesInGuest($vm_Id, $cred, $gos_pid) | % {$_.CmdLine}
}

$vm_name = $vsan_witness_va_name
$nest_hv_hostname = $vsan_witness_host_name
$domain = $vsan_witness_host_domain
$hv_ip_vmk0 = $vsan_witness_host_ip
$hv_subnetmask = $vsan_witness_host_subnetmask
$hv_gw = $vsan_witness_host_gw
$dns_1 = $vsan_witness_dns_1
$dns_2 = $vsan_witness_dns_2

task_message "Witness-2_01" ("Configure Nested ESXi: " + $vm_name)
# esxcli ...
"system hostname set --host $nest_hv_hostname --domain $domain",
"network ip interface ipv4 set --interface-name=vmk0 --type=static --ipv4=$hv_ip_vmk0 --netmask=$hv_subnetmask --gateway=$hv_gw",
"network ip route ipv4 add --network=0.0.0.0/0 --gateway=$hv_gw",
"network ip dns server add --server=$dns_1",
"network ip dns server add --server=$dns_2" |
ForEach-Object {
    nested_esxcli -ESXiVM:$vm_name -ESXiUser:$hv_user -ESXiPass:$hv_pass -ESXCLICmd $_
    sleep 1
}

#task_message "Witness-2_02" ("Configure Nested ESXi vmk0: " + $vm_name)
#"vsan network ip add -i vmk0 -T=witness" |
#ForEach-Object {
#    nested_esxcli -ESXiVM:$vm_name -ESXiUser:$hv_user -ESXiPass:$hv_pass -ESXCLICmd $_
#    sleep 1
#}
