from bit_board import BitBoard

def convert_board_to_bitboard(board, turn):
    whitequeen = 0
    whiteking = 0
    whiterooks = 0
    whitebishops = 0
    whiteknight = 0
    whitepawns = 0
    blackpawns = 0
    blackknight = 0
    blackbishops = 0
    blackrooks = 0
    blackking = 0
    blackqueen = 0
    for rank in range(len(board)):
        for file in range(len(board[rank])):
            position = 64 - ((rank * 8) + (file + 1))
            if board[rank][file] == "Q":    
                whitequeen = whitequeen | (1 << position)
            if board[rank][file] == "K":
                whiteking = whiteking | (1 << position)
            if board[rank][file] == "R":
                whiterooks = whiterooks | (1 << position)
            if board[rank][file] == "B":
                whitebishops = whitebishops | (1 << position)
            if board[rank][file] == "N":
                whiteknight = whiteknight | (1 << position)
            if board[rank][file] == "P":
                whitepawns = whitepawns | (1 << position)

            if board[rank][file] == "q":    
                blackqueen = blackqueen | (1 << position)
            if board[rank][file] == "k":
                blackking = blackking | (1 << position)
            if board[rank][file] == "r":
                blackrooks = blackrooks | (1 << position)
            if board[rank][file] == "b":
                blackbishops = blackbishops | (1 << position)
            if board[rank][file] == "n":
                blackknight = blackknight | (1 << position)
            if board[rank][file] == "p":
                blackpawns = blackpawns | (1 << position)

    whitePieces = whitebishops | whiteking | whiteknight | whitepawns | whiterooks | whitequeen
    blackPieces = blackbishops | blackking | blackknight | blackpawns | blackrooks | blackqueen
    totalBoard = whitePieces | blackPieces
    whiteDict = {"B": whitebishops, "K": whiteking, "N": whiteknight, "P": whitepawns, "Q": whitequeen, "R": whiterooks}
    blackDict = {"b": blackbishops, "k": blackking, "n": blackknight, "p": blackpawns, "r": blackrooks, "q": blackqueen}
    bitboard = BitBoard(totalBoard, whitePieces, blackPieces, whiteDict, blackDict, turn)
    
    return bitboard