$subscriptions = az account list --query '[].[id]' -o tsv

foreach($subscription in $subscriptions) {

az account set --subscription $subscription

$zones = az network dns zone list --query "[].{resource:resourceGroup, name:name}" -o tsv

foreach($zone in $zones) {

echo $zone

}
}
