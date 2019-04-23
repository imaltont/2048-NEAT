-->assumes 4x4 board
directions = {"w", "a", "s", "d"}
values = {}
for i = 1, 20 do
    values[i] = 2^i
end

point_board = {
    {16, 15, 14, 13},
    {9, 10, 11, 12},
    {8, 7, 6, 5},
    {1, 2, 3, 4}
}


function spawn_tile(board)
    local legal_placement = {}
    for i = 1, #board[1] do
        for j = 1, #board[1][i] do
            if board[1][i][j] == 0 then
                legal_placement[#legal_placement+1] = {i, j}
            end
        end
    end
    local value = 0
    if math.random() < 0.1 then
        value = 2
    else
        value = 1
    end
    local indices = legal_placement[math.random(1, #legal_placement)]
    board[1][indices[1]][indices[2]] = value
end
function print_board(board)
    io.write(string.format("Score: %d\tMax Tile: %d\nBoard: \n", board.score, 2^board.max))
    for i = 1, 4 do
        for j = 1, 4 do
            io.write(string.format("\t%d", board[1][i][j] > 0 and 2^board[1][i][j] or 0))
        end
        io.write("\n")
    end
end
function generate_board()
    board = {{}, score=0, max= 0}
    for i = 1, 4 do
        board[1][i] = {}
        for j = 1, 4 do
            board[1][i][j] = 0
        end
    end
    spawn_tile(board)
    spawn_tile(board)
    return board
end
function move_tiles(direction, board)
    local old_board = {}
    for i = 1, 4 do
        old_board[i] = {}
        for j = 1, 4 do
            old_board[i][j] = board[1][i][j]
        end
    end
    if direction == 1 then
        for i = 1, 4 do
            for j = 1, 4 do
                for k = j+1, 4 do
                    if board[1][j][i] == 0 then
                        board[1][j][i] = board[1][k][i]
                        board[1][k][i] = 0
                    elseif board[1][j][i] == board[1][k][i] then
                        board[1][j][i] = board[1][j][i] + 1
                        board[1][k][i] = 0
                        board.score = board.score + 2^board[1][j][i]
                        break
                    elseif board[1][k][i] ~= 0 then
                        break
                    end
                end
            end
        end
    elseif direction == 2 then
        for i = 1, 4 do
            for j = 1, 4 do
                for k = j+1, 4 do
                    if board[1][i][j] == 0 then
                        board[1][i][j] = board[1][i][k]
                        board[1][i][k] = 0
                    elseif board[1][i][j] == board[1][i][k] then
                        board[1][i][j] = board[1][i][j] + 1
                        board[1][i][k] = 0
                        board.score = board.score + 2^board[1][i][j]
                        break
                    elseif board[1][i][k] ~= 0 then
                        break
                    end
                end
            end
        end
    elseif direction == 3 then
        for i = 1, 4 do
            for j = 4, 1, -1 do
                for k = j-1, 1, -1 do
                    if board[1][j][i] == 0 then
                        board[1][j][i] = board[1][k][i]
                        board[1][k][i] = 0
                    elseif board[1][j][i] == board[1][k][i] then
                        board[1][j][i] = board[1][j][i] + 1
                        board[1][k][i] = 0
                        board.score = board.score + 2^board[1][j][i]
                        break
                    elseif board[1][k][i] ~= 0 then
                        break
                    end
                end
            end
        end

    elseif direction == 4 then
        for i = 1, 4 do
            for j = 4, 1, -1 do
                for k = j-1, 1, -1 do
                    if board[1][i][j] == 0 then
                        board[1][i][j] = board[1][i][k]
                        board[1][i][k] = 0
                    elseif board[1][i][j] == board[1][i][k] then
                        board[1][i][j] = board[1][i][j] + 1
                        board[1][i][k] = 0
                        board.score = board.score + 2^board[1][i][j]
                        break
                    elseif board[1][i][k] ~= 0 then
                        break
                    end
                end
            end
        end
    end
    local has_changed = false
    for i = 1, 4 do
        for j = 1, 4 do
            if old_board[i][j] ~= board[1][i][j] then
                has_changed = true
                break
            end
        end
    end
    if has_changed then
        spawn_tile(board)
        return true
    end
    return false
end
function has_legal_moves(board)
end
function max_board(board)
    for i = 1, 4 do
        for j = 1, 4 do
            if board.max < board[1][i][j] then
                board.max = board[1][i][j]
            end
        end
    end
end
function flatten(board)
    local flat = {}
    max_board(board)
    for i = 1, 4 do
        for j = 1, 4 do
            flat[#flat+1] = board[1][i][j] / 11 -- board.max
        end
    end
    return flat
end
function count_empty(board)
    local counter = 0
    for i = 1, 4 do
        for j = 1, 4 do
            if board[1][i][j] == 0 then
                counter = counter + 1
            end
        end
    end
    return counter
end
function has_moves(board)
    local working_board = generate_board()
    for i = 1, 4 do
        for j = 1, 4 do
            working_board[1][i][j] = board[1][i][j]
        end
    end
    working_board.max = board.max
    working_board.score = board.score
    if move_tiles(1, working_board) then
        return true
    elseif move_tiles(2, working_board) then
        return true
    elseif move_tiles(3, working_board) then
        return true
    elseif move_tiles(4, working_board) then
        return true
    end
    return false
end
