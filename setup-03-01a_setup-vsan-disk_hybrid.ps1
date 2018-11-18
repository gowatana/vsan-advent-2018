# Load Config file.
$config_file_name = $args[0]
. $config_file_name
if($? -eq $false){"config file not found."; exit}

$cluster = Get-Cluster -Name $cluster_name

function set_satp_rule {
    param (
        $esxi,
        $dev_list,
        $satp_rule_name = "VMW_SATP_LOCAL",
        $satp_rule_option = "disable_ssd"
    )

    $esxcli = $esxi | Get-EsxCli -V2
    $dev_list | % {
        $dev_name = $_
        "ESXi SATP Setting: " + `
            $hv.Name + " " + $satp_rule_name + " " + $satp_rule_option
        $config = $esxcli.storage.nmp.satp.rule.add.CreateArgs()
    
        $config.satp = $satp_rule_name
        $config.device = $dev_name
        $config.option = $satp_rule_option
        $esxcli.storage.nmp.satp.rule.add.Invoke($config)
        
        $config = $esxcli.storage.core.claiming.reclaim.CreateArgs()
        $config.device = $dev_name
        $esxcli.storage.core.claiming.reclaim.Invoke($config)
    }
}

# Add SSD Mark
$cluster | Get-VMHost | Sort-Object Name | % {
    $hv = $_
    set_satp_rule -esxi $hv -dev_list $vsan_cache_dev -satp_rule_option "enable_ssd"
}

# Add HDD Mark
$cluster | Get-VMHost | Sort-Object Name | % {
    $hv = $_
    set_satp_rule -esxi $hv -dev_list $vsan_capacity_dev -satp_rule_option "disable_ssd"
}