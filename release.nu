let zig_version = zig version

let ts = date now | format date "%Y-%m-%d"

let run_number = if not ($env | get -i GITHUB_RUN_NUMBER | is-empty) {
  $env.GITHUB_RUN_NUMBER | into int
} else {
  0
}

let run_attempt = if not ($env | get -i GITHUB_RUN_ATTEMPT | is-empty) {
  $env.GITHUB_RUN_ATTEMPT | into int
} else {
  0
}

let version = {zig_version: $zig_version, ts: $ts, run_number: $run_number, run_attempt: $run_attempt} | format pattern "{zig_version}-{ts}-{run_number}-{run_attempt}"

let directory = $"ghostty-gobject-($version)"
let tarfile = $"ghostty-gobject-($version).tar"
let targzfile = $"ghostty-gobject-($version).tar.gz"
let tarzstdfile = $"ghostty-gobject-($version).tar.zst"

let tmpdir = mktemp --directory

nix build .#default

ln -s $"(readlink result)/ghostty-gobject-($zig_version)" $"($tmpdir)/($directory)"

tar --create --dereference --directory $tmpdir --file $"($tmpdir)/($tarfile)" $directory

open $"($tmpdir)/($tarfile)" | gzip -c | save --raw $"($tmpdir)/($targzfile)"
open $"($tmpdir)/($tarfile)" | zstd -c | save --raw $"($tmpdir)/($tarzstdfile)"

gh release create $version --latest --title $version --notes $version $"($tmpdir)/($targzfile)" $"($tmpdir)/($tarzstdfile)"
