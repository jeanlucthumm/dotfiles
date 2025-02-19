let card = pactl -f json list cards | from json | where name == "alsa_card.pci-0000_00_1f.3" kj
