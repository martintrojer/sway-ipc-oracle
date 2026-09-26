# Reproducing the results

Build the pinned toolchain and run every result generator from a clean checkout:

```sh
git clone https://github.com/martintrojer/sway-ipc-oracle.git
cd sway-ipc-oracle
podman build -t sway-ipc-oracle -f Containerfile .
podman run --rm --memory 4g --memory-swap 4g \
  --security-opt label=disable -v "$PWD:/oracle" sway-ipc-oracle \
  ./contrib/validate reproduce i3 --snapshot i3-suite
```

The image builds the pinned i3, sway, wlroots, and swayward commits and installs
the Perl, X11, Wayland, and client dependencies. It does not use files from the
host home directory. Reproduction has six independent units: the i3-suite and
sway-ipc snapshots for each of i3, sway, and swayward. A unit is done when two
consecutive runs agree apart from assertions declared in `i3/flaky-runs.toml`,
no canary is flaky, and the regenerated result matches the committed result
apart from metadata. A completed unit does not need to be rerun when another
unit flakes.

Run a sway or swayward i3-suite unit as shards in parallel. Each command needs
its own 4 GiB, zero-swap container. Shards select files deterministically and
write partial TOML plus private diagnostics; `i3-suite-run --merge` is the only
step that writes the combined result:

```sh
mkdir -p target/reproduce/sway
for k in 1 2 3 4; do
  podman run --rm --memory 4g --memory-swap 4g \
    --security-opt label=disable -v "$PWD:/oracle" sway-ipc-oracle \
    ./contrib/validate reproduce sway --snapshot i3-suite --shard "$k/4" \
      --out "target/reproduce/sway/$k.toml" &
done
wait
./contrib/i3-suite-run --merge target/reproduce/sway/{1,2,3,4}.toml \
  --out i3/results/sway-1.12.toml
```

Use six shards on a 16-core machine after confirming memory headroom. Keep file
execution serial inside each sway or swayward shard. `--files FILE` (repeatable)
selects specific files for investigation. The outer Podman command supplies the
4 GiB memory limit and disables swap by setting the memory-plus-swap limit to
the same value.

Record one evidence line per unit with the oracle commit, image digest, wall
time, and non-metadata diff line count. Poll long runs every five minutes.
Result metadata contains the run date and oracle commit; compare content while
excluding those two keys:

```sh
git diff --ignore-matching-lines='^\(date\|oracle_commit\) = ' -- \
  i3/results sway-ipc/results
```

An empty diff means the measured content matches the committed results.
