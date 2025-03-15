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

let gobject_dir = $"ghostty-gobject-($version)"
let gobject_tarfile = $"ghostty-gobject-($version).tar"
let gobject_targzfile = $"ghostty-gobject-($version).tar.gz"
let gobject_tarzstdfile = $"ghostty-gobject-($version).tar.zst"

let tmpdir = mktemp --directory

nix build .#default

ln -s $"(readlink result)/ghostty-gobject-($zig_version)" $"($tmpdir)/($gobject_dir)"

tar --create --dereference --mode u=rwX,og=rX --owner root:0 --group root:0 --directory $tmpdir --file $"($tmpdir)/($gobject_tarfile)" $gobject_dir

open $"($tmpdir)/($gobject_tarfile)" | gzip -c | save --raw $"($tmpdir)/($gobject_targzfile)"
open $"($tmpdir)/($gobject_tarfile)" | zstd -c | save --raw $"($tmpdir)/($gobject_tarzstdfile)"

let gir_dir = $"ghostty-gir-($version)"
let gir_tarfile = $"ghostty-gir-($version).tar"
let gir_targzfile = $"ghostty-gir-($version).tar.gz"
let gir_tarzstdfile = $"ghostty-gir-($version).tar.zst"

mkdir $"($tmpdir)/($gir_dir)"

$gir_path | each {|dir| ls $dir | filter {|file| $file.name | path parse | $in.extension == "gir"} | each {|file| cp $file.name $"($tmpdir)/($gir_dir)"}} | ignore

tar --create --dereference --mode u=rwX,og=rX --owner root:0 --group root:0 --directory $tmpdir --file $"($tmpdir)/($gir_tarfile)" $gir_dir

open $"($tmpdir)/($gir_tarfile)" | gzip -c | save --raw $"($tmpdir)/($gir_targzfile)"
open $"($tmpdir)/($gir_tarfile)" | zstd -c | save --raw $"($tmpdir)/($gir_tarzstdfile)"

gh release create $version --latest --title $version --notes $version $"($tmpdir)/($gobject_targzfile)" $"($tmpdir)/($gobject_tarzstdfile)" $"($tmpdir)/($gir_targzfile)" $"($tmpdir)/($gir_tarzstdfile)"
