Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
carapace _carapace | Out-String | Invoke-Expression


if (test-path '~/Scripts/lib.ps/Profile/profile.ps1') {
    . ~/Scripts/lib.ps/Profile/profile.ps1
}
$brewPrefix = '/opt/homebrew/bin', '/opt/homebrew/bins'
$brewPrefix | foreach-object { 
  if ((epath).Path -notcontains $_) {
    Add-ToPath $_
  }
}
new-alias -Name nano -Value /opt/homebrew/Cellar/nano/9.0/bin/nano
oh-my-posh init pwsh --config ~/.config/ohmyposh/my_brshprompt.omp.yaml | invoke-expression
Invoke-Expression (& { (zoxide init powershell | Out-String) })
