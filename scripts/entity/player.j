
globals
    // 玩家對象
    player array C_Player_object
endglobals

// 創建一個新的 Player 實例
function C_Player_New takes integer index returns integer
    set C_Player_object[index] = Player(index)

    return index
endfunction

function C_Player takes player p returns integer
    return GetPlayerId(p)
endfunction

