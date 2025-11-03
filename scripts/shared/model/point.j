// 點的模型以及簡單的操作
globals
    integer C_Point_TABLE = StringHash("C_Point")
    integer g_Point_Count = 0
endglobals

function C_Point_New takes real x, real y, real z returns integer
    call SaveReal(t, C_Point_TABLE, StringHash(I2S(g_Point_Count) + ".x"), x)
    call SaveReal(t, C_Point_TABLE, StringHash(I2S(g_Point_Count) + ".y"), y)
    call SaveReal(t, C_Point_TABLE, StringHash(I2S(g_Point_Count) + ".z"), z)
    set g_Point_Count = g_Point_Count + 1
    return g_Point_Count - 1
endfunction

function C_Point_GetX takes integer point_id returns real
    return LoadReal(t, C_Point_TABLE, StringHash(I2S(point_id) + ".x"))
endfunction

function C_Point_GetY takes integer point_id returns real
    return LoadReal(t, C_Point_TABLE, StringHash(I2S(point_id) + ".y"))
endfunction

function C_Point_GetZ takes integer point_id returns real
    return LoadReal(t, C_Point_TABLE, StringHash(I2S(point_id) + ".z"))
endfunction

function C_Point_Set takes integer point_id, real x, real y, real z returns nothing
    call SaveReal(t, C_Point_TABLE, StringHash(I2S(point_id) + ".x"), x)
    call SaveReal(t, C_Point_TABLE, StringHash(I2S(point_id) + ".y"), y)
    call SaveReal(t, C_Point_TABLE, StringHash(I2S(point_id) + ".z"), z)
endfunction

function C_Point_Copy takes integer point_id returns integer
    return C_Point_New(
        C_Point_GetX(point_id),
        C_Point_GetY(point_id),
        C_Point_GetZ(point_id)
    )
endfunction

function C_Point_Distance takes integer pointA_id, integer pointB_id returns real
    local real dx = C_Point_GetX(pointA_id) - C_Point_GetX(pointB_id)
    local real dy = C_Point_GetY(pointA_id) - C_Point_GetY(pointB_id)
    local real dz = C_Point_GetZ(pointA_id) - C_Point_GetZ(pointB_id)
    return SquareRoot(dx * dx + dy * dy + dz * dz)
endfunction

function C_Point_Print takes integer point_id returns nothing
    local real x = C_Point_GetX(point_id)
    local real y = C_Point_GetY(point_id)
    local real z = C_Point_GetZ(point_id)
    call BJDebugMsg("Point ID: " + I2S(point_id) + " (X: " + R2S(x, 2) + ", Y: " + R2S(y, 2) + ", Z: " + R2S(z, 2) + ")")
endfunction

// 將兩個點相加
function C_Point_Add takes integer pointA_id, integer pointB_id returns integer
    return C_Point_New(
        C_Point_GetX(pointA_id) + C_Point_GetX(pointB_id),
        C_Point_GetY(pointA_id) + C_Point_GetY(pointB_id),
        C_Point_GetZ(pointA_id) + C_Point_GetZ(pointB_id)
    )
endfunction

// 將兩個點相減
function C_Point_Subtract takes integer pointA_id, integer pointB_id returns integer
    return C_Point_New(
        C_Point_GetX(pointA_id) - C_Point_GetX(pointB_id),
        C_Point_GetY(pointA_id) - C_Point_GetY(pointB_id),
        C_Point_GetZ(pointA_id) - C_Point_GetZ(pointB_id)
    )
endfunction

// 將點乘以一個標量
function C_Point_Scale takes integer point_id, real scalar returns integer
    return C_Point_New(
        C_Point_GetX(point_id) * scalar,
        C_Point_GetY(point_id) * scalar,
        C_Point_GetZ(point_id) * scalar
    )
endfunction

// 將點正規化為單位向量
function C_Point_Normalize takes integer point_id returns integer
    local real length = C_Point_Distance(point_id, C_Point_New(0.0, 0.0, 0.0))
    if length == 0.0 then
        return C_Point_New(0.0, 0.0, 0.0)
    endif
    return C_Point_Scale(point_id, 1.0 / length)
endfunction

// 計算兩個點的點積
function C_Point_DotProduct takes integer pointA_id, integer pointB_id returns real
    return 
        C_Point_GetX(pointA_id) * C_Point_GetX(pointB_id) +
        C_Point_GetY(pointA_id) * C_Point_GetY(pointB_id) +
        C_Point_GetZ(pointA_id) * C_Point_GetZ(pointB_id)
endfunction

// 計算兩個點的叉積
function C_Point_CrossProduct takes integer pointA_id, integer pointB_id returns integer
    return C_Point_New(
        C_Point_GetY(pointA_id) * C_Point_GetZ(pointB_id) - C_Point_GetZ(pointA_id) * C_Point_GetY(pointB_id),
        C_Point_GetZ(pointA_id) * C_Point_GetX(pointB_id) - C_Point_GetX(pointA_id) * C_Point_GetZ(pointB_id),
        C_Point_GetX(pointA_id) * C_Point_GetY(pointB_id) - C_Point_GetY(pointA_id) * C_Point_GetX(pointB_id)
    )
endfunction

// 將點繞著 Z 軸旋轉指定角度（以度為單位）
function C_Point_RotateZ takes integer point_id, real angle_degrees returns integer
    local real angle_radians = angle_degrees * bj_DEGTORAD
    local real cos_angle = Cos(angle_radians)
    local real sin_angle = Sin(angle_radians)
    local real x = C_Point_GetX(point_id)
    local real y = C_Point_GetY(point_id)
    local real z = C_Point_GetZ(point_id)
    
    return C_Point_New(
        x * cos_angle - y * sin_angle,
        x * sin_angle + y * cos_angle,
        z
    )
endfunction

// 將點繞著 Y 軸旋轉指定角度（以度為單位）
function C_Point_RotateY takes integer point_id, real angle_degrees returns integer
    local real angle_radians = angle_degrees * bj_DEGTORAD
    local real cos_angle = Cos(angle_radians)
    local real sin_angle = Sin(angle_radians)
    local real x = C_Point_GetX(point_id)
    local real y = C_Point_GetY(point_id)
    local real z = C_Point_GetZ(point_id)
    
    return C_Point_New(
        x * cos_angle + z * sin_angle,
        y,
        -x * sin_angle + z * cos_angle
    )
endfunction

// 將點繞著 X 軸旋轉指定角度（以度為單位）
function C_Point_RotateX takes integer point_id, real angle_degrees returns integer
    local real angle_radians = angle_degrees * bj_DEGTORAD
    local real cos_angle = Cos(angle_radians)
    local real sin_angle = Sin(angle_radians)
    local real x = C_Point_GetX(point_id)
    local real y = C_Point_GetY(point_id)
    local real z = C_Point_GetZ(point_id)
    
    return C_Point_New(
        x,
        y * cos_angle - z * sin_angle,
        y * sin_angle + z * cos_angle
    )
endfunction

// 將點繞著原點旋轉指定角度（以度為單位）
function C_Point_Rotate takes integer point_id, real angle_x_degrees, real angle_y_degrees, real angle_z_degrees returns integer
    local integer rotated_point_id = point_id
    set rotated_point_id = C_Point_RotateZ(rotated_point_id, angle_z_degrees)
    set rotated_point_id = C_Point_RotateY(rotated_point_id, angle_y_degrees)
    set rotated_point_id = C_Point_RotateX(rotated_point_id, angle_x_degrees)
    return rotated_point_id
endfunction

// 將點平移指定距離
function C_Point_Translate takes integer point_id, real dx, real dy, real dz returns integer
    return C_Point_New(
        C_Point_GetX(point_id) + dx,
        C_Point_GetY(point_id) + dy,
        C_Point_GetZ(point_id) + dz
    )
endfunction

// 將點沿著指定方向移動指定距離
function C_Point_MoveAlong takes integer point_id, integer direction_point_id, real distance returns integer
    local integer direction_normalized_id = C_Point_Normalize(direction_point_id)
    return C_Point_New(
        C_Point_GetX(point_id) + C_Point_GetX(direction_normalized_id) * distance,
        C_Point_GetY(point_id) + C_Point_GetY(direction_normalized_id) * distance,
        C_Point_GetZ(point_id) + C_Point_GetZ(direction_normalized_id) * distance
    )
endfunction

// 將點投影到 XY 平面
function C_Point_ProjectToXY takes integer point_id returns integer
    return C_Point_New(
        C_Point_GetX(point_id),
        C_Point_GetY(point_id),
        0.0
    )
endfunction

// 將點投影到 XZ 平面
function C_Point_ProjectToXZ takes integer point_id returns integer
    return C_Point_New(
        C_Point_GetX(point_id),
        0.0,
        C_Point_GetZ(point_id)
    )
endfunction

// 將點投影到 YZ 平面
function C_Point_ProjectToYZ takes integer point_id returns integer
    return C_Point_New(
        0.0,
        C_Point_GetY(point_id),
        C_Point_GetZ(point_id)
    )
endfunction

// 銷毀一個 Point 實例
function C_Point_Destroy takes integer point_id returns nothing
    call RemoveSavedReal(t, C_Point_TABLE, StringHash(I2S(point_id) + ".x"))
    call RemoveSavedReal(t, C_Point_TABLE, StringHash(I2S(point_id) + ".y"))
    call RemoveSavedReal(t, C_Point_TABLE, StringHash(I2S(point_id) + ".z"))
endfunction