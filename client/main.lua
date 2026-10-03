-- VelvetKeys 丝滑键盘驾驶 / VelvetKeys analog-feel keyboard driving
--
-- 原理 / How it works:
--   目标：键盘开车接近手柄的渐进手感，且不破坏游戏原生输入管线（无偏移、无漂移）。
--   Goal: controller-like progressive driving without breaking the native input
--   pipeline (no steering drift / offset).
--
--   转向 / Steering:
--     - 完全保留游戏原生转向输入（自带渐进斜坡与自动回正）——不 Disable 任何控制
--     - 按住鼠标左键（INPUT_VEH_MOUSE_CONTROL_OVERRIDE, 控制号 61）的鼠标转向
--       本身就是线性模拟输入，灵敏度永远 100% 不缩放
--     - A/D 键盘转向按车速折线缩放灵敏度（低速细腻 / 中速原生 / 高速稳定）
--   油门 / Throttle:
--     - 键盘 W 保持原生（二值瞬满），动力用"时间渐变 × 速度曲线"双重限制：
--       起步瞬间只有 ThrottleMinPower 倍率，随时间和车速逐渐解锁到 100%，
--       彻底消除起步烧胎（松开 W 立即恢复原生，倒车不受任何影响）
--   手柄玩家、飞机/直升机/船只/乘客完全不受影响。
--   Gamepads, air/sea vehicles and passengers are unaffected.

local DBG = Config.Debug

local throttleSm = 0.0 -- 当前前进油门时间渐变值 / current throttle time-ramp value
local reverseSm  = 0.0 -- 当前倒车动力时间渐变值 / current reverse time-ramp value
local lastVeh    = 0   -- 上一帧车辆 / last vehicle handle (for resets)

local function Dbg(msg)
    if DBG then print('^3[VelvetKeys]^7 ' .. msg) end
end

local function Clamp(v, lo, hi)
    if v < lo then return lo elseif v > hi then return hi else return v end
end

-- 朝目标值渐进 / step toward target over rampMs (0 = instant)
local function Ramp(current, target, rampMs)
    if rampMs <= 0 then return target end
    local step = GetFrameTime() * 1000.0 / rampMs -- 每帧步长 / step per frame
    if current < target then
        return math.min(target, current + step)
    elseif current > target then
        return math.max(target, current - step)
    end
    return current
end

-- 是否满足接管条件 / should we apply the driving profile this frame?
local function ShouldApply(ped, veh)
    if not Config.Enabled then return false end
    if IsPauseMenuActive() then return false end
    if not IsUsingKeyboard(2) then return false end          -- 仅键鼠 / keyboard+mouse only
    if veh == 0 then return false end
    if GetPedInVehicleSeat(veh, -1) ~= ped then return false end -- 仅驾驶位 / driver seat only
    return Config.GroundTypes[GetVehicleType(veh)] or false  -- 仅地面载具 / ground types only
end

-- 按车速折线表求转向灵敏度缩放（SteerCurve 相邻节点线性插值）
-- steering sensitivity scale by speed, piecewise-linear over Config.SteerCurve
local function SteerScaleBySpeed(veh)
    local kmh = GetEntitySpeed(veh) * 3.6
    local curve = Config.SteerCurve
    if kmh <= curve[1].speed then
        return curve[1].pct / 100.0
    end
    for i = 1, #curve - 1 do
        local a, b = curve[i], curve[i + 1]
        if kmh <= b.speed then
            local t = (kmh - a.speed) / (b.speed - a.speed)
            return ((a.pct + (b.pct - a.pct) * t) / 100.0)
        end
    end
    return curve[#curve].pct / 100.0
end

-- 按车速求油门动力上限 / throttle power cap by speed (anti-wheelspin)
local function ThrottleSpeedCap(veh)
    local kmh = GetEntitySpeed(veh) * 3.6
    return Clamp(kmh / Config.ThrottleFullPowerKmh, Config.ThrottleMinPower, 1.0)
end

-- 按车速求倒车动力上限 / reverse power cap by speed (anti-jerk)
local function ReverseSpeedCap(veh)
    local kmh = GetEntitySpeed(veh) * 3.6
    return Clamp(kmh / Config.ReverseFullPowerKmh, Config.ReverseMinPower, 1.0)
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if ShouldApply(ped, veh) then
            -- ===== 转向 / Steering =====
            -- 鼠标转向（按住左键拖动 = 控制号 61）永不缩放；缩放只作用于 A/D
            -- mouse steering (hold LMB, control 61) is never scaled; only A/D is
            if IsControlPressed(0, 61) then
                SetVehicleSteeringScale(veh, 1.0)
            else
                SetVehicleSteeringScale(veh, SteerScaleBySpeed(veh))
            end

            -- ===== 油门与倒车 / Throttle & Reverse =====
            -- W/S 保持原生输入，只平滑"动力倍率" / keep native W/S input, smooth power only
            if IsControlPressed(0, 71) then -- 前进 W / INPUT_VEH_ACCELERATE
                throttleSm = Ramp(throttleSm, 1.0, Config.ThrottleAttackMs)
                reverseSm  = 0.0
                SetVehicleCheatPowerIncrease(veh, throttleSm * ThrottleSpeedCap(veh))
            elseif IsControlPressed(0, 72) then -- 刹车/倒车 S / INPUT_VEH_BRAKE
                reverseSm  = Ramp(reverseSm, 1.0, Config.ReverseAttackMs)
                throttleSm = 0.0
                SetVehicleCheatPowerIncrease(veh, reverseSm * ReverseSpeedCap(veh))
                -- 倒车起步限速器：把倒车速度收敛到平方缓动曲线上（倒车扭矩小、
                -- 力矩法感知弱，速度收敛是最直观有效的方案）
                -- reverse launch limiter: ease backward speed onto a quadratic
                -- curve (reverse torque is weak, speed shaping is far more perceivable)
                local maxMs     = Config.ReverseLaunchMaxKmh / 3.6
                local allowedMs = reverseSm * reverseSm * maxMs -- 平方缓动 / quadratic ease-in
                local fwdMs     = GetEntitySpeedVector(veh, true).y -- 负值=倒车 / negative = reversing
                if fwdMs < -allowedMs - 0.2 then -- 倒车过快则柔性拉回 / ease back if reversing too fast
                    local eased = fwdMs + (-allowedMs - fwdMs) * Config.ReverseLimitEase
                    SetVehicleForwardSpeed(veh, eased)
                end
            else
                throttleSm = Config.ThrottleMinPower -- 预置下次起步起点 / pre-arm for next launch
                reverseSm  = Config.ReverseMinPower  -- 预置下次倒车起点 / pre-arm for next reverse
                SetVehicleCheatPowerIncrease(veh, 1.0) -- 无输入时恢复原生 / restore native when idle
            end

            lastVeh = veh
            Wait(0) -- 逐帧应用 / every frame
        else
            if lastVeh ~= 0 then
                SetVehicleSteeringScale(lastVeh, 1.0)      -- 恢复原生转向灵敏度 / restore native steering
                SetVehicleCheatPowerIncrease(lastVeh, 1.0) -- 恢复原生动力 / restore native power
                lastVeh = 0
            end
            throttleSm = 0.0
            reverseSm  = 0.0
            Wait(150) -- 空闲低频轮询 / low-frequency idle polling
        end
    end
end)

Dbg('loaded / 已加载')
