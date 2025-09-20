let ts = date now | format date "%Y-%m-%d"

let run_number = $env.GITHUB_RUN_NUMBER? | default 0 | into int
let run_attempt = $env.GITHUB_RUN_ATTEMPT? | default 0 | into int

let version = {ts: $ts, run_number: $run_number, run_attempt: $run_attempt} | format pattern "{ts}-{run_number}-{run_attempt}"

let gobject_dir = $"ghostty-gobject-($version)"
let gobject_tarfile = $"ghostty-gobject-($version).tar"
let gobject_targzfile = $"ghostty-gobject-($version).tar.gz"
let gobject_tarzstdfile = $"ghostty-gobject-($version).tar.zst"

let tmpdir = mktemp --directory

let result = nix build --print-out-paths --no-link .#default

ln -s $"($result)" $"($tmpdir)/($gobject_dir)"

tar --create --dereference --mtime 1970-01-01T00:00:00+00:00 --mode u=rwX,og=rX --owner root:0 --group root:0 --directory $tmpdir --file $"($tmpdir)/($gobject_tarfile)" $gobject_dir

open $"($tmpdir)/($gobject_tarfile)" | gzip -c | save --raw $"($tmpdir)/($gobject_targzfile)"
open $"($tmpdir)/($gobject_tarfile)" | zstd -c | save --raw $"($tmpdir)/($gobject_tarzstdfile)"

let gir_dir = $"ghostty-gir-($version)"
let gir_tarfile = $"ghostty-gir-($version).tar"
let gir_targzfile = $"ghostty-gir-($version).tar.gz"
let gir_tarzstdfile = $"ghostty-gir-($version).tar.zst"

mkdir $"($tmpdir)/($gir_dir)"

$gir_path | each {|dir| ls $dir | where {|file| $file.name | path parse | $in.extension == "gir"} | each {|file| cp -n $file.name $"($tmpdir)/($gir_dir)"}} | ignore

tar --create --dereference --mode u=rwX,og=rX --owner root:0 --group root:0 --directory $tmpdir --file $"($tmpdir)/($gir_tarfile)" $gir_dir

open $"($tmpdir)/($gir_tarfile)" | gzip -c | save --raw $"($tmpdir)/($gir_targzfile)"
open $"($tmpdir)/($gir_tarfile)" | zstd -c | save --raw $"($tmpdir)/($gir_tarzstdfile)"

$env.MINISIGN_KEY | save --raw $"($tmpdir)/minisign.key"

$env.MINISIGN_PASSWORD | minisign -S -m $"($tmpdir)/($gobject_targzfile)" -s $"($tmpdir)/minisign.key"
$env.MINISIGN_PASSWORD | minisign -S -m $"($tmpdir)/($gobject_tarzstdfile)" -s $"($tmpdir)/minisign.key"
$env.MINISIGN_PASSWORD | minisign -S -m $"($tmpdir)/($gir_targzfile)" -s $"($tmpdir)/minisign.key"
$env.MINISIGN_PASSWORD | minisign -S -m $"($tmpdir)/($gir_tarzstdfile)" -s $"($tmpdir)/minisign.key"

(
  gh release create $version
    --latest
    --title $version
    --notes $version
    $"($tmpdir)/($gobject_targzfile)"
    $"($tmpdir)/($gobject_targzfile).minisign"
    $"($tmpdir)/($gobject_tarzstdfile)"
    $"($tmpdir)/($gobject_tarzstdfile).minisign"
    $"($tmpdir)/($gir_targzfile)"
    $"($tmpdir)/($gir_targzfile).minisign"
    $"($tmpdir)/($gir_tarzstdfile)"
    $"($tmpdir)/($gir_tarzstdfile).minisign"
)
