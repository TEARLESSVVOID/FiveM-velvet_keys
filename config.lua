Config = {}

-- 总开关 / master switch
Config.Enabled = true

-- 仅地面载具生效（GetVehicleType 返回的类型）/ ground vehicle types only
-- 直升机(heli)/飞机(plane)/船(boat)/潜艇(sub*)/飞艇(blimp) 均不在此列，不受影响
Config.GroundTypes = {
    automobile            = true, -- 汽车 / cars
    bike                  = true, -- 摩托车 / motorcycles
    bicycle               = true, -- 自行车 / bicycles
    quadbike              = true, -- 四轮全地形车 / quads & ATVs
    amphibious_automobile = true, -- 两栖汽车 / amphibious cars
    amphibious_quadbike   = true, -- 两栖四轮车 / amphibious quads
    tank                  = true, -- 坦克 / tanks
}

-- ===== 转向 / Steering =====
-- 转向输入完全使用游戏原生管线（自带渐进斜坡、松手自动回正，无偏移）。
-- 按住鼠标左键（INPUT_VEH_MOUSE_CONTROL_OVERRIDE）转向时灵敏度永远 100%。
-- 本资源只按车速缩放 A/D 转向灵敏度（下方折线表，可自行增删节点）。
-- Steering stays fully native (built-in ramp + auto-centering). Mouse steering
-- (LMB hold) is never scaled. A/D steering sensitivity is scaled by speed via
-- the piecewise curve below (add/remove breakpoints freely).
Config.SteerCurve = {
    { speed = 0,   pct = 75 }, -- 极低速：微调更细腻 / very low speed: finer small adjustments
    { speed = 30,  pct = 100 }, -- 常用区间：原生手感 / city speeds: native feel
    { speed = 160, pct = 35 },  -- 高速：稳定防甩 / high speed: stable, no twitch
}

-- ===== 油门 / Throttle =====
-- 动力 = 时间渐变 × 速度曲线 双重限制，彻底消除起步烧胎
-- power = time-ramp × speed-curve, kills launch wheelspin even on muscle cars
Config.ThrottleAttackMs     = 250  -- 按住 W：时间渐变到 100% 的毫秒数 / time ramp while held
Config.ThrottleMinPower     = 0.35 -- 起步瞬间动力倍率（0~1）/ initial power multiplier
Config.ThrottleFullPowerKmh = 30   -- 车速达到此值(km/h)时速度限制解除 / speed cap fully released here

-- 调试日志（输出到 F8 控制台）/ debug prints to the F8 console
Config.Debug = false
