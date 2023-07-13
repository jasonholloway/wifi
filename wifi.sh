#!/bin/bash
set -e

iface=wlp0s20f3

main() {
		case "$(pickMode)" in
				Home)
						wpa_cli select_network 0
						wpa_cli reassociate
						refreshIp
						;;

				Phone)
						wpa_cli select_network 1
						wpa_cli reassociate
						refreshIp
						;;

				Office)
						wpa_cli select_network 2
						wpa_cli reassociate
						refreshIp
						;;

				Office2)
						wpa_cli select_network 5
						wpa_cli reassociate
						refreshIp
						;;

				Other)
						read -r bssid frq level flags ssid <<< $(pickWifi)
						info "Picked $ssid at $bssid"

						nid=4

						wpa_cli set_network $nid ssid "\"$ssid\""
						wpa_cli set_network $nid bssid "$bssid"

						if [[ $flags =~ PSK ]]; then
								echo "PSK?"
								wpa_cli set_network $nid key_mgmt "WPA-PSK WPA-EAP"
								wpa_cli set_network $nid psk "$(fzf --disabled --prompt="psk? ")"
						else
								wpa_cli set_network $nid key_mgmt NONE
						fi

						wpa_cli select_network $nid
						sleep 1
						# wpa_cli reassociate
						refreshIp
						;;

				Reassoc*)
						wpa_cli reassociate
						;;
		esac
}

pickMode() {
		fzf <<EOF
Home
Phone
Office
Office2
Other
Reassociate
EOF
}

pickWifi() {
		wpa_cli scan >/dev/null
		sleep 2
		wpa_cli scan_results |
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

