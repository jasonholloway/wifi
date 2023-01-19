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

				Other)
						set -x
						read -r bssid frq level flags ssid <<< $(pickWifi)
						info "Picked $ssid at $bssid"
						# wpa_cli remove_network 2
						# wpa_cli add_network 2
						wpa_cli set_network 2 ssid "\"$ssid\""
						wpa_cli set_network 2 bssid "$bssid"
						wpa_cli set_network 2 key_mgmt NONE
						wpa_cli enable_network 2
						wpa_cli select_network 2
						refreshIp
						;;
		esac
}

pickMode() {
		fzf <<EOF
Home
Phone
Other
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
		dhcpcd -n -4 -6

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

