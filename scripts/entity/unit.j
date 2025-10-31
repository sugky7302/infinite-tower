globals
    integer CLASS_UNIT_TABLE = StringHash("class-unit")
    // 使用 Unit Index 這個串列來記錄空閒的 Unit 實例空間編號
    // CLASS_UNIT_INDEX_CAPACITY 定義了這個串列的容量
    // 並使用 unit_index_cur 記錄目前空閒的 Index 編號，這樣就不用每次都跑 for 迴圈去找空閒的 Index，提升效能
    // 再使用 unit_index_last 記錄目前已經使用到的最高 Index，這樣在儲存空閒的編號時可以直接從後面新增
    integer array class_unit_index_queue
    integer CLASS_UNIT_INDEX_SIZE = 100
    integer class_unit_index_valid = -1
    integer class_unit_index_inserted = -1
    // Unit 實例
    integer CLASS_UNITS_SIZE = 8192
    integer class_units_index_last = -1
    integer array units

    // Unit 成員變量
    //   handle
    integer array cv_unit_id
    //   單位類型
    integer array cv_unit_type
    //   單位
    unit array cv_unit_object
endglobals

// 計算 Unit Index 串列的大小
function Class_Unit_IndexSize takes nothing returns integer
    // 回傳目前空閒佇列中的元素數量
    // 注意：當 inserted 和 valid 為 -1（初始值）時，結果為 0
    local integer size = class_unit_index_inserted - class_unit_index_valid
    if size < 0 then
        return CLASS_UNIT_INDEX_SIZE + size
    endif
    return size
endfunction

// 取得一個空閒的 Unit Index 編號
function Class_Unit_PullIndex takes nothing returns integer
    // 若空閒佇列為空，嘗試尋找一個實際未使用的 slot 並加入佇列
    if Class_Unit_IndexSize() == 0 then
        set class_units_index_last = ModuloInteger(class_units_index_last + 1, CLASS_UNITS_SIZE)
        // 將這個新編號塞到 class_unit_index_queue 串列中
        set class_unit_index_inserted = ModuloInteger(class_unit_index_inserted + 1, CLASS_UNIT_INDEX_SIZE)
        set class_unit_index_queue[class_unit_index_inserted] = class_units_index_last
    endif

    // 從 head 取出一個 index，注意使用環形索引
    set class_unit_index_valid = ModuloInteger(class_unit_index_valid + 1, CLASS_UNIT_INDEX_SIZE)

    return class_unit_index_queue[class_unit_index_valid]
endfunction

// 回收一個使用完畢的 Unit Index 編號
function Class_Unit_PushIndex takes integer index returns nothing
    // 將一個已使用完畢的 Index 回收到空閒佇列 (ring buffer)
    //  安全檢查：若佇列已滿，先推掉最舊的一項（advance head）以避免覆寫
    local integer nextInserted = ModuloInteger(class_unit_index_inserted + 1, CLASS_UNIT_INDEX_SIZE)
    // 若下一個插入位置等於目前 head，表示佇列會滿
    if nextInserted == class_unit_index_valid then
        // 讓 head 前進以空出一個位置（捨棄最舊的索引）
        set class_unit_index_valid = ModuloInteger(class_unit_index_valid + 1, CLASS_UNIT_INDEX_SIZE)
    endif
    set class_unit_index_inserted = nextInserted
    set class_unit_index_queue[class_unit_index_inserted] = index
endfunction

// 初始化 Unit 實例
function Class_Unit_Init takes integer index, integer id, unit u, integer unit_type returns nothing
    // 初始化 Unit 成員變量
    // 參數：
    //  - index: container 中的槽位編號（由 Class_Unit_PullIndex 提供）
    //  - id: 單位的 Handle Id，用於反查（透過全域 table t 存取）
    //  - u: 單位 handle
    //  - unit_type: 單位類型（整數 id）
    // 行為：把 id 與 index 綁定，並在各個欄位記錄成員資料
    // 儲存 id->index 的對應，並在各個欄位記錄實例資料
    call SaveInteger(t, CLASS_UNIT_TABLE, id, index)
    set cv_unit_id[index] = id
    set cv_unit_type[index] = unit_type
    set cv_unit_object[index] = u
endfunction

// 先搜尋有沒有相同的 unit，沒有的話就創建一個新的 Unit 實例
function Class_Unit_Create takes player p, integer unit_type, real x, real y, real face returns integer
    local unit u = CreateUnit(p, unit_type, x, y, face)
    local integer id = GetHandleId(u)
    local integer index = Class_Unit_PullIndex()

    // 若取得 index 失敗（資源耗盡），移除剛剛建立的單位並回傳 -1
    if index == -1 then
        call RemoveUnit(u)
        set u = null
        return -1
    endif

    // 記錄 Unit 實例並初始化 slot
    set units[index] = id
    call Class_Unit_Init(index, id, u, unit_type)

    set u = null
    return index
endfunction

function Class_Unit_Destroy takes integer index returns nothing
    local unit u = cv_unit_object[index]
    if u != null then
        call RemoveUnit(u)
        set cv_unit_object[index] = null
    endif
    // 清理欄位與反向映射，並把 slot 回收到空閒佇列
    // 清除 table 中的映射（設為 -1 或 0 視實作而定）；使用 0 作為未設定值
    if cv_unit_id[index] != 0 then
        call RemoveSavedInteger(t, CLASS_UNIT_TABLE, cv_unit_id[index])
    endif
    set cv_unit_id[index] = 0
    set cv_unit_type[index] = 0
    call Class_Unit_PushIndex(index)
endfunction

// 根據 unit 取得對應的 Unit 實例編號，找不到回傳 -1
function Class_Unit_Get takes unit u returns integer
    local integer id = GetHandleId(u)
    // 只呼叫一次 LoadInteger 以減少開銷
    local integer saved = LoadInteger(t, CLASS_UNIT_TABLE, id)
    if saved != null then
        return saved
    endif
    return -1
endfunction

// 設定 Unit 只能存活一段時間，時間到後自動刪除
function Class_Unit_SetLifeTime takes integer index, real dur returns nothing
    // 若 slot 中沒有單位則不呼叫 API
    if cv_unit_object[index] != null then
        call UnitApplyTimedLife(cv_unit_object[index], 'BTLF', dur)
    endif
endfunction

// 測試函數
globals
    integer array udg_F_Filter
endglobals

function Filter_0 takes nothing returns boolean
    local integer u = Class_Unit_Get(GetTriggerUnit())
    // 若找不到對應的 index（-1），則不回收
    if u != -1 then
        call Class_Unit_PushIndex(u)
    endif
    return false
endfunction

function Test_Class_Unit takes nothing returns nothing
    local integer i = 0
    local player p = Player(0)
    local integer u
    local trigger tr = CreateTrigger()
    call TriggerAddCondition(tr, Condition(function Filter_0))

    loop
        exitwhen i >= 1000
        set u = Class_Unit_Create(p, 'hfoo', 0.0, 0.0, 0.0)
        call Class_Unit_SetLifeTime(u, I2R(GetRandomInt(1, 3)))
        call TriggerRegisterUnitEvent(tr, cv_unit_object[u], EVENT_UNIT_DEATH)
        call TriggerSleepAction(0.02)
        call Print("["+I2S(i)+"] Index(push:" + I2S(class_unit_index_queue[class_unit_index_valid]) + "/pull:" + I2S(class_unit_index_queue[class_unit_index_inserted]) + ")")
        set i = i + 1
    endloop
endfunction

