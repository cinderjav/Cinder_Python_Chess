import functools
from enums import *
from bit_utils import *
clearHFile = 0Xfefefefefefefefe
clearAFile = 0X7f7f7f7f7f7f7f7f
clearBFile = 0Xbfbfbfbfbfbfbfbf
clearGFile = 0Xfdfdfdfdfdfdfdfd
maxSpotValue = 0X8000000000000000

def generateKingMoves(kingboard, friendPieces, enemyPieces):
    hFile = kingboard & clearHFile
    aFile = kingboard & clearAFile

    spot_1 = hFile << 7
    spot_2 = kingboard << 8
    spot_3 = aFile << 9
    spot_4 = aFile << 1
    spot_5 = kingboard >> 1
    spot_6 = aFile >> 7
    spot_7 = kingboard >> 8
    spot_8 = hFile >> 9
    spotList = [spot_1, spot_2, spot_3, spot_4, spot_5, spot_6, spot_7, spot_8]
    filteredList = list(filter(lambda x: x < maxSpotValue and x >= 0, spotList))
    kingMoves = functools.reduce((lambda x, y: x | y), filteredList)
    return kingMoves & ~friendPieces


def generateBishopMoves(bishopboard, friendPieces, enemyPieces):
    # count bits loop foreach,clear lowest bit
    bitCount = countBits(bishopboard)
    attacks = 0
    while bitCount > 0:
        bishopIndex = getbitIndex(bishopboard)
        bishopposition = bishopIndex % 8
        init = 1 << bishopIndex
        right = bishopposition
        left = bishopposition
        downleft = bishopposition
        downright = bishopposition
        while right > 0:
            init = init << 7
            if (init & ~friendPieces) == 0:
                break
            if init > maxSpotValue or init < 0:
                break
            attacks = attacks | init
            if (init & enemyPieces) > 0:
                break
            right -= 1

        init = 1 << bishopIndex
        while left < 7:
            init = init << 9
            if (init & ~friendPieces) == 0:
                break
            if init > maxSpotValue or init < 0:
                break
            attacks = attacks | init
            if (init & enemyPieces) > 0:
                break
            left += 1

        init = 1 << bishopIndex
        while downleft < 7:
            init = init >> 7
            if (init & ~friendPieces) == 0:
                break
            if init > maxSpotValue or init < 0:
                break
            attacks = attacks | init
            if (init & enemyPieces) > 0:
                break
            downleft += 1

        init = 1 << bishopIndex
        while downright > 0:
            init = init >> 9
            if (init & ~friendPieces) == 0:
                break
            if init > maxSpotValue or init < 0:
                break
            attacks = attacks | init
            if (init & enemyPieces) > 0:
                break
            downright -= 1

        bitCount -= 1
        bishopboard = bishopboard & (bishopboard - 1)
        # clear last bit

    return attacks & ~friendPieces


def generateKnightMoves(knightboard, friendPieces, enemyPieces):
    fileABMask = clearAFile & clearBFile
    fileGHMask = clearGFile & clearHFile
    knightABMask = knightboard & fileABMask
    knightGHMask = knightboard & fileGHMask
    knightAMask = knightboard & clearAFile
    # knightBMask = knightboard & clearBFile
    knightHMask = knightboard & clearHFile
    # knightGMask = knightboard & clearGFile
    spot_1 = knightHMask << 15
    spot_2 = knightGHMask << 6
    spot_3 = knightHMask >> 17
    spot_4 = knightGHMask >> 10
    spot_5 = knightAMask << 17
    spot_6 = knightABMask << 10
    spot_7 = knightAMask >> 15
    spot_8 = knightABMask >> 6
    spotList = [spot_1, spot_2, spot_3, spot_4, spot_5, spot_6, spot_7, spot_8]
    filteredList = list(filter(lambda x: x < maxSpotValue and x >= 0, spotList))
    knightMoves = functools.reduce((lambda x, y: x | y), filteredList)
    return knightMoves & ~friendPieces


def generateQueenMoves(queenboard, friendPieces, enemyPieces):
    bitCount = countBits(queenboard)
    attacks = 0

    while bitCount > 0:
        queenIndex = getbitIndex(queenboard)
        attacks = 0
        queenFileIndex = queenIndex % 8
        queenRankIndex = queenIndex // 8
        init = 1 << queenIndex
        left = queenFileIndex
        right = queenFileIndex
        up = queenRankIndex
        down = queenRankIndex
        downRight = queenFileIndex
        downLeft = queenFileIndex
        topLeft = queenFileIndex
        topRight = queenFileIndex

        while left < 7:
            init = init << 1
            if (init & ~friendPieces) == 0:
                break
            if init > maxSpotValue or init < 0:
                break
            attacks = attacks | init
            if (init & enemyPieces) > 0:
                break
            left += 1

        init = 1 << queenIndex
        while right > 0:
            init = init >> 1
            if (init & ~friendPieces) == 0:
                break
            if init > maxSpotValue or init < 0:
                break
            attacks = attacks | init
            if (init & enemyPieces) > 0:
                break
            right -= 1

        init = 1 << queenIndex
        while up < 7:
            init = init << 8
            if (init & ~friendPieces) == 0:
                break
            if init > maxSpotValue or init < 0:
                break
            attacks = attacks | init
            if (init & enemyPieces) > 0:
                break
            up += 1

        init = 1 << queenIndex
        while down > 0:
            init = init >> 8
            if (init & ~friendPieces) == 0:
                break
            if init > maxSpotValue or init < 0:
                break
            attacks = attacks | init
            if (init & enemyPieces) > 0:
                break
            down -= 1

        init = 1 << queenIndex
        while downRight > 0:
            init = init >> 9
            if (init & ~friendPieces) == 0:
                break
            if init > maxSpotValue or init < 0:
                break
            attacks = attacks | init
            if (init & enemyPieces) > 0:
                break
            downRight -= 1

        init = 1 << queenIndex
        while downLeft < 7:
            init = init >> 7
            if (init & ~friendPieces) == 0:
                break
            if init > maxSpotValue or init < 0:
                break
            attacks = attacks | init
            if (init & enemyPieces) > 0:
                break
            downLeft += 1

        init = 1 << queenIndex
        while topLeft < 7:
            init = init << 9
            if (init & ~friendPieces) == 0:
                break
            if init > maxSpotValue or init < 0:
                break
            attacks = attacks | init
            if (init & enemyPieces) > 0:
                break
            topLeft += 1

        init = 1 << queenIndex
        while topRight > 0:
            init = init << 7
            if (init & ~friendPieces) == 0:
                break
            if init > maxSpotValue or init < 0:
                break
            attacks = attacks | init
            if (init & enemyPieces) > 0:
                break
            topRight -= 1

        bitCount -= 1
        queenboard = queenboard & (queenboard - 1)

    return attacks & ~friendPieces


def generateRookMoves(rookboard, friendPieces, enemyPieces):
    bitCount = countBits(rookboard)
    attacks = 0

    while bitCount > 0:
        rookIndex = getbitIndex(rookboard)
        rookFileIndex = rookIndex % 8
        rookRankIndex = rookIndex // 8
        init = 1 << rookIndex
        left = rookFileIndex
        right = rookFileIndex
        up = rookRankIndex
        down = rookRankIndex

        while left < 7:
            init = init << 1
            if (init & ~friendPieces) == 0:
                break
            if init > maxSpotValue or init < 0:
                break
            attacks = attacks | init
            if (init & enemyPieces) > 0:
                break
            left += 1

        init = 1 << rookIndex
        while right > 0:
            init = init >> 1
            if (init & ~friendPieces) == 0:
                break
            if init > maxSpotValue or init < 0:
                break
            attacks = attacks | init
            if (init & enemyPieces) > 0:
                break
            right -= 1

        init = 1 << rookIndex
        while up < 7:
            init = init << 8
            if (init & ~friendPieces) == 0:
                break
            if init > maxSpotValue or init < 0:
                break
            attacks = attacks | init
            if (init & enemyPieces) > 0:
                break
            up += 1

        init = 1 << rookIndex
        while down > 0:
            init = init >> 8
            if (init & ~friendPieces) == 0:
                break
            if init > maxSpotValue or init < 0:
                break
            attacks = attacks | init
            if (init & enemyPieces) > 0:
                break
            down -= 1

        bitCount -= 1
        rookboard = rookboard & (rookboard - 1)

    return attacks & ~friendPieces


def generatePawnMoves(pawnboard, friendPieces, enemyPieces, turn):

    pawnAFileClear = pawnboard & clearAFile
    pawnHFileClear = pawnboard & clearHFile

    if turn == WHITE_TURN:
        spot_1 = (pawnHFileClear << 7) & enemyPieces
        spot_2 = (pawnAFileClear << 9) & enemyPieces
        spot_3 = pawnboard << 8 & ~enemyPieces
        spot_4 = 0
        if spot_3 > 0:
            spot_4 = pawnboard << 16 & ~enemyPieces
        spotList = [spot_1, spot_3, spot_2, spot_4]
        filteredList = list(filter(lambda x: x < maxSpotValue and x >= 0, spotList))
        pawnMoves = functools.reduce((lambda x, y: x | y), filteredList)
        return pawnMoves & ~friendPieces
    else:
        spot_1 = (pawnHFileClear >> 7) & enemyPieces
        spot_2 = (pawnAFileClear >> 9) & enemyPieces
        spot_3 = pawnboard >> 8 & ~enemyPieces
        spot_4 = 0
        if spot_3 > 0:
            spot_4 = pawnboard >> 16 & ~enemyPieces
        spotList = [spot_1, spot_3, spot_2, spot_4]
        filteredList = list(filter(lambda x: x < maxSpotValue and x >= 0, spotList))
        pawnMoves = functools.reduce((lambda x, y: x | y), filteredList)
        return pawnMoves & ~friendPieces

def generate_moves(pieces, friendBoard, enemiesBoard, turn):
    pawns = 0
    queen = 0
    rook = 0
    bishop = 0
    king = 0
    knight = 0
    if  turn == WHITE_TURN:
        pawns = generatePawnMoves(pieces['P'], friendBoard, enemiesBoard, turn)
        queen = generateQueenMoves(pieces['Q'], friendBoard, enemiesBoard)
        rook = generateRookMoves(pieces['R'], friendBoard, enemiesBoard)
        bishop = generateBishopMoves(pieces['B'], friendBoard, enemiesBoard)
        king = generateKingMoves(pieces['K'], friendBoard, enemiesBoard)
        knight = generateKnightMoves(pieces['N'], friendBoard, enemiesBoard)
    else:
        pawns = generatePawnMoves(pieces['p'], friendBoard, enemiesBoard, turn)
        queen = generateQueenMoves(pieces['q'], friendBoard, enemiesBoard)
        rook = generateRookMoves(pieces['r'], friendBoard, enemiesBoard)
        bishop = generateBishopMoves(pieces['b'], friendBoard, enemiesBoard)
        king = generateKingMoves(pieces['k'], friendBoard, enemiesBoard)
        knight = generateKnightMoves(pieces['n'], friendBoard, enemiesBoard)

    overallMoves =  pawns | queen | rook | bishop | king | knight
    moveDict = {}
    if turn == WHITE_TURN:
        moveDict = {WHITE_PAWN: pawns, WHITE_QUEEN: queen, WHITE_ROOK: rook, WHITE_BISHOP: bishop, WHITE_KING: king, WHITE_KNIGHT: knight}
    else:
        moveDict = {BLACK_PAWN: pawns, BLACK_QUEEN: queen, BLACK_ROOK: rook, BLACK_BISHOP: bishop, BLACK_KING: king, BLACK_KNIGHT: knight}

    return overallMoves, moveDict

def generate_moves_for_piece(pieces, piecestring, friendBoard, enemiesBoard, turn):
    if piecestring == WHITE_PAWN or piecestring == BLACK_PAWN:
        return generatePawnMoves(pieces, friendBoard, enemiesBoard, turn)
    if piecestring == WHITE_BISHOP or piecestring == BLACK_BISHOP:
        return generateBishopMoves(pieces, friendBoard, enemiesBoard)
    if piecestring == WHITE_KNIGHT or piecestring == BLACK_KNIGHT:
        return generateKnightMoves(pieces, friendBoard, enemiesBoard)
    if piecestring == WHITE_KING or piecestring == BLACK_KING:
        return generateKingMoves(pieces, friendBoard, enemiesBoard)
    if piecestring == WHITE_QUEEN or piecestring == BLACK_QUEEN:
        return generateQueenMoves(pieces, friendBoard, enemiesBoard)
    if piecestring == WHITE_ROOK or piecestring == BLACK_ROOK:
        return generateRookMoves(pieces, friendBoard, enemiesBoard)
