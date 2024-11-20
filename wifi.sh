#!/bin/bash
set -e

iface=wlp0s20f3

main() {
		case "$(pickMode $1)" in
				Home)
						wpa_cli select_network 0
						wpa_cli reassociate
						refreshIp
						;;

				111Piccadilly)
						wpa_cli select_network 2
						wpa_cli reassociate
						refreshIp
						;;

				Other)
						read -r bssid frq level flags ssid <<< $(pickWifi)
						info "Picked $ssid at $bssid"
						info "Flags: $flags"

						nid=4

						wpa_cli set_network $nid ssid "\"$ssid\""
						wpa_cli set_network $nid bssid "$bssid"

						if [[ $flags =~ PSK ]]; then
								psk=$(getPass $ssid)
								
								wpa_cli set_network $nid key_mgmt "WPA-PSK WPA-EAP"
								wpa_cli set_network $nid psk '"'$psk'"'
						else
								wpa_cli set_network $nid key_mgmt NONE
						fi

						wpa_cli select_network $nid
						sleep 1
						refreshIp
						;;

				Reassoc*)
						wpa_cli reassociate
						;;
		esac
}

getPass() {
		local ssid=$1
		local pskFile=~/share/wifi/psks

		[[ -e $pskFile ]] && {
				found=$(awk -F, '$1 == "'$ssid'" { print $2 }' $pskFile)

				[[ ! -z $found ]] && {
						echo $found
						return
				}
		}

		echo "PSK?" >$(tty)
		read psk <$(tty)
		echo psk

		echo "${ssid},${psk}" >> $pskFile
}

pickMode() {
		fzf $([[ ! -z $1 ]] && echo "-q$1") -1 <<EOF
Home
Other
Reassociate
EOF
}

pickWifi() {
		wpa_cli scan >/dev/null
		sleep 2
		wpa_cli all_bss |
				tail -n+3 |
				sort -k3 |
				fzf
}

refreshIp() {
		sleep 1
		dhcpcd -n -4 -6 $iface

		while sleep 1; do
				info "Waiting for IP..."
				
				foundIp=$(
						ip addr show dev $iface |
						tee /dev/stderr |
						awk '$1 == "inet" {print $2}')

				if [[ ! -z $foundIp ]]; then
						info "Found IP $foundIp"
						break;
				fi
		done
}

info() {
		echo $@ >&2
}

error() {
		echo $@ >&2
		exit 1
}

main "$@"

