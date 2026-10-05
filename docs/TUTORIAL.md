# Complete Tutorial: SSH Into Your Muse VM Over Tailscale (Reverse SSH)

> 🇮🇩 Versi Bahasa Indonesia: [TUTORIAL.id.md](TUTORIAL.id.md)

This tutorial is written for **complete beginners**. We install
everything slowly, one bolt at a time. By the end you can enter your
Muse VM with SSH — privately over Tailscale, with a key (no password),
and with no 60-minute limit.

No Muse account yet? Start with the
**[Muse claim guide](CLAIM-MUSE.md)** — VPN and no-VPN routes are
included, plus referral code **`IB4FJR`** (redeem within 48 hours and we
both receive 1 billion tokens).

---

## Part 0 — What are we building?

The problem, in plain words:

- The VM your Muse lives in has a phone that **can only call out; it
  cannot be called**. It has no public address, and the Tailscale inside
  it is a *client* only (it visits other machines; nobody can visit it).
- So to let you in, the direction is reversed: **the VM calls your
  laptop** over Tailscale, and that call is kept open and used to
  **park one port** on your laptop (standard number `2223`).
- You then SSH into **your own laptop** at that parked port — the
  connection is forwarded through the open call, and you land inside
  the Muse VM anyway.

The picture:

```
You (CMD on the laptop)
   |
   |  ssh -i muse-key -p 2223 root@127.0.0.1
   v
Parked port 2223 on your laptop
   |
   |  (the channel the VM opened, over Tailscale)
   v
sshd on the Muse VM (localhost port 2222, key-only)
```

Two sides get installed:

- **The laptop side (Windows)** — Part 1. Done once, permanent.
- **The Muse VM side** — Part 2. Done from the Muse chat / VM terminal.

Words used in this tutorial are explained in the
[main README](../README.md), section 4 (Small glossary).

---

## Part 1 — The Windows laptop side

### 1.1 Install Tailscale and note your laptop's IP

1. Install the **Tailscale** app on the laptop from tailscale.com and
   sign in with your account.
2. Open Command Prompt (normal CMD, not admin) and run:

```
"C:\Program Files\Tailscale\tailscale.exe" ip -4
```

3. One `100.x.x.x` address comes out — that is **your laptop's tailnet
   IP**. Write it down; the VM side needs it. In this tutorial it is
   called `YOUR_LAPTOP_TAILNET_IP`.

### 1.2 Check the Windows SSH server: running or not

Still in CMD, run:

```
sc query sshd
```

- If it shows `STATE : 4 RUNNING` — good, continue to 1.3.
- If it errors / shows `FAILED 1060` — the SSH server is not installed.
  Install it from PowerShell as Administrator:

```
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service sshd -StartupType Automatic
```

Then check again with `sc query sshd` until it says `RUNNING`.

### 1.3 Create your own key for entering the VM

You need one key pair: the private half stays on the laptop, the public
half will be pasted onto the VM.

In normal CMD (sitting in your home folder, `C:\Users\<you>>`):

```
ssh-keygen -t ed25519 -f muse-key
```

Press Enter through the prompts (the passphrase may be left empty). Two
files appear:

| File | What it is |
|---|---|
| `muse-key` | Your **private** key. Secret — never share it, never delete it |
| `muse-key.pub` | Your **public** key. This is the one that may be shared |

Print it and send it to Muse (in chat) or paste it onto the VM
yourself in Part 2.2:

```
type muse-key.pub
```

The output is one line starting with `ssh-ed25519 AAAA...` — send that
line, **not** the file without `.pub`.

> **From the author's real experience:** the stock Windows `.ssh`
> folder is sometimes locked in a strange way — reading a `.pub` file
> inside it can fail with `Access is denied`, even as Administrator.
> That is why this tutorial deliberately creates a dedicated `muse-key`
> in your home folder (outside `.ssh`). Don't fight that folder; just
> use the dedicated key.

### 1.4 Open the firewall for SSH from Tailscale only

Now open **Command Prompt as Administrator** (right-click → Run as
administrator). Run:

```
netsh advfirewall firewall add rule name="SSH Tailscale" dir=in action=allow protocol=TCP localport=22 remoteip=100.64.0.0/10
```

- Success looks like: `Ok.`
- `remoteip=100.64.0.0/10` means: only the **Tailscale network range**
  may come in — not the whole internet. Do not widen it to all
  addresses.
- If it says "already exists", this step was already done. Move on.

### 1.5 Install the VM's public key on your laptop

Why is this needed? Later, the VM is the one calling your laptop. The
laptop must recognize the caller — so the **VM's public key** is pasted
onto the laptop. (A public key is made to be shared; the VM's private
key never leaves the VM.)

Easy road: use this repo's script, `scripts\windows-setup.ps1`, in
PowerShell as Administrator. It checks admin rights, checks sshd, asks
you to paste the VM's public key, then performs steps 1.4 and 1.5 for
you.

Manual road, in the same admin CMD:

```
echo ssh-ed25519 AAAA...YOUR_VM_PUBLIC_KEY... your-vm>> C:\ProgramData\ssh\administrators_authorized_keys
```

Replace `AAAA...YOUR_VM_PUBLIC_KEY...` with the VM's real public key
(one full line, don't let it wrap). Then lock the file's permissions —
a hard requirement of the Windows SSH server:

```
icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
```

Success looks like: `Successfully processed 1 files; Failed processing 0 files`

> **Non-admin account note:** if your Windows account is **not** a
> member of the Administrators group, Windows sshd reads a different
> file: `C:\Users\<you>\.ssh\authorized_keys`. Paste the VM key there
> instead, and skip the ProgramData icacls step above.

### 1.6 Make sure "Allow incoming connections" is on (Shields Up off)

1. Right-click the **Tailscale** icon at the bottom right, near the
   clock.
2. Open **Preferences**.
3. Make sure **Allow incoming connections** is ticked.

That is the same switch as "Shields Up": if incoming connections are
**not** allowed, every incoming call — including the VM's — is silently
refused, which is exactly the symptom the author hit before this step
was fixed.

**The laptop side is done.** Installed once, permanent. Nothing on the
laptop needs to change again after this.

---

## Part 2 — The Muse VM side

This part runs inside the VM (through your Muse chat — ask the agent
to run it — or from the VM terminal if you already have another way in).

### 2.1 Prepare the project folder

```
mkdir -p $HOME/muse-vps-tailscale
cp -r scripts $HOME/muse-vps-tailscale/
cd $HOME/muse-vps-tailscale
chmod +x scripts/*.sh scripts/*.py
```

For the rest of the tutorial this is the **project folder**. Every
important file (host key, authorized_keys, scripts) lives here, inside
the persistent `$HOME` — not in `/etc`, which easily vanishes when a
sandbox machine is reset.

### 2.2 Paste your public key onto the VM

The public key from step 1.3 becomes a line in the `authorized_keys`
file in the project folder — one line, one key:

```
echo "ssh-ed25519 AAAA...YOUR_PUBLIC_KEY... your-name" >> authorized_keys
chmod 600 authorized_keys
```

### 2.3 Start the dedicated sshd (key-only, port 2222)

```
bash scripts/setup-sshd.sh
```

That script installs openssh-server if needed, creates the host key,
writes `sshd_config` from `scripts/sshd_config.example`, and starts
sshd with these rules:

- listens **only** on `127.0.0.1` port `2222`;
- **passwords fully disabled** (`PasswordAuthentication no`);
- only keys listed in `authorized_keys` may enter.

Test it locally first with a throwaway key or your key from another
machine — this command must succeed before you continue:

```
ssh -p 2222 root@127.0.0.1 "echo hello-from-inside"
```

### 2.4 Join the VM to your tailnet

Use the VM runtime's built-in Tailscale connector:

```
tailscale up
```

The command prints one link. The account owner (you) opens that link
and approves the device (device name `muse`). After approval, check:

```
tailscale status
```

The target: status **Connected**, the VM has its own `100.x.x.x` IP
(called `YOUR_VM_TAILNET_IP`), and your laptop appears in the peer list
with the IP you noted in 1.1.

> **IMPORTANT TRICK — if `tailscale up` gets stuck:** sometimes `up`
> only answers *"Could not finish connecting to Tailscale. Retrying."*
> over and over and **the link never appears**, because a stale old
> identity is wedged in. The fix proven on the author's setup:
>
> ```
> tailscale down
> tailscale up
> ```
>
> `down` throws the stale identity away ("Signed out. Connecting again
> needs a fresh approval."), and the `up` right after it prints the
> link **immediately**, in under a minute.

> **NOTE about the proxy:** on the author's sandbox, the machine cannot
> reach the tailnet directly — TCP traffic to the tailnet rides the
> runtime's egress proxy, port `3130`, using the little helper
> `scripts/tsconnect.py` as ssh's ProxyCommand. Adjust that proxy
> address to your own runtime with the `TSCONNECT_PROXY_HOST` /
> `TSCONNECT_PROXY_PORT` / `TSCONNECT_PROXY_URL` variables. If your VM
> has native Tailscale routing, you don't need this part at all.

### 2.5 Test the road VM → laptop (banner check)

Before opening the tunnel, prove the call can get through. From the VM:

```
ssh -o "ProxyCommand=python3 scripts/tsconnect.py %h %p" \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  YOUR_WINDOWS_USERNAME@YOUR_LAPTOP_TAILNET_IP "echo made-it-to-laptop"
```

- If `made-it-to-laptop` comes back — the VM → laptop road is
  **healthy**. Continue.
- If the connection returns empty / times out silently — the laptop is
  still refusing. Go back to 1.4 (firewall) and 1.6 (Allow incoming
  connections). On the author's setup those two were exactly the
  culprits; once fixed, the laptop's SSH banner
  (`SSH-2.0-OpenSSH_for_Windows_...`) answered right away.

### 2.6 Start the reverse tunnel (guarded by the supervisor)

```
LAPTOP_TS_IP=YOUR_LAPTOP_TAILNET_IP WIN_USER=YOUR_WINDOWS_USERNAME \
  bash scripts/reverse-start.sh
```

What happens: a **supervisor** (watchdog) process starts in the
background. It opens ssh from the VM to your laptop, parking port
`127.0.0.1:2223` on the laptop, forwarded to the VM sshd on port
`2222`. If that ssh ever drops, the supervisor starts it again every
10 seconds.

Check from the laptop (normal CMD):

```
netstat -an | findstr 2223
```

The target is a line like: `TCP 127.0.0.1:2223 ... LISTENING`.

The tunnel log lives in `reverse.log` in the VM project folder.

### 2.7 The full loop test (the strongest proof)

Still inside the ssh session from 2.5 (you are "inside" the laptop,
from the VM), run the final connect command from Part 3 there. If the
Muse VM's own hostname answers — the complete chain is proven:
VM → laptop → parked port → back into the VM.

---

## Part 3 — How you connect, day to day

From **normal CMD** on the laptop, sitting in your home folder:

```
ssh -i muse-key -p 2223 root@127.0.0.1
```

The pieces, in plain words:

- `-i muse-key` = "enter with this key" (the key from 1.3)
- `-p 2223` = through the parked port on your own laptop
- `root@127.0.0.1` = the destination *looks like* your own laptop, but
  that port contains the VM — you are forwarded inside

The first time, it asks `Are you sure you want to continue
connecting?` — type `yes`, Enter. After that, **no password** is ever
asked.

Signs of success: your prompt becomes the Muse VM's prompt (for
example `root@<your-vm-hostname>`). Try:

```
whoami
hostname
ls
```

Leave with `exit`. This session has **no 60-minute limit** — as long
as your laptop is online and the VM's tunnel is up, that parked port
stays there.

To stop the tunnel (from the VM side): `bash scripts/reverse-stop.sh`.

---

## Part 4 — After the VM machine gets reset (it heals itself)

Muse sandboxes can be reset at any time. What happens:

| Thing | Its fate |
|---|---|
| The laptop side (firewall, VM key, Tailscale app) | **Permanently fine**, never needs redoing |
| The VM's Tailscale connection | On the author's runtime it sticks across resets, with the same IP |
| Files in the project folder (`$HOME`) | **Safe** — host key and authorized_keys survive |
| The running sshd + supervisor | They stop — **and the auto-recovery guard starts them again by itself** (below) |

So after a reset, your homework is zero: **wait about one minute,
then connect as usual.** Only if that still fails do you need the
manual fallback at the end of this part.

### 4.1 Auto-recovery: the `ensure-up.sh` guard

This project ships a small guard script, `scripts/ensure-up.sh`.
Every time it runs, it checks four things **in order** and repairs
whatever is broken:

1. **Is Tailscale Connected?** If not, it stops and reports
   `TAILSCALE_DOWN`. No script can fix this one — approving a device
   is a human's job. This is the one honest limit of the whole system.
2. **Does the sshd binary still exist?** A reset can wipe system
   packages. If it is gone, the guard reinstalls `openssh-server`.
3. **Is the local sshd listening** on port `2222`? If not, the guard
   starts it, using the project folder's own config.
4. **Is the supervisor alive?** If not, the guard starts it — and
   the parked port `2223` reappears on your laptop.

If everything is already healthy, the guard does **nothing** and
prints `HEALTHY`. That makes it safe to call over and over again
(idempotent) — from a scheduler, or by hand.

### 4.2 Who calls the guard? A scheduler that survives resets

On the author's setup, the caller is a **runtime hook**
(`scripts/ensure-hook.sh`, registered with
`scripts/ssh-tunnel-ensure.hook.json.example`) that polls every
**30 seconds**. Two design choices are the whole trick:

- **The hook lives in `$HOME`, not in systemd.** A VM reset wipes
  everything outside `$HOME` — systemd units in `/etc` included. A
  scheduler stored inside `$HOME` survives every reset, which is
  exactly when it is needed most.
- **The repair itself is pure bash and costs zero AI tokens.** The
  hook only *wakes the agent* in three situations, at most once per
  incident: right after an auto-repair (so the agent can verify and
  tell you the door is back), when Tailscale has been down for
  5+ minutes (you need to approve again), or when a repair failed.

Proof from the author's machine (2026-10-05): sshd and the supervisor
were **killed on purpose** to simulate a reset — within **75
seconds** everything was back by itself, and the laptop port was
listening again. (That same morning, before this guard existed, a
real 06:24 reset had greeted the author with `Connection refused` —
this guard is the answer to that morning.)

One requirement: the scheduler's environment must contain the same
two variables `reverse-start.sh` needs (`LAPTOP_TS_IP`, `WIN_USER`) —
export them wherever your scheduler keeps its environment.

### 4.3 The flock gotcha (a real bug, so you don't repeat it)

`ensure-up.sh` takes a `flock` lock so two guard runs can never
collide. The first version had a nasty bug: the daemons the guard
started (sshd, the supervisor) **inherited the lock's file
descriptor** — so the lock stayed locked *forever*, held by a daemon
that never exits, and every later guard run politely reported
`LOCKED` and repaired nothing at all. The cure is one tiny
redirection: start every daemon with the lock fd closed — `9>&-`.
If you adapt this script, do not delete those four characters.

### 4.4 The manual fallback (always there)

If auto-recovery is not installed, or things are still broken after
a minute, run the guard once by hand:

```
bash scripts/ensure-up.sh        # one shot: checks + fixes everything
```

—or just ask your agent ("turn the Tailscale SSH back on"). The old
fully-manual road — step 2.3, then step 2.6 — still works exactly as
before.

### 4.5 On a plain Linux machine (no fancy runtime)

You do not need the author's runtime hook. Anything that calls
`ensure-up.sh` regularly does the job:

- **cron** — one line (edit with `crontab -e`), checks every minute:

  ```
  * * * * * LAPTOP_TS_IP=YOUR_LAPTOP_TAILNET_IP WIN_USER=YOUR_WINDOWS_USERNAME /path/to/project/scripts/ensure-up.sh >> /path/to/project/ensure.log 2>&1
  ```

- or a **systemd service + timer** running the same script. On a
  normal VPS that is never wiped, systemd is perfectly fine — the
  `$HOME`-hook choice above only matters on reset-happy sandboxes
  like the author's.

---

## Part 5 — When things break (symptom → cause → fix)

| Symptom | Most likely cause | The fix |
|---|---|---|
| `Connection refused` when connecting to 2223 | The VM's tunnel or sshd is down (very often: the VM was just reset) | Wait about a minute — the auto-recovery guard (Part 4) restarts everything by itself. Still refused? Run `bash scripts/ensure-up.sh` on the VM, then check on the laptop whether 2223 is LISTENING |
| `Permission denied (publickey)` | The wrong key is offered, or your public key is not in the VM's `authorized_keys` | Make sure the command uses `-i muse-key`, that CMD sits in the folder containing the `muse-key` file, and that its `.pub` line was pasted onto the VM (2.2) |
| The VM calling the laptop always fails / empty banner | The laptop is refusing: firewall not open yet, or Allow incoming connections off | Redo 1.4 and 1.6 exactly; those two were the cause on the author's setup |
| Reading a `.pub` inside the Windows `.ssh` folder gives `Access is denied` | The stock Windows `.ssh` folder is locked in a strange way (the author's real experience, even as admin) | Don't fight it. Use a dedicated key in your home folder, like step 1.3 |
| `tailscale up` only says "Retrying", no link ever appears | A stale Tailscale identity is wedged on the VM | `tailscale down` first, then `tailscale up` again (see the trick box in 2.4) |
| Testing back from inside the author's sandbox looks flaky | The test path loops through the sandbox's egress proxy, which is genuinely flaky on the author's setup | Judge by **your direct connection**: on the author's setup, the first real try connected immediately. Don't rate it by the sandbox's return test alone |
| Port 2223 is already in use on the laptop | Another program, or an old tunnel that never died | Stop the old tunnel from the VM (`reverse-stop.sh`), or change `REMOTE_PORT` in the supervisor script and adjust your connect command |
| It keeps asking for a password | You connected to the wrong port (e.g. the laptop's own 22), or the VM sshd runs a different config | Make sure the port is `2223` and the VM sshd was started by `setup-sshd.sh` (passwords are disabled in that config) |

---

## Closing

If every step above is green, you own a private door into your Muse
VM: no public address, no company relay, no 60-minute countdown. The
only guards are two keys that know each other — and you hold both
strings (delete one key line and the access dies that same second).

Back to the [main README](../README.md).
