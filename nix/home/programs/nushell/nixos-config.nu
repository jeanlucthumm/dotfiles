let __bwSessionFile = "/tmp/bw-session-id"

# Stores the session key in the kernel's "session" keyring
def bw-unlock []: [nothing -> nothing] {
	bw unlock --raw | keyctl padd user bw_session @s | save -f --raw $__bwSessionFile
}

def bw-session []: [nothing -> string] {
  if (not ($__bwSessionFile | path exists)) {
		error make -u {
			msg: "No session id file"
			help: "Run bw-unlock"
		}
	}

	keyctl pipe (cat $__bwSessionFile)
}

# List bw items based on search string
def bw-list [
	query: string,  # Search string
] {
	with-env { BW_SESSION: (bw-session) } {
    bw list items --search $query | from json | select name login
  }
}
