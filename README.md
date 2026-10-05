# muse-vps-tailscale

![muse-vps-tailscale banner](docs/images/banner.svg)

![License: MIT](https://img.shields.io/badge/license-MIT-green)
![SSH](https://img.shields.io/badge/SSH-key__only-blue)
![Tailscale](https://img.shields.io/badge/Tailscale-reverse__SSH-purple)
![Session](https://img.shields.io/badge/session-no__time__limit-brightgreen)
![Tutorials](https://img.shields.io/badge/tutorials-EN_%2B_ID-orange)

> 🇮🇩 Versi Bahasa Indonesia: [README.id.md](README.id.md)

**SSH into your own Muse VM — privately over Tailscale, key-only with
no password, and no 60-minute limit. The door is parked on your own
laptop.**

---

<div align="center">

## 🎁 DON'T HAVE MUSE YET? CLAIM A 1 BILLION TOKEN BONUS

### Referral code: `IB4FJR`

Redeem this code in Muse Settings **within 48 hours after joining** and
we both receive **1 billion Muse tokens**.

**👉 [Read the Muse claim guide — with a VPN & without one](docs/CLAIM-MUSE.md)**

</div>

---

This document is written for **complete beginners**. It is fine if this
is your first time seeing these words — everything is explained slowly,
from zero. Read top to bottom; don't skip around on your first pass.

---

## 1. The 30-second explanation (plain words)

Imagine your Muse VM is a **house with a half-broken phone**:

- The phone in that house **can only call out; it cannot be called**.
  It has no public number, and nobody can come visiting.
- But you — its owner — want to **actually walk into that house**, not
  just talk to its resident through the window (chat).

This project works around it like this:

1. The house **calls your laptop** over the private Tailscale network,
   and the call is **kept open**.
2. Through that open call, the house **parks one small door on your
   laptop** — its number is `2223`.
3. You simply walk in **through the parked door on your own laptop**.
   It looks like you are entering your own laptop, but you are
   forwarded through that open call and land **inside the Muse VM**.

That parked door is called **reverse SSH**. Only one key — yours — can
open it. There is no public address, no company in the middle, and
**no 60-minute countdown**.

## 2. Why would anyone want this?

- You want to **hold the terminal of your own Muse VM** — learn
  Linux, check files, run commands — not just chat with its agent
- You tried the free public-tunnel road (the author used Pinggy) and
  got tired of the **60-minute limit + an address that changes every
  time**
- You want the road to be **private**: only devices on your own
  Tailscale network can take part, not the whole internet
- You want login with **no password at all** — replaced by a key,
  which is far stronger and cannot be guessed
- You want the door to **heal itself after a VM reset** — an
  auto-recovery guard restarts the VM side within about a minute,
  all by itself, without you asking anyone (tutorial Part 4)

## 3. Who this is for — and who it is not for

**This fits you if:**

- You have a **Muse** account (its agent lives in the VM you want to
  enter). Don't have one yet? There is a
  [claim guide](docs/CLAIM-MUSE.md)
- You have a **Windows laptop** that can stay on while you want your
  SSH session alive, and you hold its Administrator access
- You can copy-paste commands and read slowly

**Don't use this if:**

- You need to enter the VM **while your laptop is off**. This road's
  meeting point is your laptop — laptop off, door gone. (For that, a
  public tunnel like Pinggy fits better; see section 8)
- You don't want to install anything on your laptop. The laptop side
  has a one-time setup (firewall + one key) that cannot be skipped —
  but it is permanent afterwards
- Your VM turns out to be **directly reachable** over Tailscale
  (native Tailscale routing). Lucky you — just SSH straight to the
  VM's tailnet IP; you don't need this reverse detour at all

## 4. Small glossary (words you will keep meeting)

Read this first so the rest doesn't confuse you:

| Word | What it means, in human words |
|---|---|
| **VM** | A virtual computer — the "house" your Muse lives in |
| **SSH** | A safe way to enter another computer from far away, with a terminal |
| **sshd** | The SSH doorkeeper program on a machine. What you enter is sshd; what calls out is the ssh client |
| **Key pair** | Two matching files: the **private key** (the key itself, secret, you hold it) and the **public key** (the lock, safe to share, installed on the target machine) |
| **Tailscale** | A program that builds a private network between your devices, even though they are scattered across the internet |
| **Tailnet** | The name of your private Tailscale network. Only devices you approve can join |
| **Tailnet IP** | The `100.x.x.x` address of each device inside the tailnet |
| **Reverse SSH** | SSH with its direction flipped: the machine you want to enter calls out to yours, parking a port on the way |
| **Parked port** | The port number on your laptop (standard: `2223`) whose contents are forwarded to the VM |
| **Supervisor / watchdog** | A tiny script that guards the tunnel: if it drops, it starts it again every 10 seconds |
| **Firewall** | Windows' network guard. He decides which incoming connections may pass |
| **Shields Up** | Tailscale's paranoid mode: all incoming connections blocked. Must be off for this project |
| **Pinggy** | A public tunnel service (what the author used before): the VM calls that company's server, you get a temporary public address |
| **Token** | The unit of AI "thinking fuel". In this repo it only shows up in the referral bonus block |

## 5. What you must have first (check one by one)

Do not start installing before all of these are ticked:

- [ ] **One active Muse account** — its VM is the one you want to
  enter. Don't have one? Follow the
  [Muse claim guide](docs/CLAIM-MUSE.md) — VPN and no-VPN routes are
  included — and redeem referral code **`IB4FJR`** within 48 hours for
  the 1 billion token bonus
- [ ] **One Windows laptop** with **Administrator** access, which you
  can leave on for the length of your SSH session
- [ ] **Tailscale installed on the laptop**, signed in with your
  account (the free Tailscale tier is enough)
- [ ] **The built-in Windows OpenSSH client works** — your CMD can run
  `ssh` and `ssh-keygen` (stock on Windows 10/11)
- [ ] You are ready to run the **one-time laptop setup** (tutorial
  Part 1): check the SSH server, one firewall line, one pasted key

If something is unticked, finish the missing piece first, then come
back. The order genuinely matters.

## 6. What is inside this repo, file by file

So the folders never scare you — here is everything and what it is for:

| File / folder | What it is, in human words |
|---|---|
| `README.md` | This document |
| `README.id.md` | This document in Indonesian |
| `docs/TUTORIAL.md` | **The complete step-by-step tutorial, both sides** — the main reading for installing |
| `docs/TUTORIAL.id.md` | The same tutorial in Indonesian, in super-simple language |
| `docs/CLAIM-MUSE.md` | **How to claim a Muse account with a VPN or without one**, including the highlighted `IB4FJR` referral code |
| `docs/CLAIM-MUSE.id.md` | The same Muse claim guide in Indonesian |
| `docs/images/banner.svg` | The title image above |
| `scripts/setup-sshd.sh` | **The VM-side sshd installer** — builds a key-only sshd on localhost port 2222 from the example config |
| `scripts/sshd_config.example` | The example sshd configuration (passwords off, localhost only, keys only) |
| `scripts/reverse-start.sh` | **The starter** — launches the reverse tunnel from the VM to the laptop, guarded by the watchdog |
| `scripts/reverse-supervisor.sh` | **The watchdog** — opens the reverse ssh and restarts it every 10 seconds if it drops |
| `scripts/reverse-stop.sh` | **The stopper** — kills the tunnel and its watchdog together |
| `scripts/ensure-up.sh` | **The self-healing guard** — checks Tailscale, the sshd binary, the local sshd and the supervisor in order, and repairs whatever a VM reset killed; a no-op when everything is healthy |
| `scripts/ensure-hook.sh` | **The scheduler script** — calls the guard every 30 seconds from the author's runtime hook and wakes the agent only once per real incident |
| `scripts/ssh-tunnel-ensure.hook.json.example` | **Example hook definition** — the 30-second polling schedule plus a sketch of the wake-up prompt for the guard |
| `scripts/tsconnect.py` | A small ProxyCommand helper: ferries the VM's ssh connections into the tailnet through the runtime proxy (needed on the author's sandbox; see the note in the tutorial) |
| `scripts/windows-setup.ps1` | **The Windows laptop preparer** — checks admin, checks sshd, asks for the VM's public key, installs the firewall rule + key + file permissions |
| `LICENSE` | The MIT license |

## 7. How to install — the big picture

The details live in the tutorial (linked below). The big shape:

**Laptop side (once, permanent):**

1. Note the laptop's tailnet IP (`tailscale ip -4`)
2. Make sure the Windows SSH server is **running**
   (`sc query sshd` → RUNNING)
3. Create **your own key** (`ssh-keygen`); send the `.pub` to the VM
4. Open the **firewall** for the Tailscale range only
   (`remoteip=100.64.0.0/10`) — `scripts/windows-setup.ps1` can do
   steps 4–5 for you
5. Paste the **VM's public key** onto the laptop + lock its file
   permissions
6. Make sure **Allow incoming connections** is on (Shields Up off)

**Muse VM side:**

7. Run `setup-sshd.sh` — a key-only sshd comes up on localhost:2222,
   your public key pasted into `authorized_keys`
8. Join the VM to your tailnet (`tailscale up`; you approve the link —
   **there is an important trick if the link never appears**, covered
   in the tutorial)
9. Test the road VM → laptop (must pass once steps 4–6 are done)
10. Run `reverse-start.sh` — the parked port `2223` appears on the
    laptop, guarded by the watchdog

**Connecting (every day):**

```
ssh -i muse-key -p 2223 root@127.0.0.1
```

The full tutorial:

- 🇬🇧 **[docs/TUTORIAL.md](docs/TUTORIAL.md)** — plain English, beginner-proof
- 🇮🇩 **[docs/TUTORIAL.id.md](docs/TUTORIAL.id.md)** — Indonesian version, super-simple language

**And it heals itself after resets (auto-recovery).** A VM reset
still stops the running sshd and supervisor — but the setup no
longer waits for a human. A guard script (`scripts/ensure-up.sh`)
checks Tailscale → sshd binary → local sshd → supervisor and
repairs whatever is broken, polled every 30 seconds by a runtime
hook that lives in `$HOME` — inside the one place a reset cannot
wipe. The repair itself is pure bash (**zero AI tokens**); the
agent is only woken once per incident, to verify and report. After
a reset: **wait about a minute, then just connect.** The full
story, including the one honest limit (a fully logged-out Tailscale
still needs your approval) and a real flock bug worth knowing,
lives in tutorial Part 4.

## 8. Compared with Pinggy (the author's old road)

The author of this project first entered his Muse VM with SSH through
**Pinggy** (a free public tunnel). It provably worked — and it stays a
fine fallback road. The differences:

| Thing | Pinggy (public) | This project (Tailscale reverse) |
|---|---|---|
| Meeting point | The Pinggy company's server | **Your own laptop** |
| Address to connect to | Public, **random, changes every start** | `127.0.0.1:2223` on the laptop — fixed |
| Time limit | **60 minutes** per session (free tier) | **None** — as long as the laptop is online |
| Who can even try to connect | Anyone who learns the address (still stopped by the key) | Only devices on your tailnet |
| Setup on the laptop | None — just create a key | One-time: firewall + VM key |
| Laptop must stay online? | No | **Yes**, during the session |
| Cost | Free (60 minutes) / paid (unlimited) | Free (Tailscale free tier) |

In short: Pinggy is borrowing a public gate whose door changes every
hour. This project builds a door of your own, in your own house — a
bit of work once, comfortable forever after.

## 9. Safety — explained for beginners

Several layers, from the innermost door outwards:

1. **Password login is fully disabled.** The VM's sshd accepts keys
   only (`PasswordAuthentication no`). Someone who learns the address
   still cannot guess passwords — that door simply does not exist.
2. **Only one or two known keys.** The VM only accepts keys whose
   lines sit in its `authorized_keys` file. The laptop is the same:
   only the VM's key is known for calling in. Delete one line = the
   access dies that same second.
3. **The parked port is laptop-localhost only.** Port `2223` is bound
   to `127.0.0.1` — from the network outside your laptop, that port
   is **invisible**. Only you, on that laptop, can use it.
4. **The firewall rule is limited to the Tailscale range.** The
   laptop's Windows SSH server is opened only for `100.64.0.0/10`
   (tailnet addresses), not for the whole internet.
5. **No company relay in the middle.** Traffic travels between your
   own devices over your tailnet.

**One thing you must fully realize** (the author is not hiding it): in
this design, your laptop installs the VM's key — which technically
lets the VM log into your laptop to park that port. That is exactly
the mechanism that makes the door work. If one day you don't want it
anymore, remove the VM's key line from
`administrators_authorized_keys` on the laptop and switch the rule
off — all access stops right there, with nothing left behind.

And about secrets: **private keys and the author's real machine data
NEVER enter this repo.** Every machine-specific value in the sample
files (tailnet IPs, usernames, real public keys) has been replaced
with placeholders like `YOUR_LAPTOP_TAILNET_IP` — put your own values
in when you install. Script parameters all come through environment
variables; nothing real is baked into the code.

## 10. Honest limits (so nobody is surprised)

- **The laptop is the meeting point.** Laptop off / asleep / signed
  out of Tailscale = the parked door is gone until it returns. The
  VM's watchdog reconnects by itself once the laptop is back.
- **Muse sandboxes can be reset.** The running sshd and watchdog die
  with the machine — but every file in the project folder (in `$HOME`)
  survives, the laptop side is permanent, and on the author's runtime
  the Tailscale connection sticks across resets. With the
  auto-recovery guard (tutorial Part 4), the VM side relights itself
  within about a minute; without it, relighting manually is a
  two-command job.
- **The sandbox's built-in Tailscale is client-only.** That is the
  whole reason this reverse detour exists. On a machine with native
  Tailscale routing, you may not need this project at all.
- **Tests from inside the sandbox can lie.** On the author's setup,
  the return test from inside the VM loops through an egress proxy
  that is genuinely flaky — while the author's direct connection from
  his laptop went through on the first try. Judge your setup by your
  real connection, not by the sandbox's return test alone.

## 11. Beginner FAQ

**"Is this free?"**
The project is free and open-source. Tailscale has a free tier that is
enough for this setup. What may cost money is your Muse account
itself — and there is a 1 billion token bonus from the referral code
above.

**"I can't code. Can I use this?"**
Yes, if you can copy-paste commands and read slowly. The tutorial was
written for you — the two sides are clearly separated, and every step
has a clear sign of success.

**"Why not just SSH straight into the VM?"**
Because the VM cannot be called — that is the entire reason this
project exists (section 1). Its entrance door has to be parked from
the inside out first.

**"Isn't `127.0.0.1` my own laptop?"**
Yes, exactly — and that is the trick. You connect to your own laptop,
at a port whose contents are forwarded to the VM. So the connect
command *looks* local, while you land inside the VM.

**"What if I lose my private key / change laptops?"**
Create a fresh key pair, paste the new `.pub` line into the VM's
`authorized_keys`, delete the old line. Five minutes, done.

**"Can I do this from a phone too?"**
In principle yes: a phone that joins the tailnet and acts as the
meeting point (for example with Termux + sshd). But this tutorial is
written from the Windows laptop angle — that is what the author
actually tested.

**"Where does my data travel?"**
Your laptop ↔ the Tailscale network ↔ your VM. No company tunnel
server sits in the middle like on the public road.

**"What if something errors halfway?"**
The tutorial has a troubleshooting table in Part 5 — symptom, likely
cause, fix. Including the two signature diseases the author met
himself: the Windows `.ssh` folder that answers `Access is denied`,
and a `tailscale up` that gets stuck without a link (the cure:
`down` first, then `up`).

## 12. Short history (proof this comes from real use)

- **2026-10-02** — The author first entered his Muse VM with SSH
  through a free public tunnel. It worked on the first try — but
  sessions were capped at 60 minutes and the address was random each
  start.
- **2026-10-02 (evening)** — The Tailscale road was chased. The VM
  joined the tailnet after discovering the `down`-then-`up` trick
  (before that, the approval link never appeared). The first VM →
  laptop tests were silently refused; the culprits turned out to be
  the Windows firewall and the incoming-connections switch in
  Tailscale.
- **2026-10-04** — After the laptop side was finished (firewall rule,
  VM key installed, incoming allowed), the full chain was tested and
  **passed completely**: from a session on the laptop, connecting back
  through the parked port was answered by the Muse VM itself. The
  watchdog (supervisor) was added so the tunnel heals itself when it
  drops.
- **2026-10-05** — **Auto-recovery landed.** A real morning reset
  (06:24) greeted the author with `Connection refused` because the
  VM side was still dark. The answer shipped the same day: the
  `ensure-up.sh` guard plus a runtime hook living in `$HOME` that
  polls it every 30 seconds (the repair is pure bash — zero AI
  tokens — and the agent wakes only once per incident). Proven live
  the same day: sshd and supervisor killed on purpose, everything
  back by itself within 75 seconds. After a reset now: wait about a
  minute, then connect.

Every step and error symptom in this repo is a real result from the
running setup — not invention.

## 13. Closing

A personal infrastructure project, shared as-is for anyone who wants
to learn from it or use it. If it helps you, a ⭐ on this repo means a
lot to its maker. If something errors or the tutorial confuses you
halfway, open an *issue* — tell us which part you got stuck on.

Take it slowly. Nothing here is a race.
