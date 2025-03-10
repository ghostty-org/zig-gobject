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

let version = {ts: $ts, run_number: $run_number, run_attempt: $run_attempt} | format pattern "{ts}-{run_number}-{run_attempt}"

let directory = $"ghostty-gobject-($version)"
let tarfile = $"ghostty-gobject-($version).tar.zstd"

let tmpdir = mktemp --directory

nix build .#default

ln -s $"(readlink result)/ghostty-gobject" $"($tmpdir)/($directory)"

tar --create --dereference --directory $tmpdir --file $"($tmpdir)/($tarfile)" $directory

gh release create $version --latest --title $version --notes $version $"($tmpdir)/($tarfile)"
