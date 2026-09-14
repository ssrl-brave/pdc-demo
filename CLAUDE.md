# PDC Demo Launcher

Desktop launcher for bwrap-sandboxed applications (MOE, PyMOL, xeyes, terminal)
on the PDC SLURM cluster via the `interactive` partition.

## Architecture

```
/home/sw/pdc-demo/          <- read-only source of truth (git repo)
  install.sh                <- copies runtime files to ~/pdc-demo/, installs .desktop icon
  PDC_launcher.desktop      <- template for desktop shortcut
  launcher/slurmlauncher    <- main launcher script (runs on pxslogin)
  templates/{moe,pyMOL}/    <- per-app template files copied into each sandbox workspace
  icon/pdc-icon.svg

~/pdc-demo/                 <- user's copy (created by install.sh, writable)
  (same as above minus install.sh, .desktop, .git, test scripts)

~/.pdc-demo-workspaces/     <- ephemeral per-launch sandbox workspaces
  <random-hex>/             <- created at launch, deleted on clean exit
    home/                   <- mounted as /workspace/home inside bwrap
    tmp/                    <- passwd/group files, mounted as /tmp
    launch_sandbox.sh       <- generated bwrap invocation
    app.log                 <- srun stdout/stderr (preserved on failure)
```

## User flow

1. Admin updates `/home/sw/pdc-demo/` (with sudo)
2. User runs `/home/sw/pdc-demo/install.sh` — local rsync to `~/pdc-demo/`, desktop icon installed
3. User clicks desktop icon → `ssh -t -Y pxslogin "cd ~/pdc-demo && ./launcher/slurmlauncher"`
4. Zenity app picker → Quick Launch / Configure → srun → bwrap sandbox → app

Re-running `install.sh` pushes template/launcher updates (`rsync --delete`).

## Cluster (interactive partition)

- pxproc[08-10,12]: 72 CPUs, 168G RAM
- bl121proc[01-04]: 48 CPUs, 217G RAM
- pxgpu02: 48 CPUs, 120G RAM, 1x V100 + 1x A100
- pxgpu04: 128 CPUs, 256G RAM, 4x L40
- pxgpu03: reserved for docking (NOT in interactive)

Default launch: 12 CPUs, 32G RAM. Configure mode allows node/CPU/memory selection.

## Key gotchas

- `module load moe` clobbers LD_LIBRARY_PATH, breaking zenity (GTK). The launcher
  saves/restores LD_LIBRARY_PATH around module load, only restoring MOE's version
  right before srun (after all zenity dialogs are done).
- `DBUS_SESSION_BUS_ADDRESS=/dev/null` is required on pxslogin or zenity hangs for 25s.
- `GDK_BACKEND=x11` is required for zenity over X11 forwarding.
- Templates extracted from zips (e.g. Checkpoints.zip) may have restricted permissions.
  Always `chmod -R a+r` after extracting into `/home/sw/pdc-demo/templates/`.
- Safe to update `/home/sw/pdc-demo/` while users are active — they run from
  their own `~/pdc-demo/` copy. Changes only take effect when a user re-runs install.sh.
- Workspaces in `~/.pdc-demo-workspaces/` are cleaned up on success; on failure they
  are preserved with `app.log` for debugging.

## Adding a new application

1. Add entry to `app_commands` associative array in `launcher/slurmlauncher`
2. Add it to the zenity radiolist
3. Optionally create `templates/<app-name>/` with starter files
4. If the app needs a module load, add it alongside the moe block (with the same
   LD_LIBRARY_PATH save/restore pattern)

## Testing

- `./launcher/slurmlauncher --dry-run` generates the bwrap script without launching
- `test_launcher.sh` tests each stage independently (SSH, SCP, zenity, SLURM)
