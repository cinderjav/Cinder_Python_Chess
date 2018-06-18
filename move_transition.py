from bit_utils import *
from enums import *
from move_generation import generate_moves_for_piece
import copy
import functools

def decouple_pieces(pieces):
    bitCount = countBits(pieces)
    if bitCount == 1:
        return [pieces]
    else:
        pieceList = []
        while bitCount > 0:
            index = getbitIndex(pieces)
            piece = 1 << index
            pieceList.append(piece)
            bitCount -= 1
            pieces = pieces & (pieces - 1)
    return pieceList

def decouple_pieces_with_string(pieces, symbol):
    bitCount = countBits(pieces)
    if bitCount == 1:
        return [(pieces, symbol)]
    else:
        pieceList = []
        while bitCount > 0:
            index = getbitIndex(pieces)
            piece = 1 << index
            pieceList.append((piece, symbol))
            bitCount -= 1
            pieces = pieces & (pieces - 1)
    return pieceList

def reorder_moves(moves, enemy_pieces):
    decoupled_moves = decouple_pieces(moves)
    secondaryList = []
    priorityList = []
    #consider filtering by if enemies defending
    for i in decoupled_moves:
        if i & enemy_pieces > 0:
            priorityList.append(i)
        else:
            secondaryList.append(i)

    return priorityList + secondaryList

def get_can_move_pieces(movesDict, move, turn):
    if turn == WHITE_TURN:
        piecesCanMoveList = [x for x in WHITE_PIECE_LIST if (movesDict[x] & move) > 0]
        return piecesCanMoveList

    piecesCanMoveList = [x for x in BLACK_PIECE_LIST if (movesDict[x] & move) > 0]
    #prioritize pawn?
    return piecesCanMoveList

def decoupled_pieces_ordered(canMovePieces, piecesDict, move, turn, enemyboard, friendboard):
    #can list of tuples, decoupled piece with current piece string
    decoupledList = []
    for i in canMovePieces:
        pieces_decoupled = decouple_pieces_with_string(piecesDict[i], i)
        for j in pieces_decoupled:
            if (move & generate_moves_for_piece(j[0], i, friendboard, enemyboard, turn)) > 0:
                decoupledList.append(j)
    
    return decoupledList

def execute_move(pieceTuple, move, bitboard):
    newbitboard = copy.deepcopy(bitboard)
    pieceToMove = pieceTuple[0]
    pieceDict = newbitboard.get_pieces_dict_for_turn()
    combinedPiecesSpecific = pieceDict[pieceTuple[1]]
    pieceminus = combinedPiecesSpecific ^ pieceToMove
    newPieceLocation = move
    newCombinedPieceSpecific = pieceminus | newPieceLocation
    pieceDict[pieceTuple[1]] = newCombinedPieceSpecific
    combinedPieces = functools.reduce((lambda x, y: x | y), pieceDict.values())
    if newbitboard.turn == WHITE_TURN:
        newbitboard.whitePieces = combinedPieces
    else:
        newbitboard.blackPieces = combinedPieces

    #find if the move contained a piece
    moveOnEnemy = (newbitboard.get_pieces_bitboard_for_enemy_turn() & move) > 0

    if moveOnEnemy:
        enemyCombinedPieces = newbitboard.get_pieces_bitboard_for_enemy_turn()
        enemyDict = newbitboard.get_pieces_dict_for_enemy_turn()
        result = [x for x in BLACK_PIECE_LIST if enemyDict[x] & move > 0]
        enemyDict[result[0]] = enemyDict[result[0]] ^ move
        combinedPiecesEnemy = functools.reduce((lambda x, y: x | y), enemyDict.values())
        if newbitboard.turn == WHITE_TURN:
            newbitboard.blackPieces = combinedPiecesEnemy
        else:
            newbitboard.whitePieces = combinedPiecesEnemy
        #need to fix othersides piece dict, and pieces
    
    newbitboard.gameBoard = newbitboard.get_pieces_bitboard_for_turn() | newbitboard.get_pieces_bitboard_for_enemy_turn()
    newbitboard.turn = WHITE_TURN if newbitboard.turn == BLACK_TURN else BLACK_TURN
    return newbitboard

    #need to modify non turn pieces if necessary, if intersection found (maybe bring it in)


