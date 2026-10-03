<div align="center">

# 🚗 VelvetKeys

### *Analog-feel driving for keyboard players*

[![FiveM](https://img.shields.io/badge/platform-FiveM-red?logo=gtav&logoColor=white)](https://fivem.net)
[![Standalone](https://img.shields.io/badge/framework-standalone-2e7d32)](https://github.com/TEARLESSVVOID/FiveM-velvet_keys)
[![Version](https://img.shields.io/badge/version-1.1.0-blue)](https://github.com/TEARLESSVVOID/FiveM-velvet_keys/releases)
[![License](https://img.shields.io/badge/license-MIT-brightgreen)](./LICENSE)

**Give your keyboard players the smooth, progressive driving feel of a controller —
without breaking a single native input behavior.**

[Installation](#-installation) · [Configuration](#%EF%B8%8F-configuration) · [How It Works](#-how-it-works) · [FAQ](#-faq)

</div>

---

## ✨ Why VelvetKeys?

On a controller, throttle and steering are analog — smooth, proportional, forgiving.
On a keyboard they are binary switches: **instant full throttle** and **snapping steering**.
That's why keyboard drivers launch with burning tires, twitch through corners, and
overshoot every lane change.

**VelvetKeys** bridges that gap. It reshapes the *power delivery* and *steering sensitivity*
of every ground vehicle while leaving the entire native input pipeline untouched —
so nothing about *how* your players press their keys ever changes, only how the car responds.

```diff
+ No drift. No offset. No dead keys. No broken gamepads.
```

## 🎯 Features

| | Feature | Description |
|---|---|---|
| 🛞 | **Speed-scaled steering** | A fully editable piecewise curve scales steering sensitivity by speed — fine adjustments in parking lots, native feel downtown, rock-stable at highway speeds |
| 🖱️ | **Mouse steering respected** | Hold-`LMB` mouse steering (`INPUT_VEH_MOUSE_CONTROL_OVERRIDE`) is pure analog — VelvetKeys **never** scales it down |
| 🔥 | **Anti-wheelspin launch** | Throttle power is limited by *both* a time ramp and a speed curve, so even high-torque muscle cars pull away cleanly instead of burning rubber |
| 🔄 | **Native-everything fallback** | Release `W` and reverse power instantly returns to 100% — braking, handbrake, drifting, stunting: all 100% vanilla |
| 🎮 | **Zero collateral damage** | Gamepads, aircraft, helicopters, boats, bicycles-as-input and passengers are completely untouched |
| ⚙️ | **Configuration-first** | Every number lives in one well-documented `config.lua` |

## 📦 Installation

1. Download the latest release or clone this repository.
2. Drop the `velvet_keys` folder anywhere inside your server's `resources` directory.

   ```
   resources/
   └── [plugins]/
       └── velvet_keys/
   ```

3. Add one line to your `server.cfg`:

   ```cfg
   ensure velvet_keys
   ```

4. Restart the server. **Done** — there is nothing to configure unless you want to.

> 💡 **Standalone by design.** No framework, no database, no dependencies. Drop it in and it works on ESX, QBCore, qbx, or nothing at all.

## ⚙️ Configuration

Everything lives in [`config.lua`](./config.lua).

### Steering

Sensitivity is interpolated piecewise-linearly through `Config.SteerCurve`.
Add or remove breakpoints freely — speeds in **km/h**, sensitivity in **%**.

```lua
Config.SteerCurve = {
    { speed = 0,   pct = 75  },  -- very low speed: finer small adjustments
    { speed = 30,  pct = 100 },  -- city speeds: native feel
    { speed = 160, pct = 35  },  -- high speed: stable, no twitch
}
```

### Throttle

Launch power = `time ramp × speed cap`, then slides to 100%.

```lua
Config.ThrottleAttackMs     = 250  -- time ramp to 100% while W is held (ms)
Config.ThrottleMinPower     = 0.35 -- instant power multiplier at launch (0–1)
Config.ThrottleFullPowerKmh = 30   -- speed (km/h) at which the cap is fully released
```

### Vehicle whitelist

Only ground vehicles are affected, resolved via `GetVehicleType()`:

```lua
Config.GroundTypes = {
    automobile            = true,  -- cars
    bike                  = true,  -- motorcycles
    bicycle               = true,  -- bicycles
    quadbike              = true,  -- quads & ATVs
    amphibious_automobile = true,  -- amphibious cars
    amphibious_quadbike   = true,  -- amphibious quads
    tank                  = true,  -- tanks
}
```

Aircraft (`plane`, `heli`), boats (`boat`, `sub*`), blimps and every other class are
**never** touched. Set `Config.Debug = true` to trace loading in the F8 console.

## 🧠 How It Works

VelvetKeys deliberately avoids the input-hijacking patterns that make most driving
tweaks feel broken. Two safe, vehicle-level natives do all the work:

| Native | Role | Why it's safe |
|---|---|---|
| `SetVehicleSteeringScale` | Scales steering sensitivity by speed | Multiplies sensitivity only — the native steering ramp and auto-centering stay intact, so micro-corrections never drift |
| `SetVehicleCheatPowerIncrease` | Shapes launch power | Multiplies engine power only — the `W` key keeps its native input, so releasing it instantly restores 100% (reverse included) |

```lua
-- The whole philosophy in six lines
if IsControlPressed(0, 61) then                -- mouse steering (LMB)?
    SetVehicleSteeringScale(veh, 1.0)          --   → never scale analog input
else
    SetVehicleSteeringScale(veh, curve(speed)) --   → scale A/D by speed only
end
```

> ⚠️ **What we intentionally do NOT do:**
> no `DisableControlAction`, no `SetControlNormal` re-feeding, no `SetVehicleSteerBias`.
> Those patterns disable or bypass the native pipeline and cause dead pedals,
> sticky steering and residual drift. VelvetKeys keeps every pathway native.

## ❓ FAQ

<details>
<summary><b>Does it affect gamepad players?</b></summary>
No. The profile only applies while <code>IsUsingKeyboard(2)</code> reports true, the player is the
driver, and the vehicle is a ground vehicle. Everything else is passed through untouched.
</details>

<details>
<summary><b>Does it change top speed or braking?</b></summary>
No. Power multipliers only shape acceleration below the configured speed; braking,
engine braking, handbrake and top speed remain vanilla.
</details>

<details>
<summary><b>Will it conflict with manual transmission scripts?</b></summary>
VelvetKeys disables no controls, so there is no direct control conflict. However,
if your MT script also modifies engine power, the two power multipliers will stack —
prefer one system per vehicle.
</details>

<details>
<summary><b>Is there any server-side component?</b></summary>
No. VelvetKeys is a pure client resource — zero server load, zero network traffic.
</details>

## 📄 License

Released under the [MIT License](./LICENSE).

---

<div align="center">

**VelvetKeys** · crafted for keyboard drivers · [TEARLESSVVOID](https://github.com/TEARLESSVVOID)

</div>
