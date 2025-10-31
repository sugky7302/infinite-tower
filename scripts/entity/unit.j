globals
    //region Unit 索引池管理
    // 為了解決頻繁分配與釋放 Unit 實例所帶來的效能問題，使用兩個數組來實現一個索引池
    // 使用 3 個指針來記錄池的狀態以及取用與釋放索引的位置

    // 索引池，管理索引的跳轉關係
    integer array C_Unit_g_instance_pool
    
    // 實例數量
    integer C_Unit_g_instances_length = 0

    // 還沒用與回收的指針
    integer C_Unit_g_instance_pointer_head = -1
    integer C_Unit_g_instance_pointer_tail = -1
endglobals

function C_Unit_PutIndex takes integer index returns nothing
    // 目前尾巴指向新索引
    if C_Unit_g_instance_pointer_tail != -1 then
        set C_Unit_g_instance_pool[C_Unit_g_instance_pointer_tail] = index
    endif
    
    // 更新尾巴指針
    set C_Unit_g_instance_pointer_tail = index
endfunction

// 擴大索引池，防止索引耗盡
function C_Unit_ExpandIndexPool takes nothing returns nothing
    // 擴大索引池
    set C_Unit_g_instances_length = C_Unit_g_instances_length + 1
    // 更新尾巴指針
    call C_Unit_PutIndex(C_Unit_g_instances_length - 1)
    // 讓頭指針指向新加入的索引
    set C_Unit_g_instance_pointer_head = C_Unit_g_instance_pointer_tail
endfunction

// 從索引池中取得一個可用的索引。
// 起初索引池為空，會自動擴大索引池。
function C_Unit_GetIndex takes nothing returns integer
    // 如果池子已經耗盡，回傳 -1 表示失敗
    if C_Unit_g_instances_length > 8191 then
        return - 1
    endif

    // 如果索引池為空，則擴大索引池
    if C_Unit_g_instance_pointer_head == C_Unit_g_instance_pointer_tail then
        call C_Unit_ExpandIndexPool()
        return C_Unit_g_instance_pointer_head
    endif

    // 更新頭指針
    set C_Unit_g_instance_pointer_head = C_Unit_g_instance_pool[C_Unit_g_instance_pointer_head]
    // 取得目前頭指針指向的索引
    return C_Unit_g_instance_pointer_head
endfunction



//region Unit 類別
globals
    integer C_Unit_TABLE = StringHash("C_Unit")
    // 單位的 Handle Id
    integer array C_Unit_id
    // 單位類型
    integer array C_Unit_type
    // 單位對象
    unit array C_Unit_object
endglobals

// 創建一個新的 Unit 實例
function C_Unit_New takes player p, integer unit_type, real x, real y, real face returns integer
    local integer index = C_Unit_GetIndex()

    if index == -1 then
        return -1
    endif

    // 創建單位並初始化變數
    set C_Unit_object[index] = CreateUnit(p, unit_type, x, y, face)
    set C_Unit_id[index] = GetHandleId(C_Unit_object[index])
    set C_Unit_type[index] = unit_type
    // 反向綁定 handle id 和 index，方便查找
    call SaveInteger(t, C_Unit_TABLE, C_Unit_id[index], index)

    return index
endfunction

// 銷毀一個 Unit 實例
function C_Unit_Destroy takes integer index returns nothing
    local unit u = C_Unit_object[index]

    if u != null then
        call RemoveUnit(u)
        set C_Unit_object[index] = null
    endif

    // 清理欄位與反向映射，並把 slot 回收到空閒佇列
    // 清除 table 中的映射（設為 -1 或 0 視實作而定）；使用 0 作為未設定值
    if C_Unit_id[index] != 0 then
        call RemoveSavedInteger(t, C_Unit_TABLE, C_Unit_id[index])
    endif

    // 釋放指針
    call C_Unit_PutIndex(index)

    set u = null
endfunction

// 根據 unit 取得對應的 Unit 實例編號，找不到回傳 -1
function C_Unit_Get takes unit u returns integer
    local integer id = GetHandleId(u)

    // 只呼叫一次 LoadInteger 以減少開銷
    if HaveSavedInteger(t, C_Unit_TABLE, id) then
        return LoadInteger(t, C_Unit_TABLE, id)
    endif

    return - 1
endfunction

// 設定 Unit 只能存活一段時間，時間到後自動刪除
function C_Unit_SetLifeTime takes integer index, real dur returns nothing
    // 若 slot 中沒有單位則不呼叫 API
    if index > -1 then
        call UnitApplyTimedLife(C_Unit_object[index], 'BTLF', dur)
    endif
endfunction


//region 單元測試
function Filter_0 takes nothing returns boolean
    local integer u = C_Unit_Get(GetTriggerUnit())
    call C_Unit_Destroy(u)
    return false
endfunction

function TestClassUnit takes nothing returns nothing
    local integer i = 0
    local player p = Player(0)
    local integer u
    local trigger tr = CreateTrigger()
    call TriggerAddCondition(tr, Condition(function Filter_0))

    loop
        exitwhen i >= 1000
        set u = C_Unit_New(p, 'hfoo', 0.0, 0.0, 0.0)
        call C_Unit_SetLifeTime(u, I2R(GetRandomInt(1, 3)))
        call TriggerRegisterUnitEvent(tr, C_Unit_object[u], EVENT_UNIT_DEATH)
        call TriggerSleepAction(0.02)
        call Print("[" + I2S(i) + "] Index(head:" + I2S(C_Unit_g_instance_pointer_head) + "/tail:" + I2S(C_Unit_g_instance_pointer_tail) + "/size:" + I2S(C_Unit_g_instances_length) + ")")
        set i = i + 1
    endloop
endfunction

